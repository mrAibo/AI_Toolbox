# Append-only audit log helper -- dot-source into hook scripts.
# Usage: . "$PSScriptRoot\lib-audit.ps1"; Write-AuditEvent "event_name" "key=val pairs"
# Log:   .agent\memory\audit.log  (gitignored via *.log -- local only)
#
# Events are one line each:  TIMESTAMP | EVENT | CONTEXT
# Never put secrets or full command arguments in Context -- use short labels only.

function Write-AuditEvent {
  param(
    [string]$EventName = "unknown",
    [string]$Context   = ""
  )
  $repo = git rev-parse --show-toplevel 2>$null
  if (-not $repo) { $repo = (Get-Location).Path }
  $log = Join-Path $repo ".agent\memory\audit.log"
  $ts  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  try {
    Add-Content -Path $log -Value "$ts | $EventName | $Context" -Encoding utf8 -ErrorAction Stop
  } catch {}
}
