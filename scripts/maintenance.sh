#!/usr/bin/env bash

set -Eeuo pipefail
PROJECT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"
SERVER_HOME="$(get_server_home)"
load_fizlab_config
mkdir -p "$SERVER_HOME/logs/system" "$SERVER_HOME/run"
export SERVER_HOME

case "${1:-}" in
    --dry-run) python "$PROJECT_DIR/scripts/maintenance.py" --dry-run ;;
    --status) python "$PROJECT_DIR/scripts/maintenance.py" --status ;;
    "") python "$PROJECT_DIR/scripts/maintenance.py" | tee -a "$SERVER_HOME/logs/system/maintenance.log" ;;
    *) printf 'Uso: %s [--dry-run|--status]\n' "$0" >&2; exit 2 ;;
esac
