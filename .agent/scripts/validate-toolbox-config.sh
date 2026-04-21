#!/bin/bash
# validate-toolbox-config.sh — validates .ai-toolbox/config.json structure.
# Checks required top-level keys, tier values, and primary_client consistency.
#
# Exit codes: 0 = valid (or file absent), 1 = validation failure

set -u

CONFIG_FILE=".ai-toolbox/config.json"

echo "[validate-config] Validating ${CONFIG_FILE}..."

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[validate-config] SKIP — ${CONFIG_FILE} not found"
    exit 0
fi

export CONFIG_FILE_PATH="$CONFIG_FILE"

python3 -c "
import json, sys, os

VALID_TIERS = {'basic', 'standard', 'full'}

with open(os.environ['CONFIG_FILE_PATH'], encoding='utf-8') as f:
    data = json.load(f)

errors = 0

for key in ('_meta', 'clients', 'tiers'):
    if key not in data:
        print(f'  ERROR: missing required top-level key: {key!r}')
        errors += 1

if 'clients' not in data:
    sys.exit(1)

known_clients = set(data['clients'])

primary = data.get('primary_client')
if primary is not None:
    if not isinstance(primary, str):
        print('  ERROR: primary_client must be a string or null')
        errors += 1
    elif primary not in known_clients:
        print(f'  ERROR: primary_client {primary!r} not in clients (known: {sorted(known_clients)})')
        errors += 1

for name, client in data['clients'].items():
    if 'tier' not in client:
        print(f'  ERROR: client {name!r} missing required key: tier')
        errors += 1
    elif client['tier'] not in VALID_TIERS:
        print(f'  ERROR: client {name!r} tier {client[\"tier\"]!r} not valid (must be one of: {sorted(VALID_TIERS)})')
        errors += 1

if errors > 0:
    print(f'  FAIL: {errors} error(s) found')
    sys.exit(1)

print(f'  Structure valid: {len(data[\"clients\"])} clients, primary_client={data.get(\"primary_client\")!r}')
" || { echo "[validate-config] FAIL — validation errors found"; exit 1; }

echo "[validate-config] OK — .ai-toolbox/config.json is valid"
