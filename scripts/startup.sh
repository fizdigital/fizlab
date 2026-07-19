#!/usr/bin/env bash

set -u

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

source "$PROJECT_DIR/lib/common.sh"

SERVER_HOME="$(get_server_home)"
LOG_DIRECTORY="$SERVER_HOME/logs/system"

mkdir -p "$LOG_DIRECTORY"

LOG_FILE="$LOG_DIRECTORY/startup-$(date +%Y-%m-%d_%H-%M-%S).log"

exec >> "$LOG_FILE" 2>&1

printf '\n'
printf '============================================\n'
printf '            Inicialização FizLab            \n'
printf '============================================\n'
printf 'Data:        %s\n' "$(date)"
printf 'Plataforma:  %s\n' "$(detect_platform)"
printf 'Usuário:     %s\n' "$(whoami)"
printf 'Projeto:     %s\n' "$PROJECT_DIR"
printf '============================================\n\n'

start_process() {
    local process_name="$1"
    shift

    if pgrep -x "$process_name" >/dev/null 2>&1; then
        log_success "$process_name já está em execução."
        return 0
    fi

    log_info "Iniciando $process_name..."

    if "$@"; then
        sleep 1

        if pgrep -x "$process_name" >/dev/null 2>&1; then
            log_success "$process_name iniciado."
        else
            log_warning "$process_name foi chamado, mas não foi confirmado."
        fi
    else
        log_error "Falha ao iniciar $process_name."
        return 1
    fi
}

log_info "Aguardando a inicialização do Android..."
sleep 15

if command_exists termux-wake-lock; then
    termux-wake-lock || log_warning "Não foi possível ativar o wake lock."
else
    log_warning "Comando termux-wake-lock não disponível."
fi

if command_exists sshd; then
    start_process sshd sshd
else
    log_error "sshd não está instalado."
fi

if command_exists crond; then
    start_process crond crond
else
    log_warning "crond ainda não está instalado."
fi

log_success "Rotina de inicialização concluída."
log_info "Log salvo em: $LOG_FILE"
