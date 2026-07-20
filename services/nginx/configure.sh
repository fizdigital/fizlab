#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_DIR/lib/common.sh"
source "$PROJECT_DIR/lib/config.sh"

SERVER_HOME="$(get_server_home)"
TARGET="$SERVER_HOME/config/nginx.conf"
TEMPLATE="$PROJECT_DIR/templates/nginx/nginx.conf.template"

load_fizlab_config
mkdir -p "$SERVER_HOME/config" "$SERVER_HOME/run" "$SERVER_HOME/logs/nginx"

case "$FIZLAB_DASHBOARD_ACCESS" in
    lan)
        DASHBOARD_ACCESS_RULES=""
        ;;
    tailnet)
        DASHBOARD_ACCESS_RULES="        # Dashboard privado: localhost e Tailnet apenas.\n        allow 127.0.0.1;\n        allow ::1;"
        IFS=',' read -r -a tailscale_cidrs <<< "$FIZLAB_TAILSCALE_CIDRS"
        for cidr in "${tailscale_cidrs[@]}"; do
            cidr="${cidr//[[:space:]]/}"
            [ -n "$cidr" ] && DASHBOARD_ACCESS_RULES+="\n        allow $cidr;"
        done
        DASHBOARD_ACCESS_RULES+="\n        deny all;"
        ;;
    *)
        log_error "FIZLAB_DASHBOARD_ACCESS inválido: $FIZLAB_DASHBOARD_ACCESS (use lan ou tailnet)."
        exit 2
        ;;
esac

sed \
    -e "s|__SERVER_HOME__|$SERVER_HOME|g" \
    -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
    -e "s|__HTTP_HOST__|$FIZLAB_HTTP_HOST|g" \
    -e "s|__HTTP_PORT__|$FIZLAB_HTTP_PORT|g" \
    -e "s|__API_HOST__|$FIZLAB_API_HOST|g" \
    -e "s|__API_PORT__|$FIZLAB_API_PORT|g" \
    -e "s|__DASHBOARD_ACCESS_RULES__|$DASHBOARD_ACCESS_RULES|" \
    "$TEMPLATE" > "$TARGET.tmp"

mv "$TARGET.tmp" "$TARGET"
chmod 600 "$TARGET"

if command_exists nginx; then
    nginx -t -c "$TARGET" -p "$SERVER_HOME/"

    if pid_file_is_running "$SERVER_HOME/run/nginx.pid"; then
        nginx -c "$TARGET" -p "$SERVER_HOME/" -s reload
        log_success "Configuração recarregada no nginx ativo."
    fi
fi

log_success "Nginx configurado: $TARGET"
