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
    export FIZLAB_DASHBOARD_ACCESS="${FIZLAB_DASHBOARD_ACCESS:-lan}"
    export FIZLAB_TAILSCALE_CIDRS="${FIZLAB_TAILSCALE_CIDRS:-100.64.0.0/10,fd7a:115c:a1e0::/48}"
    export FIZLAB_SSH_HARDENING="${FIZLAB_SSH_HARDENING:-disabled}"
    export FIZLAB_SSH_ACCESS="${FIZLAB_SSH_ACCESS:-tailnet}"
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
