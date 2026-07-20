#!/usr/bin/env bash

load_fizlab_config() {
    local server_home
    local config_file

    server_home="$(get_server_home)"
    config_file="$server_home/config/fizlab.env"

    if [ -f "$config_file" ]; then
        # shellcheck disable=SC1090
        source "$config_file"
    fi

    export FIZLAB_HTTP_HOST="${FIZLAB_HTTP_HOST:-0.0.0.0}"
    export FIZLAB_HTTP_PORT="${FIZLAB_HTTP_PORT:-8080}"
    export FIZLAB_API_HOST="${FIZLAB_API_HOST:-127.0.0.1}"
    export FIZLAB_API_PORT="${FIZLAB_API_PORT:-8765}"
    export FIZLAB_DASHBOARD_REFRESH_SECONDS="${FIZLAB_DASHBOARD_REFRESH_SECONDS:-10}"
    export FIZLAB_WATCHDOG_INTERVAL_MINUTES="${FIZLAB_WATCHDOG_INTERVAL_MINUTES:-5}"
    export FIZLAB_WATCHDOG_MAX_ATTEMPTS="${FIZLAB_WATCHDOG_MAX_ATTEMPTS:-3}"
    export FIZLAB_WATCHDOG_COOLDOWN_SECONDS="${FIZLAB_WATCHDOG_COOLDOWN_SECONDS:-300}"
    export FIZLAB_LOG_MAX_SIZE_MB="${FIZLAB_LOG_MAX_SIZE_MB:-5}"
    export FIZLAB_LOG_RETENTION_DAYS="${FIZLAB_LOG_RETENTION_DAYS:-30}"
    export FIZLAB_LOG_ROTATIONS="${FIZLAB_LOG_ROTATIONS:-5}"
    export FIZLAB_LOG_TAIL_MAX_LINES="${FIZLAB_LOG_TAIL_MAX_LINES:-500}"
    export FIZLAB_LOG_TAIL_MAX_BYTES="${FIZLAB_LOG_TAIL_MAX_BYTES:-262144}"
}

install_default_config() {
    local project_dir="$1"
    local server_home
    local target

    server_home="$(get_server_home)"
    target="$server_home/config/fizlab.env"
    mkdir -p "$server_home/config"

    if [ ! -f "$target" ]; then
        cp "$project_dir/config/fizlab.env.example" "$target"
        chmod 600 "$target"
        log_success "Configuração padrão instalada: $target"
    else
        log_info "Configuração existente preservada: $target"
    fi
}
