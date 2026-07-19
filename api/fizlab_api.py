#!/usr/bin/env python3
"""API HTTP somente leitura do FizLab."""

from __future__ import annotations

import json
import os
import sys
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR / "scripts"))

import system_info  # noqa: E402


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
        payload = system_info.collect()
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
        }
        if self.path == "/api/v1/status":
            self.send_json(payload)
        elif self.path in routes:
            self.send_json(routes[self.path])
        else:
            self.send_json(
                {"status": "not_found", "path": self.path},
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
