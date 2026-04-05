# AI Toolbox Pre-command hook
# Usage: powershell -File .agent/scripts/hook-pre-command.ps1 "command to run"
# 
# This hook should be called by the AI Agent BEFORE executing a command.
# It checks if the command is "heavy" and recommends the 'rtk' wrapper.

param(
  [string]$Command
)

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

exit 0
