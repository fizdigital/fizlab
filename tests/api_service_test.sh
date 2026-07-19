#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
SERVER_HOME="$TEST_DIRECTORY/server"
PORT=18766

cleanup() {
    local status="$?"
    if [ "$status" -ne 0 ] && [ -f "$SERVER_HOME/logs/python/fizlab-api.log" ]; then
        printf '\n--- FizLab API log ---\n' >&2
        cat "$SERVER_HOME/logs/python/fizlab-api.log" >&2
        printf '%s\n' '--- fim do log ---' >&2
    fi
    SERVER_HOME="$SERVER_HOME" bash "$PROJECT_DIR/services/api/stop.sh" >/dev/null 2>&1 || true
    rm -rf "$TEST_DIRECTORY"
    return "$status"
}
trap cleanup EXIT

mkdir -p "$SERVER_HOME/config" "$SERVER_HOME/logs/python" "$SERVER_HOME/run"
cp "$PROJECT_DIR/config/fizlab.env.example" "$SERVER_HOME/config/fizlab.env"
sed -i "s/FIZLAB_API_PORT=8765/FIZLAB_API_PORT=$PORT/" "$SERVER_HOME/config/fizlab.env"

SERVER_HOME="$SERVER_HOME" bash "$PROJECT_DIR/services/api/start.sh"
SERVER_HOME="$SERVER_HOME" bash "$PROJECT_DIR/services/api/start.sh"

python - "$PORT" <<'PY'
import json
import sys
import urllib.error
import urllib.request

try:
    with urllib.request.urlopen(f"http://127.0.0.1:{sys.argv[1]}/api/v1/health") as response:
        payload = json.load(response)
except urllib.error.HTTPError as error:
    print(error.read().decode("utf-8", errors="replace"), file=sys.stderr)
    raise
assert payload["status"] == "healthy"
PY

SERVER_HOME="$SERVER_HOME" bash "$PROJECT_DIR/services/api/stop.sh"
test ! -f "$SERVER_HOME/run/fizlab-api.pid"

printf 'api_service_test: OK\n'
