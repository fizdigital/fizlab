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
STARTUP_SCRIPT="$PROJECT_DIR/scripts/startup.sh"

if [ ! -x "$STARTUP_SCRIPT" ]; then
    log_error "Script de inicialização ausente ou sem permissão de execução: $STARTUP_SCRIPT"
    exit 1
fi

mkdir -p "$BOOT_DIRECTORY"

cat > "$BOOT_SCRIPT" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

export HOME="$HOME"
export PREFIX="$PREFIX"
export PATH="\$PREFIX/bin:\$PREFIX/bin/applets:\$HOME/.local/bin"

LOG_DIRECTORY="\$HOME/server/logs/system"
mkdir -p "\$LOG_DIRECTORY"
BOOT_LOG="\$LOG_DIRECTORY/termux-boot-\$(date +%Y-%m-%d_%H-%M-%S).log"

{
    echo "============================================"
    echo "Termux:Boot acionado"
    echo "Data: \$(date)"
    echo "HOME: \$HOME"
    echo "PREFIX: \$PREFIX"
    echo "PATH: \$PATH"
    echo "============================================"

    exec "$STARTUP_SCRIPT" --boot
} >> "\$BOOT_LOG" 2>&1
EOF

chmod 700 "$BOOT_SCRIPT"

log_success "Script do Termux:Boot instalado:"
log_info "$BOOT_SCRIPT"
log_warning "No Android, abra o Termux:Boot pelo menos uma vez e remova restrições de bateria do Termux e do Termux:Boot."
