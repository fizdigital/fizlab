#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"

ACTION="${1:-status}"

case "$ACTION" in
    start)
        bash "$PROJECT_DIR/services/api/start.sh"
        bash "$PROJECT_DIR/services/nginx/start.sh"
        ;;
    stop)
        bash "$PROJECT_DIR/services/nginx/stop.sh"
        bash "$PROJECT_DIR/services/api/stop.sh"
        ;;
    restart)
        "$0" stop
        "$0" start
        ;;
    status)
        SERVER_HOME="$(get_server_home)" FIZLAB_VERSION="$FIZLAB_VERSION" \
            python "$PROJECT_DIR/scripts/system_info.py" --summary
        ;;
    *)
        printf 'Uso: %s {start|stop|restart|status}\n' "$0" >&2
        exit 2
        ;;
esac
