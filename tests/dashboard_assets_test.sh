#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX="$PROJECT_DIR/dashboard/index.html"

test -s "$PROJECT_DIR/dashboard/assets/favicon.png"
test -s "$PROJECT_DIR/dashboard/assets/simbolo-fiz-digital.png"
grep -Fq 'href="/assets/favicon.png"' "$INDEX"
grep -Fq 'src="/assets/simbolo-fiz-digital.png"' "$INDEX"

printf 'dashboard_assets_test: OK\n'
