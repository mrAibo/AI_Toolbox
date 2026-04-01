$ErrorActionPreference = "Stop"
# sync-task.ps1

Write-Host "[sync-task] Exporting current task tracker state to memory..."
if (Get-Command bd -ErrorAction SilentlyContinue) {
    bd list | Out-File -FilePath ".agent/memory/current-task.md" -Encoding utf8
    Write-Host "[sync-task] Task state exported to .agent/memory/current-task.md"
} else {
    Write-Host "[sync-task] Beads (bd) is not installed. Cannot sync tasks."
    "No task tracker installed. Use manual instructions or issue trackers." | Out-File -FilePath ".agent/memory/current-task.md" -Encoding utf8
}
