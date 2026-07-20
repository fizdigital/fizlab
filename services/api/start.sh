#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"

SERVER_HOME="$(get_server_home)"
PID_FILE="$SERVER_HOME/run/fizlab-api.pid"
LOG_FILE="$SERVER_HOME/logs/python/fizlab-api.log"

load_fizlab_config
mkdir -p "$SERVER_HOME/run" "$SERVER_HOME/logs/python"

if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE")"
    if [[ "$PID" =~ ^[0-9]+$ ]] && kill -0 "$PID" 2>/dev/null; then
        if [ -r "/proc/$PID/cmdline" ] && tr '\0' ' ' < "/proc/$PID/cmdline" | grep -Fq "fizlab_api.py"; then
            log_success "FizLab API já está em execução (PID $PID)."
            exit 0
        fi
        log_warning "PID obsoleto encontrado para a FizLab API; será substituído."
    fi
    rm -f "$PID_FILE"
fi

if ! command_exists python; then
    log_error "python não está instalado."
    exit 1
fi

export SERVER_HOME FIZLAB_API_HOST FIZLAB_API_PORT FIZLAB_VERSION \
    FIZLAB_DASHBOARD_ACCESS FIZLAB_SSH_HARDENING FIZLAB_SSH_ACCESS
nohup python -u "$PROJECT_DIR/api/fizlab_api.py" >> "$LOG_FILE" 2>&1 &
PID=$!
printf '%s\n' "$PID" > "$PID_FILE"

for attempt in 1 2 3 4 5; do
    if kill -0 "$PID" 2>/dev/null && python -c \
        'import socket,sys; sock=socket.create_connection((sys.argv[1], int(sys.argv[2])), 1); sock.close()' \
        "$FIZLAB_API_HOST" "$FIZLAB_API_PORT" 2>/dev/null; then
        log_success "FizLab API iniciada (PID $PID)."
        exit 0
    fi
    if ! kill -0 "$PID" 2>/dev/null; then
        break
    fi
    sleep 1
done

rm -f "$PID_FILE"
log_error "A API não permaneceu em execução. Consulte $LOG_FILE"
exit 1
