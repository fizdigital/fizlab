#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"

SERVER_HOME="$(get_server_home)"
TARGET="$SERVER_HOME/config/nginx.conf"
TEMPLATE="$PROJECT_DIR/templates/nginx/nginx.conf.template"

load_fizlab_config
mkdir -p "$SERVER_HOME/config" "$SERVER_HOME/run" "$SERVER_HOME/logs/nginx"

sed \
    -e "s|__SERVER_HOME__|$SERVER_HOME|g" \
    -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
    -e "s|__HTTP_HOST__|$FIZLAB_HTTP_HOST|g" \
    -e "s|__HTTP_PORT__|$FIZLAB_HTTP_PORT|g" \
    -e "s|__API_HOST__|$FIZLAB_API_HOST|g" \
    -e "s|__API_PORT__|$FIZLAB_API_PORT|g" \
    "$TEMPLATE" > "$TARGET.tmp"

mv "$TARGET.tmp" "$TARGET"
chmod 600 "$TARGET"

if command_exists nginx; then
    nginx -t -c "$TARGET" -p "$SERVER_HOME/"
fi

log_success "Nginx configurado: $TARGET"
