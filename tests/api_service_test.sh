#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
SERVER_HOME="$TEST_DIRECTORY/server"
PORT=18766

cleanup() {
    SERVER_HOME="$SERVER_HOME" bash "$PROJECT_DIR/services/api/stop.sh" >/dev/null 2>&1 || true
    rm -rf "$TEST_DIRECTORY"
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
import urllib.request

with urllib.request.urlopen(f"http://127.0.0.1:{sys.argv[1]}/api/v1/health") as response:
    payload = json.load(response)
assert payload["status"] == "healthy"
PY

SERVER_HOME="$SERVER_HOME" bash "$PROJECT_DIR/services/api/stop.sh"
test ! -f "$SERVER_HOME/run/fizlab-api.pid"

printf 'api_service_test: OK\n'
