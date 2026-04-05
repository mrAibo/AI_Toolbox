$ErrorActionPreference = "Stop"

Write-Host "[stop] consolidating session memory..."

$RepoRoot = "$(git rev-parse --show-toplevel)"

if (Test-Path "$RepoRoot/.agent/memory/session-handover.md") {
  Write-Host "[stop] session handover file exists"
}

if (Test-Path "$RepoRoot/.agent/scripts/sync-task.ps1") {
  & "$RepoRoot/.agent/scripts/sync-task.ps1"
}

# Auto-refresh Beads task context (like Template Bridge PreCompact hook)
if (Get-Command bd -ErrorAction SilentlyContinue) {
  bd prime 2>$null
}

Write-Host "[stop] remember to update:"
Write-Host "  - .agent/memory/architecture-decisions.md"
Write-Host "  - .agent/memory/integration-contracts.md"
Write-Host "  - .agent/memory/session-handover.md"

Write-Host "[stop] repository left in recoverable state"
