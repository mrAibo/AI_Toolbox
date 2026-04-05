# AI Toolbox Pre-command hook
# Usage: powershell -File .agent/scripts/hook-pre-command.ps1 "command to run"
#
# This hook should be called by the AI Agent BEFORE executing a command.
# It checks if the command is "heavy" and recommends the 'rtk' wrapper,
# and tracks tool usage for session statistics.

param(
  [string]$Command
)

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$StatsFile = "$RepoRoot\.agent\memory\.tool-stats.json"

if ([string]::IsNullOrWhiteSpace($Command)) {
  exit 0
}

$HeavyCommandRegex = "^(python|python3|mvn|gradle|gradlew|pytest|npm run|pnpm|yarn|db2cli|hdbcli|sqlplus|ansible-playbook|java |cargo|go |docker|docker-compose)"

if ($Command -match $HeavyCommandRegex -and $Command -notmatch '^rtk ') {
  Write-Host "🚨 AI Toolbox Heavy Command Detected!"
  Write-Host "Please use 'rtk' wrapper for heavy commands to optimize token usage."
  Write-Host "Example: rtk $Command"
  exit 1
}

if ($Command -match '^(cat|less|tail|head) .+\.log' -and $Command -notmatch '^rtk ') {
  Write-Host "🚨 AI Toolbox: Large log file detected!"
  Write-Host "Please use 'rtk read <file-path>' to read large logs efficiently."
  exit 1
}

# Track tool usage for session statistics
function Track-Tool {
  param([string]$Tool)
  if (Test-Path $StatsFile) {
    try {
      $stats = Get-Content $StatsFile -Raw | ConvertFrom-Json
      if ($stats.$Tool) { $stats.$Tool += 1 } else { $stats | Add-Member -NotePropertyName $Tool -NotePropertyValue 1 }
      $stats | ConvertTo-Json -Depth 3 | Set-Content $StatsFile -Encoding utf8
    } catch {
      # Stats file corrupted — ignore silently
    }
  }
}

# Detect which tool is being used
if ($Command -match 'rtk.*(test|build|lint)') { Track-Tool "rtk" }
if ($Command -match 'bd\s+(create|ready|list|close)') { Track-Tool "beads" }
if ($Command -match 'claude\s+mcp|context7|sequential-thinking') { Track-Tool "mcp" }

exit 0
