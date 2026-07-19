#!/usr/bin/env bash

set -u

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

source "$PROJECT_DIR/lib/common.sh"

PLATFORM="$(detect_platform)"
SERVER_HOME="$(get_server_home)"

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
    local boot_script="$HOME/.termux/boot/00-fizlab-start"

    if [ -x "$boot_script" ]; then
        log_success "Termux:Boot configurado: $boot_script"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log_error "Termux:Boot não configurado ou sem permissão de execução: $boot_script"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

check_process() {
    local process_name="$1"
    local required="${2:-no}"

    if pgrep -x "$process_name" >/dev/null 2>&1; then
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
