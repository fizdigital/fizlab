#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
MOCK_BIN="$TEST_DIRECTORY/bin"
TEST_HOME="$TEST_DIRECTORY/home"
BOOT_DIRECTORY="$TEST_HOME/.termux/boot"

cleanup() {
    rm -rf "$TEST_DIRECTORY"
}
trap cleanup EXIT

mkdir -p "$MOCK_BIN" "$BOOT_DIRECTORY"

cat > "$MOCK_BIN/termux-info" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$MOCK_BIN/termux-info"

cat > "$BOOT_DIRECTORY/00-fizlab-start.backup" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$BOOT_DIRECTORY/00-fizlab-start.backup"

OUTPUT="$(
    env \
        HOME="$TEST_HOME" \
        PREFIX="/data/data/com.termux/files/usr" \
        PATH="$MOCK_BIN:$PATH" \
        bash "$PROJECT_DIR/scripts/install-boot.sh"
)"

BOOT_SCRIPT="$BOOT_DIRECTORY/00-fizlab-start"

test -x "$BOOT_SCRIPT"
grep -Fq 'exec "$PREFIX/bin/bash" "' "$BOOT_SCRIPT"
grep -Fq "Entrada adicional executável no Termux:Boot: $BOOT_DIRECTORY/00-fizlab-start.backup" <<< "$OUTPUT"

printf 'install_boot_test: OK\n'
