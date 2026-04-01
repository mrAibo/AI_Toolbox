param(
  [string]$Command
)

if ([string]::IsNullOrWhiteSpace($Command)) {
  exit 0
}

if ($Command -match '^(python|python3|mvn|gradlew|pytest|npm run|pnpm|yarn|db2cli|hdbcli|sqlplus|ansible-playbook|java|cargo|go|docker|docker-compose)' -and $Command -notmatch '^rtk\s') {
  Write-Host "ERROR: heavy commands should be prefixed with rtk"
  exit 1
}

if ($Command -match '^(cat|less|tail|head).+\.log$' -and $Command -notmatch '^rtk\s') {
  Write-Host "ERROR: use rtk read <file> for large log files"
  exit 1
}

exit 0
