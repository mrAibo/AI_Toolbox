# AI Toolbox Commit Verification (POWERSHELL)
# Validates that primary architectural intent is preserved.

$RepoRoot = git rev-parse --show-toplevel
$ADRFile = "$RepoRoot/.agent/memory/architecture-decisions.md"

if (Test-Path $ADRFile) {
    $Content = Get-Content $ADRFile -ErrorAction SilentlyContinue
    
    # Check if file is empty OR only contains the default header
    if ($null -eq $Content -or $Content.Count -eq 0 -or ($Content.Count -le 2 -and $Content -match "^# Architecture Decision Records")) {
        Write-Host "🚨 AI Toolbox Block: architecture-decisions.md is empty or only contains a header!"
        Write-Host "Please document your architectural decisions before committing to ensure project durability."
        exit 1
    }
}

exit 0
