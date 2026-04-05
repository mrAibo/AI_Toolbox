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
  try { bd prime 2>$null } catch {}
}

Write-Host "[stop] remember to update:"
Write-Host "  - .agent/memory/architecture-decisions.md"
Write-Host "  - .agent/memory/integration-contracts.md"
Write-Host "  - .agent/memory/session-handover.md"

# Write session summary to session-handover.md if active-session.md exists
if (Test-Path "$RepoRoot/.agent/memory/active-session.md") {
  Write-Host ""
  Write-Host "[stop] 📊 Session summary available in .agent/memory/active-session.md"
  Write-Host "[stop] Writing final summary to session-handover.md..."
  if (Test-Path "$RepoRoot/.agent/memory/session-handover.md") {
    "`n## Session Summary — $(Get-Date -Format 'yyyy-MM-dd HH:mm UTC')" | Out-File -FilePath "$RepoRoot/.agent/memory/session-handover.md" -Append -Encoding utf8
    Get-Content "$RepoRoot/.agent/memory/active-session.md" -Raw | Out-File -FilePath "$RepoRoot/.agent/memory/session-handover.md" -Append -Encoding utf8
  }
}

Write-Host "[stop] repository left in recoverable state"
