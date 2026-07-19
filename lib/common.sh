#!/usr/bin/env bash

# ============================================================
# FizLab - Funções compartilhadas
# ============================================================

set -o pipefail

FIZLAB_NAME="FizLab"
FIZLAB_VERSION="0.1.0"

log_info() {
    printf '\033[1;34m[INFO]\033[0m %s\n' "$1"
}

log_success() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$1"
}

log_warning() {
    printf '\033[1;33m[AVISO]\033[0m %s\n' "$1"
}

log_error() {
    printf '\033[1;31m[ERRO]\033[0m %s\n' "$1" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

process_is_running() {
    local process_name="$1"

    pgrep -x "$process_name" >/dev/null 2>&1 ||
        pgrep -f "(^|/)${process_name}([[:space:]]|$)" >/dev/null 2>&1
}

create_directory() {
    local directory="$1"
    local permissions="${2:-755}"

    if mkdir -p "$directory"; then
        chmod "$permissions" "$directory"
        log_success "Diretório preparado: $directory"
    else
        log_error "Não foi possível criar: $directory"
        return 1
    fi
}

detect_platform() {
    if command_exists termux-info || [ -n "${PREFIX:-}" ] && [[ "$PREFIX" == *"com.termux"* ]]; then
        printf '%s\n' "termux"
        return
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release

        case "${ID:-unknown}" in
            ubuntu)
                printf '%s\n' "ubuntu"
                ;;
            debian)
                printf '%s\n' "debian"
                ;;
            fedora)
                printf '%s\n' "fedora"
                ;;
            arch)
                printf '%s\n' "arch"
                ;;
            *)
                printf '%s\n' "${ID:-linux}"
                ;;
        esac

        return
    fi

    printf '%s\n' "unknown"
}

get_server_home() {
    printf '%s\n' "${SERVER_HOME:-$HOME/server}"
}

confirm_action() {
    local message="$1"
    local answer

    printf '%s [s/N]: ' "$message"
    read -r answer

    case "$answer" in
        s|S|sim|SIM|Sim)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
