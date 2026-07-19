#!/usr/bin/env bash

set -u

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

source "$PROJECT_DIR/lib/common.sh"

SERVER_HOME="$(get_server_home)"
LOG_DIRECTORY="$SERVER_HOME/logs/system"
LOCK_DIRECTORY="$SERVER_HOME/run"
LOCK_FILE="$LOCK_DIRECTORY/startup.lock"
BOOT_MODE="${1:-}"
PROCESS_CHECK_ATTEMPTS="${FIZLAB_PROCESS_CHECK_ATTEMPTS:-10}"
PROCESS_CHECK_INTERVAL="${FIZLAB_PROCESS_CHECK_INTERVAL:-1}"
STARTUP_FAILED=0

case "$PROCESS_CHECK_ATTEMPTS" in
    ''|*[!0-9]*|0)
        PROCESS_CHECK_ATTEMPTS=10
        ;;
esac

if ! [[ "$PROCESS_CHECK_INTERVAL" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    PROCESS_CHECK_INTERVAL=1
fi

mkdir -p "$LOG_DIRECTORY" "$LOCK_DIRECTORY"

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
printf 'Modo:        %s\n' "${BOOT_MODE:---manual}"
printf '============================================\n\n'

if ! mkdir "$LOCK_FILE" 2>/dev/null; then
    log_warning "Outra rotina de inicialização já está em andamento."
    exit 0
fi
trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT

start_process() {
    local process_name="$1"
    local required="$2"
    local attempt
    shift
    shift

    if process_is_running "$process_name"; then
        log_success "$process_name já está em execução."
        return 0
    fi

    log_info "Iniciando $process_name..."

    if "$@"; then
        for ((attempt = 1; attempt <= PROCESS_CHECK_ATTEMPTS; attempt++)); do
            if process_is_running "$process_name"; then
                log_success "$process_name iniciado e confirmado (tentativa $attempt/$PROCESS_CHECK_ATTEMPTS)."
                return 0
            fi

            if [ "$attempt" -lt "$PROCESS_CHECK_ATTEMPTS" ]; then
                sleep "$PROCESS_CHECK_INTERVAL"
            fi
        done

        if [ "$required" = "yes" ]; then
            log_error "$process_name foi iniciado, mas não apareceu após $PROCESS_CHECK_ATTEMPTS tentativas."
        else
            log_warning "$process_name foi chamado, mas não foi confirmado."
        fi

        return 1
    else
        log_error "Falha ao iniciar $process_name."
        return 1
    fi
}

if [ "$BOOT_MODE" = "--boot" ]; then
    log_info "Aguardando o Android concluir a inicialização..."
    sleep "${FIZLAB_BOOT_DELAY:-25}"
fi

if command_exists termux-wake-lock; then
    termux-wake-lock || log_warning "Não foi possível ativar o wake lock."
else
    log_warning "Comando termux-wake-lock não disponível. Instale o Termux:API se quiser manter o wake lock."
fi

if command_exists sshd; then
    if ! start_process sshd yes sshd; then
        STARTUP_FAILED=1
    fi
else
    log_error "sshd não está instalado."
    STARTUP_FAILED=1
fi

if command_exists crond; then
    start_process crond no crond || true
else
    log_warning "crond ainda não está instalado."
fi

if [ "$STARTUP_FAILED" -ne 0 ]; then
    log_error "Rotina de inicialização concluída com falhas."
    log_info "Log salvo em: $LOG_FILE"
    exit 1
fi

log_success "Rotina de inicialização concluída com os serviços obrigatórios ativos."
log_info "Log salvo em: $LOG_FILE"
