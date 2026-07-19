#!/usr/bin/env bash

install_debian_packages() {
    if [ "$(id -u)" -eq 0 ]; then
        local privilege=""
    elif command_exists sudo; then
        local privilege="sudo"
    else
        log_error "Este ambiente exige root ou sudo."
        return 1
    fi

    log_info "Atualizando repositórios Debian/Ubuntu..."

    $privilege apt-get update || return 1

    local packages=(
        bash
        ca-certificates
        curl
        wget
        git
        nano
        vim
        tree
        openssh-server
        python3
        python3-pip
        python3-venv
        python-is-python3
        php
        php-cli
        nginx
        sqlite3
        cron
    )

    log_info "Instalando pacotes básicos..."

    $privilege apt-get install -y "${packages[@]}" || {
        log_error "Falha ao instalar pacotes Debian/Ubuntu."
        return 1
    }

    log_success "Pacotes Debian/Ubuntu instalados."
}
