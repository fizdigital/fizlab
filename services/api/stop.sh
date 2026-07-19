#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"

SERVER_HOME="$(get_server_home)"
PID_FILE="$SERVER_HOME/run/fizlab-api.pid"

if [ ! -f "$PID_FILE" ]; then
    log_info "FizLab API já está parada."
    exit 0
fi

PID="$(cat "$PID_FILE")"
if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    log_error "Arquivo PID inválido: $PID_FILE"
    exit 1
fi

if kill -0 "$PID" 2>/dev/null; then
    if [ -r "/proc/$PID/cmdline" ] && ! tr '\0' ' ' < "/proc/$PID/cmdline" | grep -Fq "fizlab_api.py"; then
        log_error "O PID $PID não pertence à FizLab API."
        exit 1
    fi
    kill "$PID"
fi

rm -f "$PID_FILE"
log_success "FizLab API parada."
