$ErrorActionPreference = "Stop"
# sync-task.ps1
# Export current task state to a static file for the AI to read.
# Also detects task type and suggests the appropriate workflow.

$RepoRoot = "$(git rev-parse --show-toplevel)"
$TaskPath = "$RepoRoot/.agent/memory/current-task.md"
$ActiveSession = "$RepoRoot/.agent/memory/active-session.md"

Write-Host "[sync-task] Exporting current task tracker state to memory..."
if (Get-Command bd -ErrorAction SilentlyContinue) {
    bd list | Out-File -FilePath $TaskPath -Encoding utf8
    Write-Host "[sync-task] Task state exported to $TaskPath"

    # Detect task type from Beads output and suggest workflow
    $TaskTitle = Get-Content $TaskPath -First 1 -ErrorAction SilentlyContinue
    if ($TaskTitle -match 'fix|bug|issue|error|crash') {
        Write-Host "[sync-task] 🐛 Bug fix detected — suggesting Bug-Fix Workflow"
    } elseif ($TaskTitle -match 'refactor|rewrite|migrate|rename') {
        Write-Host "[sync-task] 🔧 Refactor detected — suggesting Code Review Workflow"
    } elseif ($TaskTitle -match 'feature|build|create|add|implement') {
        Write-Host "[sync-task] 🚀 Feature detected — suggesting Unified Workflow (9 steps)"
    }
} else {
    # Fallback: Preserve existing manual entries or initialize if missing/empty
    if (-not (Test-Path $TaskPath) -or (Get-Item $TaskPath).Length -eq 0) {
        $TaskTemplate = @"
# Task: Short title

- Status: ready
- Priority: medium
- Owner: AI agent
- Related files:
- Goal:
- Steps:
    - [ ] Step 1
- Verification:
- Notes:
"@
        $TaskTemplate | Out-File -FilePath $TaskPath -Encoding utf8
        Write-Host "[sync-task] Initialized structured task in $TaskPath"
    } else {
        Write-Host "[sync-task] Beads (bd) not installed. Keeping existing manual task entries."
    }
}

# Update active-session.md with current task info if it exists
if (Test-Path $ActiveSession) {
    $TaskInfo = Get-Content $TaskPath -First 3 -ErrorAction SilentlyContinue
    if ($TaskInfo) {
        # Remove old Current Step section and append new one
        $Content = Get-Content $ActiveSession -Raw
        if ($Content -match '(?s)## Current Step.*') {
            $Content = $Content -replace '(?s)## Current Step.*', ''
        }
        $Content += "`n## Current Step`n- **Workflow:** Awaiting task analysis`n- **Task:** $($TaskInfo -join "`n")`n"
        $Content | Out-File -FilePath $ActiveSession -Encoding utf8
    }
}

# Fix 4: Count ready tasks and suggest Multi-Agent if >= 3
if (Get-Command bd -ErrorAction SilentlyContinue) {
    try {
        $ReadyOutput = bd ready 2>$null
        if ($ReadyOutput) {
            $ReadyCount = ($ReadyOutput | Measure-Object -Line).Lines
            if ($ReadyCount -ge 3) {
                Write-Host "[sync-task] 💡 $ReadyCount tasks ready — consider Multi-Agent Workflow"
            }
        }
    } catch { /* Ignore errors */ }
}

# Fix 5: Suggest specialist templates based on detected stack
if (Test-Path "package.json") {
    Write-Host "[sync-task] 💡 Templates available: api-rest, database, ui-analysis"
} elseif (Test-Path "Cargo.toml") {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/rust, devops-infrastructure"
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/python, ai-specialists"
} elseif (Test-Path "go.mod") {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/go, devops-infrastructure"
} elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/java, database"
}
