#!/usr/bin/env python3

import importlib.util
import sqlite3
import tempfile
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
MODULE_PATH = PROJECT_DIR / "database" / "init_db.py"
spec = importlib.util.spec_from_file_location("init_db", MODULE_PATH)
assert spec and spec.loader
init_db = importlib.util.module_from_spec(spec)
spec.loader.exec_module(init_db)

with tempfile.TemporaryDirectory() as temporary_directory:
    database = Path(temporary_directory) / "databases" / "fizlab.db"
    init_db.initialize(database, "1")

    with sqlite3.connect(database) as connection:
        connection.execute(
            "INSERT INTO service_events(service, status) VALUES(?, ?)",
            ("api", "healthy"),
        )
        connection.commit()

    init_db.initialize(database, "1")

    with sqlite3.connect(database) as connection:
        version = connection.execute(
            "SELECT value FROM metadata WHERE key = 'schema_version'"
        ).fetchone()
        event_count = connection.execute("SELECT COUNT(*) FROM service_events").fetchone()

    assert version == ("1",)
    assert event_count == (1,)

print("sqlite_test: OK")
