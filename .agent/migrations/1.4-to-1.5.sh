#!/bin/bash
# Migration: AI Toolbox 1.4 → 1.5
#
# Changes introduced in 1.5:
#   - Required field `toolbox_version` in .ai-toolbox/config.json.
#   - Optional `$schema` reference in .ai-toolbox/config.json.
#   - Optional `context` budget block (max_files / max_lines_per_file / max_total_lines / priorities).
#   - New directory .agent/schema/ with seven JSON Schema files.
#   - New directory .agent/contracts/ with hook-protocol and error-codes.
#
# Idempotent: re-running on already-migrated config is a no-op.
#
# Inputs:  $1 = repo root (defaults to git rev-parse --show-toplevel || pwd)
# Output:  prints one '[migrate]' line per change. Exits 0 on success.

set -u

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CONFIG_FILE="${REPO_ROOT}/.ai-toolbox/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[migrate 1.4-to-1.5] SKIP — ${CONFIG_FILE} not present"
    exit 0
fi

PYTHONIOENCODING=utf-8 CONFIG_PATH="$CONFIG_FILE" python3 - <<'PY' || { echo "[migrate 1.4-to-1.5] FAIL — could not update config"; exit 40; }
import json, os, sys
from pathlib import Path

config_path = Path(os.environ['CONFIG_PATH'])
with config_path.open(encoding='utf-8') as f:
    data = json.load(f)

changed = False
report = []

# 1. $schema reference
if data.get('$schema') != '../.agent/schema/config.schema.json':
    data['$schema'] = '../.agent/schema/config.schema.json'
    report.append('added $schema reference')
    changed = True

# 2. toolbox_version
if data.get('toolbox_version') != '1.5':
    data['toolbox_version'] = '1.5'
    report.append('set toolbox_version=1.5')
    changed = True

# 3. context budgets — only fill in if absent (non-destructive).
context_defaults = {
    'max_files': 5,
    'max_lines_per_file': 200,
    'max_total_lines': 800,
    'priorities': [
        'changed', 'test', 'imports', 'same-dir',
        'memory', 'plugin-hints', 'recently-modified'
    ],
}
ctx = data.get('context') or {}
for k, v in context_defaults.items():
    if k not in ctx:
        ctx[k] = v
        report.append(f'context.{k} = {v}')
        changed = True
if ctx and 'context' not in data:
    data['context'] = ctx
    changed = True
elif ctx:
    data['context'] = ctx

if changed:
    # Reorder so $schema and toolbox_version appear first (cosmetic but stable).
    head = {}
    if '$schema' in data:        head['$schema']         = data.pop('$schema')
    if 'toolbox_version' in data: head['toolbox_version'] = data.pop('toolbox_version')
    head.update(data)
    data = head

    with config_path.open('w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
        f.write('\n')

if report:
    for line in report:
        print(f'[migrate 1.4-to-1.5]   {line}')
else:
    print('[migrate 1.4-to-1.5] config already at 1.5 — no-op')
PY

# Ensure schema and contracts directories exist (created by bootstrap normally).
for d in .agent/schema .agent/contracts .agent/migrations; do
    if [ ! -d "$REPO_ROOT/$d" ]; then
        mkdir -p "$REPO_ROOT/$d"
        echo "[migrate 1.4-to-1.5]   created $d/"
    fi
done

echo "[migrate 1.4-to-1.5] OK"
exit 0
