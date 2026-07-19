#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

source "$PROJECT_DIR/lib/common.sh"

PLATFORM="$(detect_platform)"

if [ "$PLATFORM" != "termux" ]; then
    log_warning "O Termux:Boot só é aplicável ao perfil Termux."
    exit 0
fi

BOOT_DIRECTORY="$HOME/.termux/boot"
BOOT_SCRIPT="$BOOT_DIRECTORY/00-fizlab-start"

mkdir -p "$BOOT_DIRECTORY"

cat > "$BOOT_SCRIPT" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

export HOME="$HOME"
export PREFIX="$PREFIX"
export PATH="\$HOME/.local/bin:\$PREFIX/bin:\$PREFIX/bin/applets"

LOG_DIRECTORY="\$HOME/server/logs/system"
mkdir -p "\$LOG_DIRECTORY"

BOOT_LOG="\$LOG_DIRECTORY/termux-boot-\$(date +%Y-%m-%d_%H-%M-%S).log"

{
    echo "============================================"
    echo "Termux:Boot acionado"
    echo "Data: \$(date)"
    echo "PATH: \$PATH"
    echo "============================================"

    sleep 20

    "$PROJECT_DIR/scripts/startup.sh"
} >> "\$BOOT_LOG" 2>&1
EOF

chmod +x "$BOOT_SCRIPT"

log_success "Script do Termux:Boot instalado:"
log_info "$BOOT_SCRIPT"
log_warning "Confirme que o aplicativo Termux:Boot foi instalado e aberto uma vez."
