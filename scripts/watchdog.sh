#!/usr/bin/env bash

set -Eeuo pipefail
PROJECT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"
SERVER_HOME="$(get_server_home)"
load_fizlab_config
mkdir -p "$SERVER_HOME/logs/system" "$SERVER_HOME/run"
export SERVER_HOME
python "$PROJECT_DIR/scripts/watchdog.py" >> "$SERVER_HOME/logs/system/watchdog.log" 2>&1
