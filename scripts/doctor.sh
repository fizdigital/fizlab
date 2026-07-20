#!/usr/bin/env bash

set -u

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"

PLATFORM="$(detect_platform)"
SERVER_HOME="$(get_server_home)"
load_fizlab_config

if [ "${1:-}" = "--json" ]; then
    export SERVER_HOME FIZLAB_VERSION
    exec python "$PROJECT_DIR/scripts/system_info.py" --doctor
fi

PASS_COUNT=0
WARNING_COUNT=0
FAIL_COUNT=0

check_command() {
    local command_name="$1"

    if command_exists "$command_name"; then
        log_success "Comando disponível: $command_name"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_warning "Comando ausente: $command_name"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
}

check_directory() {
    local directory="$1"

    if [ -d "$directory" ]; then
        log_success "Diretório encontrado: $directory"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_error "Diretório ausente: $directory"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

check_termux_boot() {
    local boot_directory="$HOME/.termux/boot"
    local boot_script="$boot_directory/00-fizlab-start"
    local boot_entry

    if [ -x "$boot_script" ]; then
        log_success "Termux:Boot configurado: $boot_script"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_error "Termux:Boot não configurado ou sem permissão de execução: $boot_script"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    for boot_entry in "$boot_directory"/*; do
        if [ -f "$boot_entry" ] && [ -x "$boot_entry" ] && [ "$boot_entry" != "$boot_script" ]; then
            log_warning "Entrada adicional executável no Termux:Boot: $boot_entry"
            WARNING_COUNT=$((WARNING_COUNT + 1))
        fi
    done
}

check_process() {
    local process_name="$1"
    local required="${2:-no}"

    if process_is_running "$process_name"; then
        log_success "Serviço ativo: $process_name"
        PASS_COUNT=$((PASS_COUNT + 1))
    elif [ "$required" = "yes" ]; then
        log_error "Serviço inativo: $process_name"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        log_warning "Serviço inativo: $process_name"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
}

check_managed_process() {
    local service_name="$1"
    local pid_file="$2"

    if pid_file_is_running "$pid_file"; then
        log_success "Serviço ativo: $service_name"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_error "Serviço inativo: $service_name"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

check_monitoring() {
    local watchdog="$PROJECT_DIR/scripts/watchdog.sh"
    local maintenance="$PROJECT_DIR/scripts/maintenance.sh"

    if [ -x "$watchdog" ] && [ -x "$maintenance" ]; then
        log_success "Rotinas de watchdog e manutenção instaladas."
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_error "Rotinas de monitoramento ausentes ou sem permissão de execução."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if [ -w "$SERVER_HOME/logs" ]; then
        log_success "Diretório de logs permite gravação."
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_error "Diretório de logs não permite gravação."
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if command_exists crontab && crontab -l 2>/dev/null | grep -Fq '# FizLab managed monitoring'; then
        log_success "Watchdog e manutenção configurados no cron."
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_warning "Agendamentos de monitoramento não encontrados no cron."
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
}

check_remote_access() {
    local managed_ssh="$SERVER_HOME/config/sshd_config"

    case "$FIZLAB_DASHBOARD_ACCESS" in
        lan)
            log_warning "Dashboard ainda disponível na rede local; habilite tailnet após validar o Tailscale."
            WARNING_COUNT=$((WARNING_COUNT + 1))
            ;;
        tailnet)
            log_success "Dashboard restrito a localhost e Tailnet."
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        *)
            log_error "Modo de dashboard inválido: $FIZLAB_DASHBOARD_ACCESS"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
    esac

    if [ "$FIZLAB_SSH_HARDENING" = "enabled" ]; then
        if [ -s "$managed_ssh" ] && [ -s "$HOME/.ssh/authorized_keys" ]; then
            log_success "Política SSH por chave e Tailnet configurada."
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            log_error "Política SSH marcada como ativa, mas a configuração ou chave autorizada está ausente."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        log_warning "Política SSH por chave ainda não foi aplicada."
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
}

get_local_ip() {
    python - <<'PY'
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    sock.connect(("8.8.8.8", 80))
    print(sock.getsockname()[0])
except OSError:
    print("indisponível")
finally:
    sock.close()
PY
}

printf '\n'
printf '============================================\n'
printf '              FizLab Doctor                 \n'
printf '============================================\n'
printf 'Versão:       %s\n' "$FIZLAB_VERSION"
printf 'Plataforma:   %s\n' "$PLATFORM"
printf 'Usuário:      %s\n' "$(whoami)"
printf 'Diretório:    %s\n' "$SERVER_HOME"
printf 'IP local:     %s\n' "$(get_local_ip 2>/dev/null || printf 'indisponível')"
printf 'Data:         %s\n' "$(date)"
printf '============================================\n\n'

check_command bash
check_command curl
check_command wget
check_command git
check_command ssh
check_command sshd
check_command pgrep
check_command python
check_command php
check_command nginx
check_command sqlite3
check_command crond

check_directory "$SERVER_HOME"
check_directory "$SERVER_HOME/www"
check_directory "$SERVER_HOME/api"
check_directory "$SERVER_HOME/git"
check_directory "$SERVER_HOME/backups"
check_directory "$SERVER_HOME/scripts"
check_directory "$SERVER_HOME/logs"
check_directory "$SERVER_HOME/files"
check_directory "$SERVER_HOME/databases"

if [ "$PLATFORM" = "termux" ]; then
    check_termux_boot
    check_process sshd yes
    check_process crond no
fi

if [ -f "$SERVER_HOME/config/fizlab.env" ]; then
    check_managed_process fizlab-api "$SERVER_HOME/run/fizlab-api.pid"
else
    log_warning "FizLab API ainda não configurada."
    WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ -f "$SERVER_HOME/config/nginx.conf" ]; then
    check_managed_process nginx "$SERVER_HOME/run/nginx.pid"
else
    log_warning "nginx ainda não configurado."
    WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if command_exists python; then
    printf '\nResumo de serviços: %s\n' "$(SERVER_HOME="$SERVER_HOME" FIZLAB_VERSION="$FIZLAB_VERSION" python "$PROJECT_DIR/scripts/system_info.py" --summary)"
fi

check_monitoring
check_remote_access

printf '\n'
printf '============================================\n'
printf 'Aprovados:    %s\n' "$PASS_COUNT"
printf 'Avisos:       %s\n' "$WARNING_COUNT"
printf 'Falhas:       %s\n' "$FAIL_COUNT"
printf '============================================\n'

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi

exit 0
