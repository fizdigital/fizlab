#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"

if ! command_exists php; then
    log_warning "PHP não está instalado; o dashboard não depende dele."
    exit 2
fi

php -r 'exit(version_compare(PHP_VERSION, "8.0.0", ">=") ? 0 : 1);'
log_success "PHP CLI disponível: $(php -r 'echo PHP_VERSION;')"
