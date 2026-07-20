#!/usr/bin/env python3

import importlib.util
import os
import sys
import tempfile
from pathlib import Path
from unittest import mock

PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR / "scripts"))

with tempfile.TemporaryDirectory() as temporary:
    home = Path(temporary) / "server"
    (home / "run").mkdir(parents=True)
    os.environ["SERVER_HOME"] = str(home)
    spec = importlib.util.spec_from_file_location("watchdog", PROJECT_DIR / "scripts/watchdog.py")
    assert spec and spec.loader
    watchdog = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(watchdog)

    (home / "run/watchdog.lock").mkdir()
    (home / "run/watchdog.lock/pid").write_text(str(os.getpid()), encoding="utf-8")
    assert watchdog.main() == 0
    (home / "run/watchdog.lock/pid").unlink()
    (home / "run/watchdog.lock").rmdir()

    with mock.patch.object(watchdog, "process_matches", return_value=False), \
         mock.patch.object(watchdog, "restart", return_value=True) as restart:
        assert watchdog.main() == 0
        assert restart.call_count == 2

print("watchdog_test: OK")
