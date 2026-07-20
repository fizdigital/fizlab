#!/usr/bin/env python3
"""Coleta portátil e somente leitura de informações do nó FizLab."""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import socket
import subprocess
import time
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import operations  # noqa: E402


COMMANDS = (
    "bash", "curl", "wget", "git", "ssh", "sshd", "python", "php",
    "nginx", "sqlite3", "crond",
)
DIRECTORIES = (
    "www", "api", "git", "backups", "scripts", "logs", "files", "databases",
)
SERVICES = {
    "ssh": "sshd",
    "cron": "crond",
    "nginx": "nginx",
    "api": "fizlab_api.py",
}


def server_home() -> Path:
    return Path(os.environ.get("SERVER_HOME", str(Path.home() / "server")))


def detect_platform() -> str:
    prefix = os.environ.get("PREFIX", "")
    if "com.termux" in prefix or shutil.which("termux-info"):
        return "termux"

    try:
        values: dict[str, str] = {}
        for line in Path("/etc/os-release").read_text(encoding="utf-8").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                values[key] = value.strip().strip('"')
        return values.get("ID", "linux")
    except OSError:
        return platform.system().lower() or "unknown"


def local_ip() -> str:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))
        return str(sock.getsockname()[0])
    except OSError:
        return "unavailable"
    finally:
        sock.close()


def uptime_seconds() -> int:
    try:
        return int(float(Path("/proc/uptime").read_text(encoding="utf-8").split()[0]))
    except (OSError, ValueError, IndexError):
        return 0


def memory() -> dict[str, int | float]:
    values: dict[str, int] = {}
    try:
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            key, raw = line.split(":", 1)
            values[key] = int(raw.strip().split()[0]) * 1024
    except (OSError, ValueError, IndexError):
        return {"total_bytes": 0, "used_bytes": 0, "percent": 0.0}

    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", values.get("MemFree", 0))
    used = max(total - available, 0)
    percent = round((used / total * 100), 1) if total else 0.0
    return {"total_bytes": total, "used_bytes": used, "percent": percent}


def storage(path: Path) -> dict[str, int | float]:
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        usage = shutil.disk_usage(Path.home())
    percent = round((usage.used / usage.total * 100), 1) if usage.total else 0.0
    return {
        "total_bytes": usage.total,
        "used_bytes": usage.used,
        "free_bytes": usage.free,
        "percent": percent,
    }


def load_average() -> list[float]:
    getter = getattr(os, "getloadavg", None)
    if callable(getter):
        try:
            return [round(value, 2) for value in getter()]
        except OSError:
            pass

    try:
        values = Path("/proc/loadavg").read_text(encoding="utf-8").split()[:3]
        return [round(float(value), 2) for value in values]
    except (OSError, ValueError):
        return []


def process_running(pattern: str) -> bool:
    if not shutil.which("pgrep"):
        return False
    result = subprocess.run(
        ["pgrep", "-f", pattern],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def pid_file_running(path: Path) -> bool:
    try:
        pid = int(path.read_text(encoding="utf-8").strip())
        os.kill(pid, 0)
        return True
    except (OSError, ValueError):
        return False


def service_status() -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    command_map = {"ssh": "sshd", "cron": "crond", "nginx": "nginx", "api": "python"}
    for name, pattern in SERVICES.items():
        installed = shutil.which(command_map[name]) is not None
        if name == "nginx":
            running = pid_file_running(server_home() / "run" / "nginx.pid")
        elif name == "api":
            running = pid_file_running(server_home() / "run" / "fizlab-api.pid")
        else:
            running = process_running(pattern) if installed else False
        result[name] = {
            "installed": installed,
            "running": running,
            "status": "healthy" if running else ("down" if installed else "unavailable"),
        }
    return result


def doctor() -> dict[str, Any]:
    home = server_home()
    commands = {name: shutil.which(name) is not None for name in COMMANDS}
    directories = {str(home / name): (home / name).is_dir() for name in DIRECTORIES}
    failures = [path for path, exists in directories.items() if not exists]
    warnings = [name for name, exists in commands.items() if not exists]
    watchdog = Path(__file__).resolve().parent / "watchdog.sh"
    operational = {
        "logs_writable": os.access(home / "logs", os.W_OK),
        "watchdog_installed": watchdog.is_file() and os.access(watchdog, os.X_OK),
        "last_watchdog": operations.maintenance_status()["last_watchdog"],
    }
    if not operational["logs_writable"]:
        failures.append(str(home / "logs") + " (sem escrita)")
    if not operational["watchdog_installed"]:
        failures.append(str(watchdog))
    if not operational["last_watchdog"]:
        warnings.append("watchdog ainda não executado")
    return {
        "status": "healthy" if not failures else "down",
        "commands": commands,
        "directories": directories,
        "warnings": warnings,
        "failures": failures,
        "operational": operational,
    }


def collect() -> dict[str, Any]:
    home = server_home()
    services = service_status()
    required = (services["ssh"], services["nginx"], services["api"])
    overall = "healthy" if all(item["running"] for item in required) else "down"
    current_load_average = load_average()
    cpu_count = os.cpu_count() or 0
    load_percent = round(min(current_load_average[0] / cpu_count * 100, 100), 1) if current_load_average and cpu_count else 0.0

    return {
        "status": overall,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": os.environ.get("FIZLAB_VERSION", "0.2.0-dev"),
        "system": {
            "hostname": socket.gethostname(),
            "platform": detect_platform(),
            "architecture": platform.machine(),
            "cpu_count": cpu_count,
            "load_average": current_load_average,
            "load_percent": load_percent,
            "memory": memory(),
            "storage": storage(home),
            "uptime_seconds": uptime_seconds(),
            "local_ip": local_ip(),
            "server_home": str(home),
        },
        "services": services,
        "doctor": doctor(),
        "monitoring": operations.maintenance_status(),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Informações do nó FizLab")
    parser.add_argument("--doctor", action="store_true", help="exibe apenas o diagnóstico")
    parser.add_argument("--summary", action="store_true", help="exibe um resumo em uma linha")
    args = parser.parse_args()
    payload = collect()

    if args.doctor:
        payload = payload["doctor"]
    if args.summary:
        services = collect()["services"]
        states = ", ".join(f"{name}={data['status']}" for name, data in services.items())
        print(states)
        return
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
