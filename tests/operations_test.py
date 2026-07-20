#!/usr/bin/env python3

import importlib.util
import os
import sqlite3
import tempfile
import time
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
MODULE = PROJECT_DIR / "scripts" / "operations.py"
spec = importlib.util.spec_from_file_location("operations", MODULE)
assert spec and spec.loader
operations = importlib.util.module_from_spec(spec)
spec.loader.exec_module(operations)

with tempfile.TemporaryDirectory() as temporary:
    home = Path(temporary) / "server"
    os.environ.update({
        "SERVER_HOME": str(home),
        "FIZLAB_LOG_MAX_SIZE_MB": "1",
        "FIZLAB_LOG_RETENTION_DAYS": "1",
        "FIZLAB_LOG_ROTATIONS": "2",
        "FIZLAB_LOG_TAIL_MAX_LINES": "10",
        "FIZLAB_LOG_TAIL_MAX_BYTES": "1024",
    })
    log = home / "logs/system/watchdog.log"
    log.parent.mkdir(parents=True)
    log.write_text("\n".join(f"linha {index}" for index in range(30)), encoding="utf-8")

    assert operations.tail_log("watchdog", 999)["line_count"] == 10
    try:
        operations.tail_log("../config", 10)
        raise AssertionError("ID arbitrário deveria ser rejeitado")
    except KeyError:
        pass

    log.write_bytes(b"x" * (1024 * 1024 + 1))
    preview = operations.run_maintenance(dry_run=True)
    assert preview["action_count"] > 0 and log.stat().st_size > 1024 * 1024
    result = operations.run_maintenance()
    assert result["status"] == "completed"
    assert log.stat().st_size == 0
    assert (log.parent / "watchdog.log.1.gz").is_file()

print("operations_test: OK")
