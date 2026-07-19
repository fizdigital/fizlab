#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
MOCK_BIN="$TEST_DIRECTORY/bin"

cleanup() {
    rm -rf "$TEST_DIRECTORY"
}
trap cleanup EXIT

mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/nginx" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$MOCK_BIN/nginx"

env \
    PATH="$MOCK_BIN:$PATH" \
    SERVER_HOME="$TEST_DIRECTORY/server" \
    FIZLAB_HTTP_PORT=9080 \
    FIZLAB_API_PORT=9765 \
    bash "$PROJECT_DIR/services/nginx/configure.sh"

CONFIG="$TEST_DIRECTORY/server/config/nginx.conf"
grep -Fq "listen 0.0.0.0:9080;" "$CONFIG"
grep -Fq "proxy_pass http://127.0.0.1:9765;" "$CONFIG"
grep -Fq "root $PROJECT_DIR/dashboard;" "$CONFIG"
grep -Fq "text/css css;" "$CONFIG"
grep -Fq "application/javascript js;" "$CONFIG"

printf 'nginx_config_test: OK\n'
