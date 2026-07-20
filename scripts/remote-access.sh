#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"

SERVER_HOME="$(get_server_home)"
ACTION="${1:-status}"
SSHD_CONFIG="$SERVER_HOME/config/sshd_config"

load_fizlab_config

system_sshd_config() {
    if [ -n "${PREFIX:-}" ] && [ -f "$PREFIX/etc/ssh/sshd_config" ]; then
        printf '%s\n' "$PREFIX/etc/ssh/sshd_config"
    elif [ -f /etc/ssh/sshd_config ]; then
        printf '%s\n' /etc/ssh/sshd_config
    else
        return 1
    fi
}

show_status() {
    SERVER_HOME="$SERVER_HOME" FIZLAB_DASHBOARD_ACCESS="$FIZLAB_DASHBOARD_ACCESS" \
        FIZLAB_SSH_HARDENING="$FIZLAB_SSH_HARDENING" FIZLAB_SSH_ACCESS="$FIZLAB_SSH_ACCESS" \
        python "$PROJECT_DIR/scripts/remote_access.py"
}

audit() {
    show_status
}

start_sshd() {
    if [ "$FIZLAB_SSH_HARDENING" = "enabled" ] && [ -f "$SSHD_CONFIG" ]; then
        log_info "Iniciando sshd com a política gerenciada do FizLab."
        exec sshd -f "$SSHD_CONFIG"
    fi
    exec sshd
}

secure_ssh() {
    [ "${1:-}" = "--apply" ] || {
        log_error "Ação protegida. Use: fizlab-remote secure-ssh --apply"
        exit 2
    }
    [ -s "$HOME/.ssh/authorized_keys" ] || {
        log_error "Nenhuma chave encontrada em $HOME/.ssh/authorized_keys. A política não foi alterada."
        exit 1
    }
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/authorized_keys"
    [ "$FIZLAB_SSH_ACCESS" = "tailnet" ] || {
        log_error "FIZLAB_SSH_ACCESS inválido: $FIZLAB_SSH_ACCESS (somente tailnet é aceito nesta Sprint)."
        exit 2
    }

    local base_config candidate
    base_config="$(system_sshd_config)" || {
        log_error "Não foi possível localizar o sshd_config do sistema."
        exit 1
    }
    candidate="$SSHD_CONFIG.new"
    mkdir -p "$SERVER_HOME/config"
    cp "$base_config" "$candidate"
    cat >> "$candidate" <<EOF

# FizLab managed remote-access policy — Sprint 5
# Mantém somente chaves autorizadas e limita novas sessões à Tailnet.
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
PermitRootLogin no
X11Forwarding no
AllowTcpForwarding yes
AllowUsers $(whoami)@100.64.0.0/10 $(whoami)@fd7a:115c:a1e0::/48
EOF
    chmod 600 "$candidate"
    sshd -t -f "$candidate"
    mv "$candidate" "$SSHD_CONFIG"
    if grep -q '^FIZLAB_SSH_HARDENING=' "$SERVER_HOME/config/fizlab.env"; then
        sed -i 's/^FIZLAB_SSH_HARDENING=.*/FIZLAB_SSH_HARDENING=enabled/' "$SERVER_HOME/config/fizlab.env"
    else
        printf '\nFIZLAB_SSH_HARDENING=enabled\n' >> "$SERVER_HOME/config/fizlab.env"
    fi
    log_success "Política SSH validada e preparada: $SSHD_CONFIG"
    log_warning "Reinicie os serviços somente após confirmar o acesso SSH por Tailscale de outro dispositivo."
}

case "$ACTION" in
    status) show_status ;;
    audit) audit ;;
    start-sshd) start_sshd ;;
    secure-ssh) secure_ssh "${2:-}" ;;
    *)
        printf 'Uso: %s {status|audit|secure-ssh --apply|start-sshd}\n' "$0" >&2
        exit 2
        ;;
esac
