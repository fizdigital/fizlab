#!/usr/bin/env python3

import importlib.util
import json
from pathlib import Path
from unittest import mock


PROJECT_DIR = Path(__file__).resolve().parent.parent
MODULE_PATH = PROJECT_DIR / "scripts" / "remote_access.py"
spec = importlib.util.spec_from_file_location("remote_access", MODULE_PATH)
assert spec and spec.loader
remote_access = importlib.util.module_from_spec(spec)
spec.loader.exec_module(remote_access)

assert remote_access.exposure("127.0.0.1") == "local"
assert remote_access.exposure("100.100.100.100") == "tailnet"
assert remote_access.exposure("0.0.0.0") == "network"

with mock.patch.object(remote_access, "listeners", return_value=[
    {"protocol": "tcp", "address": "127.0.0.1", "port": 8765},
    {"protocol": "tcp", "address": "0.0.0.0", "port": 8080},
    {"protocol": "tcp", "address": "0.0.0.0", "port": 31337},
]):
    result = remote_access.audit()
    assert result["visibility"] == "complete"
    assert result["listeners"][0]["service"] == "api"
    assert any("dashboard" in warning.lower() for warning in result["warnings"])
    assert any("31337" in warning for warning in result["warnings"])
    json.dumps(result)

with mock.patch.object(remote_access, "listeners", return_value=[]):
    result = remote_access.audit()
    assert result["visibility"] == "limited"
    assert result["warnings"]

print("remote_access_test: OK")
