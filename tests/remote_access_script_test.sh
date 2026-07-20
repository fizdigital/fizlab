#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
TEST_HOME="$TEST_DIRECTORY/home"
SERVER_HOME="$TEST_HOME/server"
PREFIX="$TEST_DIRECTORY/prefix"
MOCK_BIN="$TEST_DIRECTORY/bin"

cleanup() {
    rm -rf "$TEST_DIRECTORY"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME/.ssh" "$SERVER_HOME/config" "$PREFIX/etc/ssh" "$MOCK_BIN"
printf 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest fizlab-test\n' > "$TEST_HOME/.ssh/authorized_keys"
printf '# config do sshd de teste\n' > "$PREFIX/etc/ssh/sshd_config"
cp "$PROJECT_DIR/config/fizlab.env.example" "$SERVER_HOME/config/fizlab.env"

cat > "$MOCK_BIN/sshd" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SSHD_CALLS"
exit 0
EOF
chmod +x "$MOCK_BIN/sshd"

env \
    HOME="$TEST_HOME" \
    SERVER_HOME="$SERVER_HOME" \
    PREFIX="$PREFIX" \
    PATH="$MOCK_BIN:$PATH" \
    SSHD_CALLS="$TEST_DIRECTORY/sshd-calls.log" \
    bash "$PROJECT_DIR/scripts/remote-access.sh" secure-ssh --apply

CONFIG="$SERVER_HOME/config/sshd_config"
grep -Fq 'PasswordAuthentication no' "$CONFIG"
grep -Fq 'AllowUsers ' "$CONFIG"
grep -Fq 'FIZLAB_SSH_HARDENING=enabled' "$SERVER_HOME/config/fizlab.env"
grep -Fq -- '-t -f' "$TEST_DIRECTORY/sshd-calls.log"

env \
    HOME="$TEST_HOME" \
    SERVER_HOME="$SERVER_HOME" \
    PREFIX="$PREFIX" \
    PATH="$MOCK_BIN:$PATH" \
    SSHD_CALLS="$TEST_DIRECTORY/sshd-calls.log" \
    bash "$PROJECT_DIR/scripts/remote-access.sh" start-sshd

grep -Fq -- "-f $CONFIG" "$TEST_DIRECTORY/sshd-calls.log"
printf 'remote_access_script_test: OK\n'
