$ErrorActionPreference = "Stop"
# sync-task.ps1

$RepoRoot = "$(git rev-parse --show-toplevel)"
$TaskPath = "$RepoRoot/.agent/memory/current-task.md"

Write-Host "[sync-task] Exporting current task tracker state to memory..."
if (Get-Command bd -ErrorAction SilentlyContinue) {
    bd list | Out-File -FilePath $TaskPath -Encoding utf8
    Write-Host "[sync-task] Task state exported to $TaskPath"
} else {
    # Fallback: Preserve existing manual entries or initialize if missing/empty
    if (-not (Test-Path $TaskPath) -or (Get-Item $TaskPath).Length -eq 0) {
        $TaskTemplate = @"
# Task: Short title

- Status: ready
- Priority: medium
- Owner: AI agent
- Related files:
- Goal:
- Steps:
    - [ ] Step 1
- Verification:
- Notes:
"@
        $TaskTemplate | Out-File -FilePath $TaskPath -Encoding utf8
        Write-Host "[sync-task] Initialized structured task in $TaskPath"
    } else {
        Write-Host "[sync-task] Beads (bd) not installed. Keeping existing manual task entries."
    }
}
