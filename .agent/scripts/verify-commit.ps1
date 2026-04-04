# AI Toolbox Commit Verification (POWERSHELL)
# Validates that primary architectural intent is preserved.

$RepoRoot = git rev-parse --show-toplevel
$ADRFile = "$RepoRoot/.agent/memory/architecture-decisions.md"

if (Test-Path $ADRFile) {
    $Content = Get-Content $ADRFile -ErrorAction SilentlyContinue
    
    # Check if file contains at least one ADR entry
    if ($null -eq $Content -or $Content.Count -eq 0 -or -not ($Content -match "^### ADR-")) {
        Write-Host "🚨 AI Toolbox Block: no architecture decisions found in $ADRFile!"
        Write-Host "Please document your architectural decisions (use the '### ADR-XXXX' format) before committing to ensure project durability."
        exit 1
    }
}

exit 0
