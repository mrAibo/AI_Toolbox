$ErrorActionPreference = "Stop"
# sync-task.ps1

Write-Host "[sync-task] Exporting current task tracker state to memory..."
if (Get-Command bd -ErrorAction SilentlyContinue) {
    bd list | Out-File -FilePath ".agent/memory/current-task.md" -Encoding utf8
    Write-Host "[sync-task] Task state exported to .agent/memory/current-task.md"
} else {
    # Fallback: Preserve existing manual entries or initialize if missing/empty
    if (-not (Test-Path ".agent/memory/current-task.md") -or (Get-Item ".agent/memory/current-task.md").Length -eq 0) {
        "# Tasks (Manual)`r`n`r`n- [ ] Define your first task here..." | Out-File -FilePath ".agent/memory/current-task.md" -Encoding utf8
        Write-Host "[sync-task] Initialized manual task file in .agent/memory/current-task.md"
    } else {
        Write-Host "[sync-task] Beads (bd) not installed. Keeping existing manual task entries."
    }
}
