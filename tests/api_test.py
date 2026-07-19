#!/usr/bin/env python3

import json
import os
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
PORT = "18765"

with tempfile.TemporaryDirectory() as temporary_directory:
    server_home = Path(temporary_directory) / "server"
    for directory in ("www", "api", "git", "backups", "scripts", "logs", "files", "databases"):
        (server_home / directory).mkdir(parents=True, exist_ok=True)

    env = {
        **os.environ,
        "SERVER_HOME": str(server_home),
        "FIZLAB_API_HOST": "127.0.0.1",
        "FIZLAB_API_PORT": PORT,
    }
    process = subprocess.Popen(
        ["python", str(PROJECT_DIR / "api" / "fizlab_api.py")],
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(30):
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/api/v1/health") as response:
                    health = json.load(response)
                break
            except (OSError, urllib.error.URLError):
                time.sleep(0.1)
        else:
            raise AssertionError("A API não iniciou dentro do prazo")

        assert health["status"] == "healthy"
        with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/api/v1/status") as response:
            status = json.load(response)
        assert "system" in status and "services" in status and "doctor" in status

        try:
            urllib.request.urlopen(f"http://127.0.0.1:{PORT}/unknown")
            raise AssertionError("A rota desconhecida deveria retornar 404")
        except urllib.error.HTTPError as error:
            assert error.code == 404
    finally:
        process.terminate()
        process.wait(timeout=5)

print("api_test: OK")
