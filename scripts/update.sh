#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

source "$PROJECT_DIR/lib/common.sh"

PLATFORM="$(detect_platform)"
SERVER_HOME="$(get_server_home)"

LOG_DIRECTORY="$SERVER_HOME/logs/system"
mkdir -p "$LOG_DIRECTORY"

LOG_FILE="$LOG_DIRECTORY/fizlab-update-$(date +%Y-%m-%d_%H-%M-%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

log_info "Iniciando atualização do FizLab."
log_info "Plataforma detectada: $PLATFORM"

case "$PLATFORM" in
    termux)
        pkg update -y
        pkg upgrade -y
        pkg autoclean -y || true
        ;;

    ubuntu|debian)
        if [ "$(id -u)" -eq 0 ]; then
            privilege=""
        elif command_exists sudo; then
            privilege="sudo"
        else
            log_error "sudo ou root é necessário."
            exit 1
        fi

        $privilege apt-get update
        $privilege apt-get upgrade -y
        $privilege apt-get autoremove -y
        $privilege apt-get autoclean -y
        ;;

    *)
        log_error "Plataforma não suportada: $PLATFORM"
        exit 1
        ;;
esac

log_success "Atualização concluída."
log_info "Log salvo em: $LOG_FILE"
