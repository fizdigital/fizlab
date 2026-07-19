#!/usr/bin/env bash

install_termux_packages() {
    log_info "Atualizando os repositórios do Termux..."

    pkg update -y || {
        log_error "Falha ao atualizar os repositórios."
        return 1
    }

    local packages=(
        bash
        coreutils
        curl
        wget
        git
        nano
        vim
        tree
        openssh
        python
        php
        nginx
        sqlite
        cronie
        termux-api
    )

    log_info "Instalando pacotes básicos do FizLab..."

    pkg install -y "${packages[@]}" || {
        log_error "Falha ao instalar um ou mais pacotes."
        return 1
    }

    log_success "Pacotes do Termux instalados."
}
