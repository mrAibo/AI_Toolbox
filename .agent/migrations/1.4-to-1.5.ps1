# Migration: AI Toolbox 1.4 -> 1.5 (PowerShell parity)
# See sibling 1.4-to-1.5.sh for protocol details.

[CmdletBinding()]
param(
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
}

$ConfigFile = Join-Path $RepoRoot '.ai-toolbox/config.json'
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[migrate 1.4-to-1.5] SKIP - $ConfigFile not present"
    exit 0
}

# Use Python for JSON manipulation to keep parity with the bash version's behavior.
$python = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
if (-not $python) {
    Write-Host '[migrate 1.4-to-1.5] FAIL - python not available' -ForegroundColor Red
    exit 40
}

$env:CONFIG_PATH = $ConfigFile
$env:PYTHONIOENCODING = 'utf-8'

$pyScript = @'
import json, os
from pathlib import Path

config_path = Path(os.environ['CONFIG_PATH'])
with config_path.open(encoding='utf-8') as f:
    data = json.load(f)

changed = False
report = []

if data.get('$schema') != '../.agent/schema/config.schema.json':
    data['$schema'] = '../.agent/schema/config.schema.json'
    report.append('added $schema reference')
    changed = True

if data.get('toolbox_version') != '1.5':
    data['toolbox_version'] = '1.5'
    report.append('set toolbox_version=1.5')
    changed = True

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
if ctx:
    data['context'] = ctx

if changed:
    head = {}
    if '$schema' in data:        head['$schema']         = data.pop('$schema')
    if 'toolbox_version' in data: head['toolbox_version'] = data.pop('toolbox_version')
    head.update(data)
    data = head
    with config_path.open('w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

if report:
    for line in report:
        print(f'[migrate 1.4-to-1.5]   {line}')
else:
    print('[migrate 1.4-to-1.5] config already at 1.5 - no-op')
'@

$pyScript | & $python.Source -
if ($LASTEXITCODE -ne 0) {
    Write-Host '[migrate 1.4-to-1.5] FAIL - could not update config' -ForegroundColor Red
    exit 40
}

# Ensure schema/contracts/migrations dirs exist.
foreach ($d in @('.agent/schema', '.agent/contracts', '.agent/migrations')) {
    $dir = Join-Path $RepoRoot $d
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[migrate 1.4-to-1.5]   created $d/"
    }
}

Write-Host '[migrate 1.4-to-1.5] OK'
exit 0
