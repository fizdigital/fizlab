#!/usr/bin/env python3
"""Primitivas operacionais seguras para monitoramento e manutenção."""

from __future__ import annotations

import gzip
import json
import os
import shutil
import sqlite3
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


LOGS = {
    "startup": ("Inicialização", "system/startup.log"),
    "watchdog": ("Watchdog", "system/watchdog.log"),
    "maintenance": ("Manutenção", "system/maintenance.log"),
    "install": ("Instalação", "system/install.log"),
    "update": ("Atualização", "system/update.log"),
    "nginx-access": ("Nginx — acessos", "nginx/access.log"),
    "nginx-error": ("Nginx — erros", "nginx/error.log"),
    "api": ("FizLab API", "python/fizlab-api.log"),
    "cron": ("Cron", "cron/fizlab-cron.log"),
}


def home() -> Path:
    return Path(os.environ.get("SERVER_HOME", str(Path.home() / "server")))


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def positive_int(name: str, default: int, minimum: int = 1, maximum: int | None = None) -> int:
    try:
        value = int(os.environ.get(name, str(default)))
    except ValueError:
        value = default
    value = max(value, minimum)
    return min(value, maximum) if maximum is not None else value


def database() -> Path:
    return home() / "databases" / "sqlite" / "fizlab.db"


def record_event(service: str, status: str, details: str = "") -> None:
    try:
        with sqlite3.connect(database(), timeout=2) as connection:
            connection.execute(
                "INSERT INTO service_events(service, status, details) VALUES(?, ?, ?)",
                (service[:64], status[:64], details[:1000]),
            )
    except (OSError, sqlite3.Error):
        pass


def set_metadata(key: str, value: str) -> None:
    try:
        with sqlite3.connect(database(), timeout=2) as connection:
            connection.execute(
                """INSERT INTO metadata(key, value, updated_at)
                   VALUES(?, ?, CURRENT_TIMESTAMP)
                   ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=CURRENT_TIMESTAMP""",
                (key, value),
            )
    except (OSError, sqlite3.Error):
        pass


def get_metadata() -> dict[str, str]:
    try:
        with sqlite3.connect(database(), timeout=2) as connection:
            return dict(connection.execute("SELECT key, value FROM metadata"))
    except (OSError, sqlite3.Error):
        return {}


def recent_events(limit: int = 20) -> list[dict[str, Any]]:
    limit = max(1, min(limit, 100))
    try:
        with sqlite3.connect(database(), timeout=2) as connection:
            connection.row_factory = sqlite3.Row
            rows = connection.execute(
                "SELECT id, service, status, details, created_at FROM service_events ORDER BY id DESC LIMIT ?",
                (limit,),
            )
            return [dict(row) for row in rows]
    except (OSError, sqlite3.Error):
        return []


def log_path(log_id: str) -> Path:
    if log_id not in LOGS:
        raise KeyError(log_id)
    candidate = (home() / "logs" / LOGS[log_id][1]).resolve()
    root = (home() / "logs").resolve()
    if root not in candidate.parents:
        raise ValueError("log fora do diretório permitido")
    return candidate


def log_catalog() -> list[dict[str, Any]]:
    result = []
    for log_id, (label, relative) in LOGS.items():
        path = log_path(log_id)
        try:
            stat = path.stat()
            size, modified, available = stat.st_size, datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(), True
        except OSError:
            size, modified, available = 0, None, False
        result.append({"id": log_id, "name": label, "source": relative.split("/", 1)[0], "size_bytes": size, "modified_at": modified, "available": available})
    return result


def tail_log(log_id: str, lines: int) -> dict[str, Any]:
    max_lines = positive_int("FIZLAB_LOG_TAIL_MAX_LINES", 500, maximum=2000)
    max_bytes = positive_int("FIZLAB_LOG_TAIL_MAX_BYTES", 262144, maximum=1048576)
    requested = max(1, min(lines, max_lines))
    path = log_path(log_id)
    if not path.is_file():
        raise FileNotFoundError(log_id)
    with path.open("rb") as stream:
        stream.seek(0, os.SEEK_END)
        size = stream.tell()
        stream.seek(max(0, size - max_bytes))
        content = stream.read(max_bytes).decode("utf-8", errors="replace")
    selected = content.splitlines()[-requested:]
    return {"id": log_id, "name": LOGS[log_id][0], "lines": selected, "line_count": len(selected), "truncated": size > max_bytes, "size_bytes": size}


def maintenance_status() -> dict[str, Any]:
    metadata = get_metadata()
    log_bytes = sum(item["size_bytes"] for item in log_catalog())
    return {"last_watchdog": metadata.get("last_watchdog"), "last_maintenance": metadata.get("last_maintenance"), "logs_size_bytes": log_bytes}


def rotate_file(path: Path, rotations: int, dry_run: bool) -> list[str]:
    actions: list[str] = []
    if not path.is_file():
        return actions
    oldest = path.with_name(f"{path.name}.{rotations}.gz")
    if oldest.exists():
        actions.append(f"remover {oldest}")
        if not dry_run:
            oldest.unlink()
    for index in range(rotations - 1, 0, -1):
        source = path.with_name(f"{path.name}.{index}.gz")
        target = path.with_name(f"{path.name}.{index + 1}.gz")
        if source.exists():
            actions.append(f"mover {source} -> {target}")
            if not dry_run:
                source.replace(target)
    target = path.with_name(f"{path.name}.1.gz")
    actions.append(f"rotacionar {path} -> {target}")
    if not dry_run:
        with path.open("rb") as source, gzip.open(target, "wb") as destination:
            shutil.copyfileobj(source, destination)
        path.write_bytes(b"")
    return actions


def run_maintenance(dry_run: bool = False) -> dict[str, Any]:
    root = home()
    max_bytes = positive_int("FIZLAB_LOG_MAX_SIZE_MB", 5) * 1024 * 1024
    retention = positive_int("FIZLAB_LOG_RETENTION_DAYS", 30)
    rotations = positive_int("FIZLAB_LOG_ROTATIONS", 5, maximum=20)
    cutoff = time.time() - retention * 86400
    actions: list[str] = []
    for log_id in LOGS:
        path = log_path(log_id)
        try:
            if path.stat().st_size > max_bytes:
                actions.extend(rotate_file(path, rotations, dry_run))
        except OSError:
            pass
        for archive in path.parent.glob(f"{path.name}.*.gz"):
            try:
                if archive.stat().st_mtime < cutoff:
                    actions.append(f"remover vencido {archive}")
                    if not dry_run:
                        archive.unlink()
            except OSError:
                pass
    for directory in (root / "tmp", root / "run"):
        if not directory.is_dir():
            continue
        for candidate in directory.iterdir():
            if candidate.is_file() and candidate.suffix in {".tmp", ".lock"}:
                try:
                    if candidate.stat().st_mtime < time.time() - 86400:
                        actions.append(f"remover temporário {candidate}")
                        if not dry_run:
                            candidate.unlink()
                except OSError:
                    pass
    result = {"status": "dry-run" if dry_run else "completed", "timestamp": now(), "actions": actions, "action_count": len(actions)}
    if not dry_run:
        set_metadata("last_maintenance", result["timestamp"])
        record_event("maintenance", "maintenance_completed", json.dumps({"actions": len(actions)}))
    return result
