#!/usr/bin/env python3
"""Watchdog portátil dos serviços gerenciados pelo FizLab."""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

import operations


PROJECT_DIR = Path(__file__).resolve().parent.parent
HOME = operations.home()
SERVICES = {
    "api": (HOME / "run/fizlab-api.pid", "fizlab_api.py", PROJECT_DIR / "services/api/start.sh"),
    "nginx": (HOME / "run/nginx.pid", "nginx", PROJECT_DIR / "services/nginx/start.sh"),
}


def process_matches(pid_file: Path, marker: str) -> bool:
    try:
        pid = int(pid_file.read_text(encoding="utf-8").strip())
        os.kill(pid, 0)
        cmdline = Path(f"/proc/{pid}/cmdline")
        if cmdline.is_file():
            return marker in cmdline.read_bytes().replace(b"\0", b" ").decode(errors="replace")
        return True
    except (OSError, ValueError):
        return False


def api_healthy() -> bool:
    host = os.environ.get("FIZLAB_API_HOST", "127.0.0.1")
    port = int(os.environ.get("FIZLAB_API_PORT", "8765"))
    try:
        with socket.create_connection((host, port), timeout=2):
            return True
    except OSError:
        return False


def restart(service: str, start_script: Path) -> bool:
    max_attempts = operations.positive_int("FIZLAB_WATCHDOG_MAX_ATTEMPTS", 3, maximum=10)
    cooldown = operations.positive_int("FIZLAB_WATCHDOG_COOLDOWN_SECONDS", 300, minimum=0)
    state_file = HOME / "run" / f"watchdog-{service}.json"
    try:
        state = json.loads(state_file.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        state = {}
    if time.time() - float(state.get("last_attempt", 0)) < cooldown:
        operations.record_event(service, "restart_cooldown", "Recuperação adiada pelo cooldown")
        return False
    pid_file, marker, _ = SERVICES[service]
    if service == "api" and process_matches(pid_file, marker) and not api_healthy():
        subprocess.run(
            ["bash", str(PROJECT_DIR / "services/api/stop.sh")],
            env={**os.environ, "SERVER_HOME": str(HOME)},
            check=False,
        )
    for attempt in range(1, max_attempts + 1):
        operations.record_event(service, "restart_attempt", f"tentativa {attempt}/{max_attempts}")
        state_file.write_text(json.dumps({"last_attempt": time.time(), "attempt": attempt}), encoding="utf-8")
        result = subprocess.run(["bash", str(start_script)], env={**os.environ, "SERVER_HOME": str(HOME)}, check=False)
        time.sleep(1)
        healthy = process_matches(pid_file, marker) and (service != "api" or api_healthy())
        if result.returncode == 0 and healthy:
            operations.record_event(service, "service_recovered", f"recuperado na tentativa {attempt}")
            state_file.unlink(missing_ok=True)
            return True
    operations.record_event(service, "restart_failed", f"falhou após {max_attempts} tentativas")
    return False


def main() -> int:
    lock = HOME / "run" / "watchdog.lock"
    lock.parent.mkdir(parents=True, exist_ok=True)
    try:
        lock.mkdir()
    except FileExistsError:
        owner = lock / "pid"
        try:
            pid = int(owner.read_text(encoding="utf-8"))
            os.kill(pid, 0)
            print("Watchdog já está em execução.")
            return 0
        except (OSError, ValueError):
            owner.unlink(missing_ok=True)
            try:
                lock.rmdir()
                lock.mkdir()
            except OSError:
                print("Não foi possível recuperar o lock órfão do watchdog.")
                return 1
    (lock / "pid").write_text(str(os.getpid()), encoding="utf-8")
    failed = []
    try:
        for name, (pid_file, marker, start_script) in SERVICES.items():
            healthy = process_matches(pid_file, marker) and (name != "api" or api_healthy())
            if healthy:
                continue
            operations.record_event(name, "service_down", "serviço ou health check indisponível")
            if not restart(name, start_script):
                failed.append(name)
        timestamp = operations.now()
        operations.set_metadata("last_watchdog", timestamp)
        operations.set_metadata("watchdog_status", "down" if failed else "healthy")
        print(f"Watchdog concluído: {'falha em ' + ', '.join(failed) if failed else 'serviços saudáveis'}")
        return 1 if failed else 0
    finally:
        (lock / "pid").unlink(missing_ok=True)
        lock.rmdir()


if __name__ == "__main__":
    sys.exit(main())
