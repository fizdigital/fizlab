#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"

SERVER_HOME="$(get_server_home)"
DATABASE="$SERVER_HOME/databases/sqlite/fizlab.db"

if ! command_exists python; then
    log_error "python é necessário para inicializar o SQLite."
    exit 1
fi

python "$PROJECT_DIR/database/init_db.py" "$DATABASE" --version 1
chmod 600 "$DATABASE"
log_success "SQLite configurado: $DATABASE"
