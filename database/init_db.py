#!/usr/bin/env python3

import argparse
import sqlite3
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent


def initialize(database: Path, version: str) -> None:
    database.parent.mkdir(parents=True, exist_ok=True)
    schema = (PROJECT_DIR / "database" / "schema.sql").read_text(encoding="utf-8")
    with sqlite3.connect(database) as connection:
        connection.executescript(schema)
        connection.execute(
            """
            INSERT INTO metadata(key, value, updated_at)
            VALUES('schema_version', ?, CURRENT_TIMESTAMP)
            ON CONFLICT(key) DO UPDATE SET
                value = excluded.value,
                updated_at = CURRENT_TIMESTAMP
            """,
            (version,),
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Inicializa o SQLite do FizLab")
    parser.add_argument("database", type=Path)
    parser.add_argument("--version", default="1")
    args = parser.parse_args()
    initialize(args.database, args.version)
    print(f"SQLite inicializado: {args.database}")


if __name__ == "__main__":
    main()
