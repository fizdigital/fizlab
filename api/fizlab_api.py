#!/usr/bin/env python3
"""API HTTP somente leitura do FizLab."""

from __future__ import annotations

import json
import os
import sys
import traceback
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR / "scripts"))

import system_info  # noqa: E402
import operations  # noqa: E402


class FizLabHandler(BaseHTTPRequestHandler):
    server_version = "FizLabAPI/0.1"

    def send_json(self, payload: Any, status: HTTPStatus = HTTPStatus.OK) -> None:
        content = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(content)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(content)

    def do_GET(self) -> None:  # noqa: N802
        try:
            self.handle_get()
        except Exception as error:  # API boundary: keep the connection diagnosable
            traceback.print_exc()
            self.send_json(
                {
                    "status": "error",
                    "error": type(error).__name__,
                    "message": str(error),
                },
                HTTPStatus.INTERNAL_SERVER_ERROR,
            )

    def handle_get(self) -> None:
        payload = system_info.collect()
        parsed = urlparse(self.path)
        path = parsed.path
        routes = {
            "/api/v1/health": {
                "status": "healthy",
                "node_status": payload["status"],
                "timestamp": payload["timestamp"],
                "version": payload["version"],
            },
            "/api/v1/system": payload["system"],
            "/api/v1/services": payload["services"],
            "/api/v1/doctor": payload["doctor"],
            "/api/v1/monitoring": payload["monitoring"],
            "/api/v1/remote-access": payload["remote_access"],
            "/api/v1/maintenance": operations.maintenance_status(),
            "/api/v1/logs": {"logs": operations.log_catalog()},
        }
        if path == "/api/v1/events":
            query = parse_qs(parsed.query)
            try:
                limit = int(query.get("limit", ["20"])[0])
            except ValueError:
                limit = 20
            self.send_json({"events": operations.recent_events(limit)})
        elif path.startswith("/api/v1/logs/"):
            log_id = path.removeprefix("/api/v1/logs/")
            query = parse_qs(parsed.query)
            try:
                lines = int(query.get("lines", ["200"])[0])
                self.send_json(operations.tail_log(log_id, lines))
            except (KeyError, FileNotFoundError):
                self.send_json({"status": "not_found", "log": log_id}, HTTPStatus.NOT_FOUND)
            except ValueError as error:
                self.send_json({"status": "invalid_request", "message": str(error)}, HTTPStatus.BAD_REQUEST)
        elif path == "/api/v1/status":
            self.send_json(payload)
        elif path in routes:
            self.send_json(routes[path])
        else:
            self.send_json(
                {"status": "not_found", "path": path},
                HTTPStatus.NOT_FOUND,
            )

    def log_message(self, message: str, *args: object) -> None:
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), message % args))


def main() -> None:
    host = os.environ.get("FIZLAB_API_HOST", "127.0.0.1")
    port = int(os.environ.get("FIZLAB_API_PORT", "8765"))
    server = ThreadingHTTPServer((host, port), FizLabHandler)
    print(f"FizLab API ativa em http://{host}:{port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
