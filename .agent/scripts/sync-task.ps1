$ErrorActionPreference = "Stop"
# sync-task.ps1

Write-Host "[sync-task] Exporting current task tracker state to memory..."
if (Get-Command bd -ErrorAction SilentlyContinue) {
    bd list | Out-File -FilePath ".agent/memory/current-task.md" -Encoding utf8
    Write-Host "[sync-task] Task state exported to .agent/memory/current-task.md"
} else {
    # Fallback: Preserve existing manual entries or initialize if missing/empty
    if (-not (Test-Path ".agent/memory/current-task.md") -or (Get-Item ".agent/memory/current-task.md").Length -eq 0) {
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
        $TaskTemplate | Out-File -FilePath ".agent/memory/current-task.md" -Encoding utf8
        Write-Host "[sync-task] Initialized structured task in .agent/memory/current-task.md"
    } else {
        Write-Host "[sync-task] Beads (bd) not installed. Keeping existing manual task entries."
    }
}
