#!/bin/bash
# validate-toolbox-config.sh — validates .ai-toolbox/config.json against
# .agent/schema/config.schema.json (Draft 2020-12).
#
# Falls back to a minimal structural check if the `jsonschema` Python module
# is unavailable, so legacy environments still get coverage.
#
# Exit codes: 0 = valid (or file absent), 1 = validation failure

set -u

CONFIG_FILE=".ai-toolbox/config.json"
SCHEMA_DIR=".agent/schema"
SCHEMA_FILE="${SCHEMA_DIR}/config.schema.json"

echo "[validate-config] Validating ${CONFIG_FILE}..."

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[validate-config] SKIP — ${CONFIG_FILE} not found"
    exit 0
fi

export CONFIG_FILE_PATH="$CONFIG_FILE"
export SCHEMA_FILE_PATH="$SCHEMA_FILE"
export SCHEMA_DIR_PATH="$SCHEMA_DIR"

# Prefer schema-based validation when both jsonschema and the schema file exist.
if [ -f "$SCHEMA_FILE" ] && python3 -c "import jsonschema" 2>/dev/null; then
    python3 - <<'PY' || { echo "[validate-config] FAIL — schema validation errors"; exit 1; }
import json, os, sys
from pathlib import Path
from jsonschema import Draft202012Validator

schema_dir = Path(os.environ['SCHEMA_DIR_PATH']).resolve()
schema_file = Path(os.environ['SCHEMA_FILE_PATH']).resolve()
config_file = Path(os.environ['CONFIG_FILE_PATH']).resolve()

with schema_file.open(encoding='utf-8') as f:
    schema = json.load(f)
with config_file.open(encoding='utf-8') as f:
    data = json.load(f)

# Resolve sibling schemas (client.schema.json) using the modern `referencing` API.
try:
    from referencing import Registry, Resource
    from referencing.jsonschema import DRAFT202012

    resources = []
    for sib in schema_dir.glob('*.schema.json'):
        with sib.open(encoding='utf-8') as f:
            body = json.load(f)
        resources.append((sib.name, Resource(contents=body, specification=DRAFT202012)))
        # Also register by absolute file URI so '$id'-less local refs work.
        resources.append((sib.as_uri(), Resource(contents=body, specification=DRAFT202012)))
    registry = Registry().with_resources(resources)
    validator = Draft202012Validator(schema, registry=registry)
except ImportError:
    # Older jsonschema without `referencing` — fall back to RefResolver.
    from jsonschema import RefResolver  # type: ignore
    base_uri = schema_dir.as_uri() + '/'
    resolver = RefResolver(base_uri=base_uri, referrer=schema)
    validator = Draft202012Validator(schema, resolver=resolver)

errors = sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path))
if errors:
    for err in errors:
        path = '/'.join(str(p) for p in err.absolute_path) or '<root>'
        print(f"  ERROR at {path}: {err.message}")
    print(f"  FAIL: {len(errors)} schema violation(s)")
    sys.exit(1)

primary = data.get('primary_client')
if primary is not None and primary not in data.get('clients', {}):
    print(f"  ERROR: primary_client {primary!r} not in clients")
    sys.exit(1)

n_clients = len(data.get('clients', {}))
print(f"  Schema valid: {n_clients} client(s), primary_client={primary!r}, "
      f"toolbox_version={data.get('toolbox_version', '<missing>')!r}")
PY
    echo "[validate-config] OK — ${CONFIG_FILE} matches ${SCHEMA_FILE}"
    exit 0
fi

# Fallback: minimal structural check (legacy behavior).
echo "[validate-config] WARN — jsonschema or schema file unavailable; using minimal fallback"

python3 - <<'PY' || { echo "[validate-config] FAIL — fallback validation errors"; exit 1; }
import json, os, sys

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
        print(f'  ERROR: primary_client {primary!r} not in clients')
        errors += 1

for name, client in data['clients'].items():
    if 'tier' not in client:
        print(f'  ERROR: client {name!r} missing required key: tier')
        errors += 1
    elif client['tier'] not in VALID_TIERS:
        print(f"  ERROR: client {name!r} tier {client['tier']!r} not valid")
        errors += 1

if errors:
    print(f'  FAIL: {errors} error(s) found')
    sys.exit(1)

print(f"  Structure valid (fallback): {len(data['clients'])} clients, "
      f"primary_client={data.get('primary_client')!r}")
PY

echo "[validate-config] OK — ${CONFIG_FILE} passes fallback validation"
exit 0
