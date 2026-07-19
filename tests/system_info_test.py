#!/usr/bin/env python3

import importlib.util
import json
import os
import subprocess
import tempfile
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
MODULE_PATH = PROJECT_DIR / "scripts" / "system_info.py"

spec = importlib.util.spec_from_file_location("system_info", MODULE_PATH)
assert spec and spec.loader
system_info = importlib.util.module_from_spec(spec)
spec.loader.exec_module(system_info)

with tempfile.TemporaryDirectory() as temporary_directory:
    home = Path(temporary_directory)
    os.environ["SERVER_HOME"] = str(home)

    initial = system_info.doctor()
    assert initial["status"] == "down"
    assert initial["failures"]

    for directory in system_info.DIRECTORIES:
        (home / directory).mkdir(parents=True, exist_ok=True)

    result = system_info.collect()
    assert result["doctor"]["status"] == "healthy"
    assert result["system"]["server_home"] == str(home)
    assert set(result["services"]) == {"ssh", "cron", "nginx", "api"}
    json.dumps(result)

    output = subprocess.check_output(
        ["bash", str(PROJECT_DIR / "scripts" / "doctor.sh"), "--json"],
        env={**os.environ, "SERVER_HOME": str(home)},
        text=True,
    )
    assert json.loads(output)["status"] == "healthy"

print("system_info_test: OK")
