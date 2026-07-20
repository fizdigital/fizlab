#!/usr/bin/env bash

set -Eeuo pipefail
PROJECT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"
SERVER_HOME="$(get_server_home)"
load_fizlab_config

case "$FIZLAB_WATCHDOG_INTERVAL_MINUTES" in
    ''|*[!0-9]*) FIZLAB_WATCHDOG_INTERVAL_MINUTES=5 ;;
esac
if [ "$FIZLAB_WATCHDOG_INTERVAL_MINUTES" -lt 1 ] || [ "$FIZLAB_WATCHDOG_INTERVAL_MINUTES" -gt 59 ]; then
    FIZLAB_WATCHDOG_INTERVAL_MINUTES=5
fi

if ! command_exists crontab; then
    log_warning "crontab não disponível; agendamentos de monitoramento não instalados."
    exit 0
fi

MARKER="# FizLab managed monitoring"
CURRENT="$(crontab -l 2>/dev/null || true)"
CLEAN="$(printf '%s\n' "$CURRENT" | awk -v marker="$MARKER" '
    $0 == marker { skip=2; next }
    skip > 0 { skip--; next }
    { print }
')"
{
    printf '%s\n' "$CLEAN" | sed '/^[[:space:]]*$/d'
    printf '%s\n' "$MARKER"
    printf '*/%s * * * * SERVER_HOME=%s bash %s/scripts/watchdog.sh\n' "$FIZLAB_WATCHDOG_INTERVAL_MINUTES" "$SERVER_HOME" "$PROJECT_DIR"
    printf '17 3 * * * SERVER_HOME=%s bash %s/scripts/maintenance.sh\n' "$SERVER_HOME" "$PROJECT_DIR"
} | crontab -
log_success "Watchdog e manutenção programados no cron."
