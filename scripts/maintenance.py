#!/usr/bin/env python3

import argparse
import json
import operations

parser = argparse.ArgumentParser(description="Manutenção segura do FizLab")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--status", action="store_true")
args = parser.parse_args()
result = operations.maintenance_status() if args.status else operations.run_maintenance(args.dry_run)
print(json.dumps(result, ensure_ascii=False, indent=2))
