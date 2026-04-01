$ErrorActionPreference = "Stop"

Write-Host "[stop] consolidating session memory..."

if (Test-Path ".agent/memory/session-handover.md") {
  Write-Host "[stop] session handover file exists"
}

Write-Host "[stop] remember to update:"
Write-Host "  - .agent/memory/architecture-decisions.md"
Write-Host "  - .agent/memory/integration-contracts.md"
Write-Host "  - .agent/memory/session-handover.md"

Write-Host "[stop] repository left in recoverable state"
