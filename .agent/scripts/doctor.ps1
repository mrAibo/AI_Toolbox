# doctor.ps1 - AI Toolbox Health Check for Windows
# Validates all components are present and functional.
# Exit 0 = all green, Exit 1 = warnings only, Exit 2 = errors found

$Errors = 0
$Warnings = 0

function Write-Pass { param($Msg) Write-Host "  [PASS] $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow; $script:Warnings++ }
function Write-Fail  { param($Msg) Write-Host "  [FAIL] $Msg" -ForegroundColor Red; $script:Errors++ }

# Find repo root
$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

Write-Host "[doctor] AI Toolbox Health Check"
Write-Host "================================"
Write-Host ""

# 1. Check .agent/ structure
Write-Host "Core Structure"
foreach ($dir in @(".agent/memory", ".agent/rules", ".agent/scripts", ".agent/workflows", ".agent/templates")) {
    if (Test-Path (Join-Path $RepoRoot $dir)) { Write-Pass "$dir exists" }
    else { Write-Fail "$dir missing" }
}

# 2. Check router files
Write-Host ""
Write-Host "Router Files"
foreach ($f in @("CLAUDE.md", "QWEN.md", "GEMINI.md", "CONVENTIONS.md", ".cursorrules", ".clinerules", ".windsurfrules", "SKILL.md")) {
    $path = Join-Path $RepoRoot $f
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        if ($content -match "\-\- Tier:") { Write-Pass "$f exists with tier badge" }
        else { Write-Warn "$f exists but missing tier badge" }
    }
}

# 3. Check hook scripts
Write-Host ""
Write-Host "Hook Scripts"
foreach ($script in @("bootstrap", "sync-task", "hook-pre-command", "hook-stop", "verify-commit", "commit-msg")) {
    foreach ($ext in @("sh", "ps1")) {
        $path = Join-Path $RepoRoot ".agent/scripts/${script}.${ext}"
        if (Test-Path $path) { Write-Pass "${script}.${ext} exists" }
        else { Write-Warn "${script}.${ext} missing" }
    }
}

# 4. Check Qwen hooks (if .qwen/settings.json exists)
$QwenSettings = Join-Path $RepoRoot ".qwen/settings.json"
if (-not (Test-Path $QwenSettings)) {
    $QwenSettings = Join-Path $env:USERPROFILE ".qwen/settings.json"
}
if (Test-Path $QwenSettings) {
    Write-Host ""
    Write-Host "Qwen Code Hooks"
    $Content = Get-Content $QwenSettings -Raw
    foreach ($hook in @("SessionStart", "PreToolUse", "PostToolUse", "Stop", "SessionEnd", "PreCompact")) {
        if ($Content -match $hook) { Write-Pass "$hook configured" }
        else { Write-Warn "$hook not configured" }
    }
}

# 5. Check tools
Write-Host ""
Write-Host "Tooling"
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    $ver = rtk --version 2>$null
    Write-Pass "rtk installed ($($ver -replace '\s',' '))"
} else {
    Write-Warn "rtk not installed - heavy commands will use more tokens"
}

if (Get-Command bd -ErrorAction SilentlyContinue) {
    $ver = bd version 2>$null
    Write-Pass "Beads installed ($($ver -replace '\s',' '))"
} else {
    Write-Warn "Beads not installed - task tracking will use manual mode"
}

# flock is a Unix-only tool; on Windows atomic rename is the fallback
if ($IsLinux -or $IsMacOS) {
    if (Get-Command flock -ErrorAction SilentlyContinue) {
        Write-Pass "flock available - concurrent hook writes are fully serialized"
    } else {
        Write-Warn "flock not available - concurrent hook writes use atomic rename only (weaker guarantee on parallel agents)"
    }
}

# 6. Check memory files
Write-Host ""
Write-Host "Memory Files"
foreach ($f in @("memory-index.md", "architecture-decisions.md", "integration-contracts.md", "session-handover.md", "runbook.md")) {
    $path = Join-Path $RepoRoot ".agent/memory/$f"
    if (Test-Path $path) { Write-Pass "$f exists" }
    else { Write-Warn "$f missing" }
}

# Check ADRs directory
$AdrsDir = Join-Path $RepoRoot ".agent/memory/adrs"
if (Test-Path $AdrsDir) {
    $adrCount = (Get-ChildItem $AdrsDir -Filter "*.md").Count
    Write-Pass "adrs/ directory exists ($adrCount ADRs)"
} else {
    Write-Warn "adrs/ directory missing"
}

# 7. Check .gitignore
Write-Host ""
Write-Host ".gitignore"
$Gitignore = Join-Path $RepoRoot ".gitignore"
if (Test-Path $Gitignore) {
    $Content = Get-Content $Gitignore
    foreach ($ignore in @(".beads/", ".agent/memory/session-handover.md", ".agent/memory/current-task.md")) {
        if ($Content -contains $ignore -or ($Content -join "`n") -match [regex]::Escape($ignore)) {
            Write-Pass "$ignore excluded"
        } else {
            Write-Fail "$ignore not excluded - may leak local state"
        }
    }
} else {
    Write-Fail ".gitignore missing"
}

# 8. Bootstrap parity
Write-Host ""
Write-Host "Bootstrap Parity"
foreach ($script in @("bootstrap", "sync-task", "hook-pre-command", "hook-stop", "verify-commit", "commit-msg")) {
    $hasSh = Test-Path (Join-Path $RepoRoot ".agent/scripts/${script}.sh")
    $hasPs1 = Test-Path (Join-Path $RepoRoot ".agent/scripts/${script}.ps1")
    if ($hasSh -and $hasPs1) { Write-Pass "${script}: both .sh and .ps1" }
    elseif ($hasSh) { Write-Warn "${script}: only .sh (no .ps1)" }
    elseif ($hasPs1) { Write-Warn "${script}: only .ps1 (no .sh)" }
    else { Write-Fail "${script}: missing both" }
}

# 9. Audit log
Write-Host ""
Write-Host "Audit Log"
$AuditLog = Join-Path $RepoRoot ".agent\memory\audit.log"
if (Test-Path $AuditLog) {
    $lines = (Get-Content $AuditLog -ErrorAction SilentlyContinue).Count
    Write-Pass "audit.log exists ($lines entries)"
    $gitignoreContent = Get-Content (Join-Path $RepoRoot ".gitignore") -Raw -ErrorAction SilentlyContinue
    if ($gitignoreContent -notmatch '\*\.log') {
        Write-Warn "audit.log may not be gitignored - verify *.log is in .gitignore"
    }
} else {
    Write-Pass "audit.log not yet created (written on first hook event)"
}

# Summary
Write-Host ""
Write-Host "================================"
if ($Errors -gt 0) {
    Write-Host "[FAIL] $Errors error(s) found - action required" -ForegroundColor Red
    exit 2
} elseif ($Warnings -gt 0) {
    Write-Host "[WARN] $Warnings warning(s) - toolbox functional but could be improved" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "[PASS] All checks passed - AI Toolbox healthy" -ForegroundColor Green
    exit 0
}
