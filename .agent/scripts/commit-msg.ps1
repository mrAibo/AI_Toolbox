# AI Toolbox Commit-Message Verification (PowerShell)
# Called by Git as commit-msg hook with $args[0] = commit message file path.
# Checks that code changes include test updates, unless tdd-skip is in the message.

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

$CommitMsgFile = $args[0]
$CommitMsg = ""
if ($CommitMsgFile -and (Test-Path $CommitMsgFile)) {
    $CommitMsg = Get-Content $CommitMsgFile -Raw 2>$null
}

$Errors = 0

# Check if staged code changes have corresponding test updates
$StagedCode = git diff --cached --name-only 2>$null | Where-Object { $_ -match '\.(ts|tsx|js|jsx|py|rs|go|java|kt|rb)$' }
$StagedTests = git diff --cached --name-only 2>$null | Where-Object { $_ -match '(?i)(^|/)(test|tests|spec|specs)(/|$)|(_test\.|\.test\.|\.spec\.)' }

if ($StagedCode -and -not $StagedTests) {
    if ($CommitMsg -match '(?i)tdd-skip') {
        Write-Host "AI Toolbox: TDD skip requested via commit message."
    } else {
        Write-Host "[WARN] AI Toolbox: Code changes without test updates."
        Write-Host "   Per .agent/rules/tdd-rules.md, all code changes must have tests."
        Write-Host "   Staged code files:"
        $StagedCode | ForEach-Object { Write-Host "     $_" }
        Write-Host ""
        Write-Host "   To fix: Stage corresponding test files and commit again."
        Write-Host "   To skip (emergency only): Include 'tdd-skip' in the commit message."
        $Errors++
    }
}

if ($Errors -gt 0) {
    Write-Host ""
    Write-Host "[FAIL] AI Toolbox: Commit blocked. Fix the issue above and try again."
    exit 1
}

exit 0
