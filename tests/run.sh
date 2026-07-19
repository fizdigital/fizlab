#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

bash tests/startup_test.sh
bash tests/install_boot_test.sh
bash tests/nginx_config_test.sh
bash tests/dashboard_assets_test.sh
bash tests/api_service_test.sh
bash tests/install_test.sh
python tests/system_info_test.py
python tests/api_test.py
python tests/sqlite_test.py

printf 'Todos os testes do FizLab foram aprovados.\n'
