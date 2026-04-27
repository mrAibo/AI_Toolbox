# doctor.ps1 - AI Toolbox Health Check for Windows
# Validates all components are present and functional.
#
# Usage:
#   pwsh .agent/scripts/doctor.ps1 [-Json] [-Explain] [-Text]
#
# Output modes:
#   -Text    (default) Human-readable.
#   -Json    Machine-readable per .agent/schema/doctor-output.schema.json.
#   -Explain Append a "Fix:" line to every warn/error in text mode.
#
# Exit codes: 0 = all green, 1 = warnings only, 2 = errors found

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Text,
    [switch]$Explain
)

$Mode = if ($Json) { 'json' } else { 'text' }
$ErrorsCount = 0
$Warnings = 0
$Passed = 0
$Records = New-Object System.Collections.Generic.List[object]

function Write-Pass { param($Msg) if ($Mode -eq 'text') { Write-Host "  [PASS] $Msg" -ForegroundColor Green } }
function Write-Warn-Line { param($Msg, $Fix) if ($Mode -eq 'text') {
    Write-Host "  [WARN] $Msg" -ForegroundColor Yellow
    if ($Explain -and $Fix) { Write-Host "         Fix: $Fix" -ForegroundColor DarkYellow }
} }
function Write-Fail-Line { param($Msg, $Fix) if ($Mode -eq 'text') {
    Write-Host "  [FAIL] $Msg" -ForegroundColor Red
    if ($Explain -and $Fix) { Write-Host "         Fix: $Fix" -ForegroundColor DarkRed }
} }

function Add-Record {
    param(
        [string]$Category, [string]$Name, [string]$Status,
        [string]$Detail, [string]$Fix = '', [string]$ErrorCode = ''
    )
    $rec = [ordered]@{
        name     = $Name
        category = $Category
        status   = $Status
        detail   = $Detail
    }
    if ($Fix) { $rec['fix'] = $Fix }
    if ($ErrorCode) { $rec['error_code'] = $ErrorCode }
    $script:Records.Add([pscustomobject]$rec) | Out-Null
}

function Ok { param($Cat, $Name, $Detail)
    Add-Record $Cat $Name 'ok' $Detail
    $script:Passed++
    Write-Pass $Detail
}
function Warn { param($Cat, $Name, $Detail, $Fix='', $Code='')
    Add-Record $Cat $Name 'warning' $Detail $Fix $Code
    $script:Warnings++
    Write-Warn-Line $Detail $Fix
}
function Fail { param($Cat, $Name, $Detail, $Fix='', $Code='')
    Add-Record $Cat $Name 'error' $Detail $Fix $Code
    $script:ErrorsCount++
    Write-Fail-Line $Detail $Fix
}

function Section { param($Title) if ($Mode -eq 'text') { Write-Host ''; Write-Host $Title } }

function ConvertTo-CheckName {
    param([string]$s)
    $r = $s.ToLowerInvariant() -replace '/','.' -replace '^\.+',''
    $r -replace '\.+$',''
}

# Find repo root
$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

# Toolbox version
$ToolboxVersion = ''
$ConfigPath = Join-Path $RepoRoot '.ai-toolbox/config.json'
if (Test-Path $ConfigPath) {
    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        $ToolboxVersion = $cfg.toolbox_version
    } catch {}
}

if ($Mode -eq 'text') {
    Write-Host '[doctor] AI Toolbox Health Check'
    Write-Host '================================'
}

# 1. Core structure
Section 'Core Structure'
foreach ($dir in @('.agent/memory', '.agent/rules', '.agent/scripts', '.agent/workflows', '.agent/templates')) {
    $name = "structure.$(ConvertTo-CheckName $dir)"
    if (Test-Path (Join-Path $RepoRoot $dir)) {
        Ok 'structure' $name "$dir exists"
    } else {
        Fail 'structure' $name "$dir missing" 'Run: ai-toolbox setup' 'CONFIG_ERROR'
    }
}

# 2. Router files
Section 'Router Files'
foreach ($f in @('CLAUDE.md', 'QWEN.md', 'GEMINI.md', 'CONVENTIONS.md', '.cursorrules', '.clinerules', '.windsurfrules', 'SKILL.md')) {
    $path = Join-Path $RepoRoot $f
    if (-not (Test-Path $path)) { continue }
    $content = Get-Content $path -Raw
    $name = "router.$(ConvertTo-CheckName $f)"
    if ($content -match '\-\- Tier:') {
        if ($content -match 'cache-prefix:') {
            Ok 'router' $name "$f exists with tier badge and cache-prefix"
        } else {
            Warn 'router' $name "$f exists with tier badge but missing cache-prefix comment" 'Run: bash .agent/scripts/bootstrap.sh'
        }
    } else {
        Warn 'router' $name "$f exists but missing tier badge" 'Run: bash .agent/scripts/bootstrap.sh'
    }
}

# 3. Hook scripts
Section 'Hook Scripts'
foreach ($script in @('bootstrap', 'sync-task', 'hook-pre-command', 'hook-stop', 'verify-commit', 'commit-msg')) {
    foreach ($ext in @('sh', 'ps1')) {
        $name = "hook.$script.$ext"
        $path = Join-Path $RepoRoot ".agent/scripts/${script}.${ext}"
        if (Test-Path $path) {
            Ok 'hook' $name "${script}.${ext} exists"
        } else {
            Warn 'hook' $name "${script}.${ext} missing" 'Run: bash .agent/scripts/bootstrap.sh'
        }
    }
}

# 4. Qwen hooks
$QwenSettings = Join-Path $RepoRoot '.qwen/settings.json'
if (-not (Test-Path $QwenSettings)) { $QwenSettings = Join-Path $env:USERPROFILE '.qwen/settings.json' }
if ((Get-Command qwen -ErrorAction SilentlyContinue) -and (Test-Path $QwenSettings)) {
    Section 'Qwen Code Hooks'
    $Content = Get-Content $QwenSettings -Raw
    foreach ($hook in @('SessionStart', 'PreToolUse', 'PostToolUse', 'Stop', 'SessionEnd', 'PreCompact')) {
        $name = "qwen.hook.$($hook.ToLowerInvariant())"
        if ($Content -match $hook) {
            Ok 'qwen' $name "$hook configured"
        } else {
            Warn 'qwen' $name "$hook not configured" 'Run: bash .agent/scripts/bootstrap.sh'
        }
    }
}

# 5. Tooling
Section 'Tooling'
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    $ver = (rtk --version 2>$null) -replace "`n",' '
    Ok 'tooling' 'rtk' "rtk installed ($ver)"
} else {
    Warn 'tooling' 'rtk' 'rtk not installed - heavy commands will use more tokens' 'Run: cargo install --git https://github.com/rtk-ai/rtk --rev v0.35.0'
}

if (Get-Command bd -ErrorAction SilentlyContinue) {
    $ver = (bd version 2>$null) -replace "`n",' '
    Ok 'tooling' 'beads' "Beads installed ($ver)"
} else {
    Warn 'tooling' 'beads' 'Beads not installed - task tracking will use manual mode' 'Run: go install github.com/steveyegge/beads/cmd/bd@v0.63.3'
}

if (Get-Command shellcheck -ErrorAction SilentlyContinue) {
    Ok 'tooling' 'shellcheck' 'shellcheck installed'
} else {
    Warn 'tooling' 'shellcheck' 'shellcheck not installed - same warnings will hit you in CI' 'Windows: scoop install shellcheck (or choco install shellcheck) | Linux: apt install shellcheck | macOS: brew install shellcheck'
}

# PSScriptAnalyzer is the PowerShell counterpart. Required by CI for any
# script under .agent/scripts/*.ps1.
if (Get-Module -ListAvailable -Name PSScriptAnalyzer -ErrorAction SilentlyContinue) {
    Ok 'tooling' 'psscriptanalyzer' 'PSScriptAnalyzer installed (pwsh module)'
} else {
    Warn 'tooling' 'psscriptanalyzer' 'PSScriptAnalyzer not installed - same warnings will hit you in CI' "Run: Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"
}

# 6. Memory files
Section 'Memory Files'
foreach ($f in @('memory-index.md', 'architecture-decisions.md', 'integration-contracts.md', 'session-handover.md', 'runbook.md')) {
    $name = "memory.$(ConvertTo-CheckName $f)"
    $path = Join-Path $RepoRoot ".agent/memory/$f"
    if (Test-Path $path) {
        Ok 'memory' $name "$f exists"
    } else {
        Warn 'memory' $name "$f missing" 'Run: bash .agent/scripts/bootstrap.sh'
    }
}

$AdrsDir = Join-Path $RepoRoot '.agent/memory/adrs'
if (Test-Path $AdrsDir) {
    $adrCount = (Get-ChildItem $AdrsDir -Filter '*.md').Count
    Ok 'memory' 'memory.adrs' "adrs/ directory exists ($adrCount ADRs)"
} else {
    Warn 'memory' 'memory.adrs' 'adrs/ directory missing' 'Run: New-Item -ItemType Directory -Path .agent/memory/adrs'
}

# 7. Schema & Contracts (v1.5+)
Section 'Schema & Contracts'
$SchemaDir = Join-Path $RepoRoot '.agent/schema'
if (Test-Path $SchemaDir) {
    $schemaCount = (Get-ChildItem $SchemaDir -Filter '*.schema.json').Count
    Ok 'schema' 'schema.dir' ".agent/schema/ exists ($schemaCount schemas)"
} else {
    Warn 'schema' 'schema.dir' '.agent/schema/ missing' 'Run: ai-toolbox migrate' 'MIGRATION_VERSION_MISMATCH'
}
foreach ($f in @('hook-protocol.json', 'error-codes.json')) {
    $name = "contract.$(ConvertTo-CheckName $f)"
    $path = Join-Path $RepoRoot ".agent/contracts/$f"
    if (Test-Path $path) {
        Ok 'schema' $name "$f exists"
    } else {
        Warn 'schema' $name "$f missing" 'Run: ai-toolbox migrate'
    }
}

# 8. Toolbox version
Section 'Toolbox Version'
if ($ToolboxVersion) {
    Ok 'version' 'config.toolbox_version' "config.json toolbox_version=$ToolboxVersion"
} elseif (Test-Path $ConfigPath) {
    Warn 'version' 'config.toolbox_version' 'config.json present but missing toolbox_version field' 'Run: ai-toolbox migrate' 'CONFIG_MISSING_FIELD'
} else {
    Warn 'version' 'config.file' '.ai-toolbox/config.json absent' 'Run: bash .agent/scripts/bootstrap.sh'
}

# 9. .gitignore
Section '.gitignore'
$Gitignore = Join-Path $RepoRoot '.gitignore'
if (Test-Path $Gitignore) {
    $content = Get-Content $Gitignore -Raw
    foreach ($ignore in @('.beads/', '.agent/memory/session-handover.md', '.agent/memory/current-task.md')) {
        $name = "gitignore.$(ConvertTo-CheckName $ignore)"
        if ($content -match [regex]::Escape($ignore)) {
            Ok 'gitignore' $name "$ignore excluded"
        } else {
            Fail 'gitignore' $name "$ignore not excluded - may leak local state" "Add to .gitignore: $ignore"
        }
    }
} else {
    Fail 'gitignore' 'gitignore.file' '.gitignore missing' 'Run: bash .agent/scripts/bootstrap.sh'
}

# 10. Bootstrap parity
Section 'Bootstrap Parity'
foreach ($script in @('bootstrap', 'sync-task', 'hook-pre-command', 'hook-stop', 'verify-commit', 'commit-msg')) {
    $hasSh = Test-Path (Join-Path $RepoRoot ".agent/scripts/${script}.sh")
    $hasPs1 = Test-Path (Join-Path $RepoRoot ".agent/scripts/${script}.ps1")
    $name = "parity.$script"
    if ($hasSh -and $hasPs1) { Ok 'parity' $name "${script}: both .sh and .ps1" }
    elseif ($hasSh)  { Warn 'parity' $name "${script}: only .sh (no .ps1)"  'Add a .ps1 sibling' }
    elseif ($hasPs1) { Warn 'parity' $name "${script}: only .ps1 (no .sh)" 'Add a .sh sibling' }
    else             { Fail 'parity' $name "${script}: missing both" 'Run: bash .agent/scripts/bootstrap.sh' }
}

# 11. Audit log
Section 'Audit Log'
$AuditLog = Join-Path $RepoRoot '.agent/memory/audit.log'
if (Test-Path $AuditLog) {
    $lines = (Get-Content $AuditLog -ErrorAction SilentlyContinue).Count
    Ok 'audit' 'audit.log' "audit.log exists ($lines entries)"
} else {
    Ok 'audit' 'audit.log' 'audit.log not yet created (written on first hook event)'
}

# Final output
if ($Mode -eq 'json') {
    $status = if ($ErrorsCount -gt 0) { 'error' } elseif ($Warnings -gt 0) { 'warning' } else { 'ok' }
    $out = [ordered]@{
        version = '1.0'
        status = $status
        summary = [ordered]@{
            ok = $Passed
            warning = $Warnings
            error = $ErrorsCount
        }
        checks = $Records
    }
    if ($ToolboxVersion) { $out['toolbox_version'] = $ToolboxVersion }
    ($out | ConvertTo-Json -Depth 6) | Write-Output
} else {
    Write-Host ''
    Write-Host '================================'
    if ($ErrorsCount -gt 0) {
        Write-Host "[FAIL] $ErrorsCount error(s) found - action required" -ForegroundColor Red
    } elseif ($Warnings -gt 0) {
        Write-Host "[WARN] $Warnings warning(s) - toolbox functional but could be improved" -ForegroundColor Yellow
    } else {
        Write-Host '[PASS] All checks passed - AI Toolbox healthy' -ForegroundColor Green
    }
}

if ($ErrorsCount -gt 0) { exit 2 }
if ($Warnings -gt 0) { exit 1 }
exit 0
