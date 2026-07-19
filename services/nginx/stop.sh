#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"

SERVER_HOME="$(get_server_home)"
CONFIG="$SERVER_HOME/config/nginx.conf"
PID_FILE="$SERVER_HOME/run/nginx.pid"

if ! pid_file_is_running "$PID_FILE"; then
    log_info "nginx já está parado."
    exit 0
fi

nginx -c "$CONFIG" -p "$SERVER_HOME/" -s quit
log_success "Parada do nginx solicitada."
