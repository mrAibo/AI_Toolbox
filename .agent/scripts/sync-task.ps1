# sync-task.ps1
# Export current task state to a static file for the AI to read.
# Also detects task type and suggests the appropriate workflow.

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$TaskPath = "$RepoRoot\.agent\memory\current-task.md"
$ActiveSession = "$RepoRoot\.agent\memory\active-session.md"

Write-Host "[sync-task] Exporting current task tracker state to memory..."
if (Get-Command bd -ErrorAction SilentlyContinue) {
    bd list | Out-File -FilePath $TaskPath -Encoding utf8
    Write-Host "[sync-task] Task state exported to $TaskPath"

    # Detect task type from Beads output and suggest workflow
    $TaskOutput = Get-Content $TaskPath -First 5 -ErrorAction SilentlyContinue | Out-String
    if ($TaskOutput -match 'fix|bug|issue|error|crash') {
        Write-Host "[sync-task] 🐛 Bug fix detected — suggesting Bug-Fix Workflow"
    } elseif ($TaskOutput -match 'refactor|rewrite|migrate|rename') {
        Write-Host "[sync-task] 🔧 Refactor detected — suggesting Code Review Workflow"
    } elseif ($TaskOutput -match 'feature|build|create|add|implement') {
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
        # Remove old Current Step section (non-greedy: stops at next ## header) and append new one
        $Content = Get-Content $ActiveSession -Raw
        if ($Content -match '(?s)## Current Step.*?(?=\n## |\z)') {
            $Content = $Content -replace '(?s)## Current Step.*?(?=\n## |\z)', ''
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

    # Fix 5b: Scan import statements for framework-specific templates
    if (Select-String -Pattern '"next"' -Include '*.tsx','*.ts','*.js' -Path . -Exclude @('node_modules/*', '.git/*') -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: web-frameworks/nextjs"
    }
    if (Select-String -Pattern '"react"' -Include '*.tsx','*.ts','*.js' -Path . -Exclude @('node_modules/*', '.git/*') -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: frontend/react"
    }
    if (Select-String -Pattern '"express"' -Include '*.ts','*.js' -Path . -Exclude @('node_modules/*', '.git/*') -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: api-rest/express"
    }
    if (Select-String -Pattern '"@prisma/client"' -Include '*.ts','*.js' -Path . -Exclude @('node_modules/*', '.git/*') -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: database/prisma"
    }
    if (Select-String -Pattern '"jest"' -Include '*.json' -Path . -Exclude @('node_modules/*', '.git/*') -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: testing/jest"
    }
} elseif (Test-Path "Cargo.toml") {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/rust, devops-infrastructure"
    if (Select-String -Pattern 'tokio' -Path Cargo.toml -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: tokio async runtime"
    }
    if (Select-String -Pattern 'actix' -Path Cargo.toml -ErrorAction SilentlyContinue) {
        Write-Host "[sync-task] 💡 Detected: actix-web framework"
    }
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/python, ai-specialists"
    if ((Select-String -Pattern 'django' -Path pyproject.toml,requirements.txt -ErrorAction SilentlyContinue) -or
        (Select-String -Pattern 'fastapi' -Path pyproject.toml,requirements.txt -ErrorAction SilentlyContinue)) {
        Write-Host "[sync-task] 💡 Detected: web framework (django/fastapi)"
    }
} elseif (Test-Path "go.mod") {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/go, devops-infrastructure"
} elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
    Write-Host "[sync-task] 💡 Templates available: programming-languages/java, database"
}
