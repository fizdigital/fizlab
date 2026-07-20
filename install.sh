#!/usr/bin/env bash

# ============================================================
# FizLab Installer
# Versão inicial multiplataforma
# ============================================================

set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# shellcheck source=lib/common.sh
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"

PLATFORM="$(detect_platform)"
SERVER_HOME="$(get_server_home)"

LOG_DIRECTORY="$SERVER_HOME/logs/system"
mkdir -p "$LOG_DIRECTORY"

LOG_FILE="$LOG_DIRECTORY/install.log"

exec > >(tee -a "$LOG_FILE") 2>&1

handle_error() {
    local line="$1"
    local command="$2"

    log_error "Falha na linha $line."
    log_error "Comando: $command"
    log_error "Consulte o log: $LOG_FILE"
}

trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR

show_header() {
    clear 2>/dev/null || true

    printf '\n'
    printf '============================================\n'
    printf '             FizLab Installer               \n'
    printf '============================================\n'
    printf 'Versão:      %s\n' "$FIZLAB_VERSION"
    printf 'Plataforma:  %s\n' "$PLATFORM"
    printf 'Usuário:     %s\n' "$(whoami)"
    printf 'Diretório:   %s\n' "$SERVER_HOME"
    printf 'Log:         %s\n' "$LOG_FILE"
    printf '============================================\n\n'
}

create_server_structure() {
    log_info "Preparando estrutura do servidor..."

    create_directory "$SERVER_HOME" 700

    create_directory "$SERVER_HOME/www" 755
    create_directory "$SERVER_HOME/www/default" 755

    create_directory "$SERVER_HOME/api" 755
    create_directory "$SERVER_HOME/api/apps" 755
    create_directory "$SERVER_HOME/api/venvs" 755
    create_directory "$SERVER_HOME/api/shared" 755

    create_directory "$SERVER_HOME/git" 755
    create_directory "$SERVER_HOME/git/repositories" 755
    create_directory "$SERVER_HOME/git/working" 755

    create_directory "$SERVER_HOME/backups" 700
    create_directory "$SERVER_HOME/backups/sites" 700
    create_directory "$SERVER_HOME/backups/databases" 700
    create_directory "$SERVER_HOME/backups/configs" 700
    create_directory "$SERVER_HOME/backups/archives" 700

    create_directory "$SERVER_HOME/scripts" 700
    create_directory "$SERVER_HOME/scripts/backup" 700
    create_directory "$SERVER_HOME/scripts/maintenance" 700
    create_directory "$SERVER_HOME/scripts/monitoring" 700
    create_directory "$SERVER_HOME/scripts/startup" 700

    create_directory "$SERVER_HOME/logs" 755
    create_directory "$SERVER_HOME/logs/system" 755
    create_directory "$SERVER_HOME/logs/nginx" 755
    create_directory "$SERVER_HOME/logs/php" 755
    create_directory "$SERVER_HOME/logs/python" 755
    create_directory "$SERVER_HOME/logs/mariadb" 755
    create_directory "$SERVER_HOME/logs/cron" 755
    create_directory "$SERVER_HOME/tmp" 700

    create_directory "$SERVER_HOME/files" 755
    create_directory "$SERVER_HOME/files/documents" 755
    create_directory "$SERVER_HOME/files/projects" 755
    create_directory "$SERVER_HOME/files/installers" 755
    create_directory "$SERVER_HOME/files/media" 755
    create_directory "$SERVER_HOME/files/shared" 755
    create_directory "$SERVER_HOME/files/inbox" 755

    create_directory "$SERVER_HOME/databases" 700
    create_directory "$SERVER_HOME/databases/sqlite" 700
    create_directory "$SERVER_HOME/databases/dumps" 700

    create_directory "$SERVER_HOME/config" 700
    create_directory "$SERVER_HOME/run" 700
}

install_packages() {
    case "$PLATFORM" in
        termux)
            source "$PROJECT_DIR/profiles/termux.sh"
            install_termux_packages
            ;;

        ubuntu|debian)
            source "$PROJECT_DIR/profiles/debian.sh"
            install_debian_packages
            ;;

        *)
            log_error "Plataforma ainda não suportada: $PLATFORM"
            log_error "O instalador não fará alterações de pacotes."
            return 1
            ;;
    esac
}

create_default_page() {
    local page="$SERVER_HOME/www/default/index.html"

    if [ -f "$page" ]; then
        log_warning "Página inicial já existe. Nenhuma alteração realizada."
        return
    fi

    cat > "$page" <<'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>FizLab Node</title>
</head>
<body>
    <h1>FizLab Node</h1>
    <p>Estrutura inicial instalada com sucesso.</p>
</body>
</html>
EOF

    log_success "Página inicial criada."
}

configure_core_services() {
    log_info "Configurando os serviços base..."
    install_default_config "$PROJECT_DIR"
    bash "$PROJECT_DIR/services/sqlite/configure.sh"
    bash "$PROJECT_DIR/services/nginx/configure.sh"
    log_success "Serviços base configurados."
}

install_command_links() {
    local bin_directory="$HOME/.local/bin"

    mkdir -p "$bin_directory"

    ln -sfn "$PROJECT_DIR/install.sh" "$bin_directory/fizlab-install"
    ln -sfn "$PROJECT_DIR/scripts/update.sh" "$bin_directory/fizlab-update"
    ln -sfn "$PROJECT_DIR/scripts/doctor.sh" "$bin_directory/fizlab-doctor"
    ln -sfn "$PROJECT_DIR/scripts/startup.sh" "$bin_directory/fizlab-start"
    ln -sfn "$PROJECT_DIR/scripts/services.sh" "$bin_directory/fizlab-services"
    ln -sfn "$PROJECT_DIR/scripts/watchdog.sh" "$bin_directory/fizlab-watchdog"
    ln -sfn "$PROJECT_DIR/scripts/maintenance.sh" "$bin_directory/fizlab-maintenance"


    if ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
    fi

    log_success "Comandos do FizLab instalados em $bin_directory."
}

main() {
    show_header

    log_info "Iniciando instalação..."

    create_server_structure
    install_packages
    configure_core_services
    create_default_page
    install_command_links
    bash "$PROJECT_DIR/scripts/install-monitoring-cron.sh"

    log_success "Instalação inicial concluída."
    log_info "Recarregue o shell com: source ~/.bashrc"
    log_info "Depois execute: fizlab-doctor"
}

main "$@"
