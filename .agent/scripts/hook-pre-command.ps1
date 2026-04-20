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

$HeavyCommandRegex = "^(python|python3|mvn|gradle|gradlew|pytest|npm run|pnpm run|yarn run|db2cli|hdbcli|sqlplus|ansible-playbook|javac|java -jar|cargo build|cargo test|cargo run|cargo check|go build|go test|go run|docker build|docker-compose build)"

if ($Command -match $HeavyCommandRegex -and $Command -notmatch '^rtk ') {
  Write-Host "[WARN]  AI Toolbox: Heavy command detected — consider using 'rtk' wrapper for token optimization."
  Write-Host "   Example: rtk $Command"
  exit 1
}

if ($Command -match '^(cat|less|tail|head) .+\.log' -and $Command -notmatch '^rtk ') {
  Write-Host "[WARN]  AI Toolbox: Large log file detected — consider 'rtk read <file>' for efficient reading."
  exit 1
}

# Track tool usage for session statistics
# PR1: Uses Named Mutex for serialization + temp file for atomic write to prevent JSON corruption.
# Named Update-ToolStat (not Update-ToolStat) to satisfy PSUseApprovedVerbs.
function Update-ToolStat {
  param([string]$Tool)
  # Initialize stats file if missing (outside lock — benign if two processes race here)
  if (-not (Test-Path $StatsFile)) {
    @{ "rtk" = 0; "beads" = 0; "mcp" = 0 } | ConvertTo-Json | Set-Content $StatsFile -Encoding utf8
  }
  $mutex = $null
  try {
    $mutex = [System.Threading.Mutex]::new($false, "AI_Toolbox_Stats")
    $mutex.WaitOne(5000) | Out-Null
    $stats = Get-Content $StatsFile -Raw -ErrorAction Stop | ConvertFrom-Json
    $statsHash = @{}
    $stats.PSObject.Properties | ForEach-Object { $statsHash[$_.Name] = $_.Value }
    if ($statsHash.ContainsKey($Tool)) { $statsHash[$Tool] += 1 } else { $statsHash[$Tool] = 1 }
    # Atomic write: write to temp file first, then rename — prevents truncated JSON on crash
    $TmpFile = "$StatsFile.tmp"
    $statsHash | ConvertTo-Json -Depth 3 | Set-Content $TmpFile -Encoding utf8
    Move-Item -Path $TmpFile -Destination $StatsFile -Force
  } catch {
    # Stats file corrupted, lock timeout, or Mutex not supported — ignore silently
  } finally {
    if ($mutex) {
      try { $mutex.ReleaseMutex() } catch {}
      $mutex.Dispose()
    }
  }
}

# Detect which tool is being used
if ($Command -match '^rtk ') { Update-ToolStat "rtk" }
if ($Command -match '^bd\s+') { Update-ToolStat "beads" }
if ($Command -match 'claude\s+mcp|context7|sequential-thinking') { Update-ToolStat "mcp" }

exit 0

