#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
MOCK_BIN="$TEST_DIRECTORY/bin"
TEST_HOME="$TEST_DIRECTORY/home"
SERVER_HOME="$TEST_HOME/server"

cleanup() {
    rm -rf "$TEST_DIRECTORY"
}
trap cleanup EXIT

mkdir -p "$MOCK_BIN" "$TEST_HOME"
for command_name in pkg nginx termux-info clear; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$MOCK_BIN/$command_name"
    chmod +x "$MOCK_BIN/$command_name"
done

run_install() {
    env \
        HOME="$TEST_HOME" \
        SERVER_HOME="$SERVER_HOME" \
        PREFIX="/data/data/com.termux/files/usr" \
        PATH="$MOCK_BIN:$PATH" \
        bash "$PROJECT_DIR/install.sh"
}

run_install >/dev/null
test -f "$SERVER_HOME/config/fizlab.env"
test -f "$SERVER_HOME/config/nginx.conf"
test -f "$SERVER_HOME/databases/sqlite/fizlab.db"
test -L "$TEST_HOME/.local/bin/fizlab-services"
test -L "$TEST_HOME/.local/bin/fizlab-watchdog"
test -L "$TEST_HOME/.local/bin/fizlab-maintenance"
HOME="$TEST_HOME" SERVER_HOME="$SERVER_HOME" \
    "$TEST_HOME/.local/bin/fizlab-services" status >/dev/null

python - "$SERVER_HOME/databases/sqlite/fizlab.db" <<'PY'
import sqlite3
import sys
with sqlite3.connect(sys.argv[1]) as connection:
    connection.execute("INSERT INTO service_events(service, status) VALUES('test', 'healthy')")
    connection.commit()
PY

run_install >/dev/null
python - "$SERVER_HOME/databases/sqlite/fizlab.db" <<'PY'
import sqlite3
import sys
with sqlite3.connect(sys.argv[1]) as connection:
    count = connection.execute("SELECT COUNT(*) FROM service_events").fetchone()[0]
assert count == 1
PY

printf 'install_test: OK\n'
