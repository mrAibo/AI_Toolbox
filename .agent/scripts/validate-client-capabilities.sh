#!/bin/bash
# validate-client-capabilities.sh — validates .agent/config/client-capabilities.json
# If the file doesn't exist, this check is skipped.

echo "[json-schema] Validating client-capabilities.json..."

CONFIG_FILE=".agent/config/client-capabilities.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[json-schema] SKIP — $CONFIG_FILE not found (optional)"
    exit 0
fi

# Validate JSON and check required structure
python3 -c "
import json, sys
with open('$CONFIG_FILE') as f:
    data = json.load(f)
if 'clients' not in data:
    print('  ERROR: missing required key: clients')
    sys.exit(1)
for name, client in data['clients'].items():
    if 'tier' not in client:
        print('  ERROR: client \"%s\" missing required key: tier' % name)
        sys.exit(1)
    if client['tier'] not in ('basic', 'standard', 'full'):
        print('  ERROR: client \"%s\" has invalid tier: %s' % (name, client['tier']))
        sys.exit(1)
print('  Structure valid: %d clients checked' % len(data['clients']))
" || { echo "FAIL: validation error"; exit 1; }

echo "[json-schema] OK — client-capabilities.json is valid"
