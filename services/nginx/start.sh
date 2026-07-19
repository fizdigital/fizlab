#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"

SERVER_HOME="$(get_server_home)"
CONFIG="$SERVER_HOME/config/nginx.conf"
PID_FILE="$SERVER_HOME/run/nginx.pid"

if pid_file_is_running "$PID_FILE"; then
    log_success "nginx já está em execução."
    exit 0
fi

if ! command_exists nginx; then
    log_error "nginx não está instalado."
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    log_error "Configuração ausente: $CONFIG"
    exit 1
fi

nginx -t -c "$CONFIG" -p "$SERVER_HOME/"
nginx -c "$CONFIG" -p "$SERVER_HOME/"
log_success "nginx iniciado."
