#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIRECTORY="$(mktemp -d)"
MOCK_BIN="$TEST_DIRECTORY/bin"

cleanup() {
    rm -rf "$TEST_DIRECTORY"
}
trap cleanup EXIT

mkdir -p "$MOCK_BIN"

grep -Fq 'start_process fizlab_api.py yes bash "$PROJECT_DIR/services/api/start.sh"' \
    "$PROJECT_DIR/scripts/startup.sh"
grep -Fq 'start_process nginx yes bash "$PROJECT_DIR/services/nginx/start.sh"' \
    "$PROJECT_DIR/scripts/startup.sh"

cat > "$MOCK_BIN/pgrep" <<'EOF'
#!/usr/bin/env bash

match_mode="$1"
process_pattern="${@: -1}"

if [[ "$process_pattern" == *crond* ]]; then
    exit 0
fi

if [ "$match_mode" = "-x" ]; then
    exit 1
fi

count_file="$TEST_STATE/pgrep-count"
count=0

if [ -f "$count_file" ]; then
    count="$(cat "$count_file")"
fi

count=$((count + 1))
printf '%s\n' "$count" > "$count_file"

if [ "$count" -ge "$CONFIRM_AFTER" ]; then
    exit 0
fi

exit 1
EOF

for command_name in sshd crond sleep termux-wake-lock; do
    cat > "$MOCK_BIN/$command_name" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
done

chmod +x "$MOCK_BIN"/*

run_startup() {
    local server_home="$1"
    local confirm_after="$2"
    local attempts="$3"

    mkdir -p "$server_home" "$server_home/state"

    env \
        PATH="$MOCK_BIN:$PATH" \
        SERVER_HOME="$server_home" \
        TEST_STATE="$server_home/state" \
        CONFIRM_AFTER="$confirm_after" \
        FIZLAB_PROCESS_CHECK_ATTEMPTS="$attempts" \
        FIZLAB_PROCESS_CHECK_INTERVAL=0 \
        bash "$PROJECT_DIR/scripts/startup.sh"
}

SUCCESS_HOME="$TEST_DIRECTORY/success"
run_startup "$SUCCESS_HOME" 4 5
grep -q "sshd iniciado e confirmado (tentativa 3/5)." "$SUCCESS_HOME"/logs/system/startup.log
grep -q "serviços obrigatórios ativos" "$SUCCESS_HOME"/logs/system/startup.log

FAILURE_HOME="$TEST_DIRECTORY/failure"
if run_startup "$FAILURE_HOME" 99 3; then
    printf 'O startup deveria falhar quando o sshd não é confirmado.\n' >&2
    exit 1
fi

grep -q "sshd foi iniciado, mas não apareceu após 3 tentativas." "$FAILURE_HOME"/logs/system/startup.log
grep -q "Rotina de inicialização concluída com falhas." "$FAILURE_HOME"/logs/system/startup.log

printf 'startup_test: OK\n'
