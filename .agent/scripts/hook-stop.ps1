# hook-stop.ps1 - Session end consolidation
# Runs after every command (post-command hook).
# No $ErrorActionPreference = "Stop" - must be resilient to individual failures.

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

# 1. Sync task state (resilient - continue even if it fails)
if (Test-Path "$RepoRoot/.agent/scripts/sync-task.ps1") {
    try { & "$RepoRoot/.agent/scripts/sync-task.ps1" } catch {}
}

# 2. Auto-refresh Beads task context
$BdPath = Get-Command bd.exe -ErrorAction SilentlyContinue
if ($BdPath) {
    try { & $BdPath.Source prime 2>$null } catch {}
}

# 3. Display tool usage stats if available
$StatsFile = "$RepoRoot/.agent/memory/.tool-stats.json"
if (Test-Path $StatsFile) {
    try {
        $stats = Get-Content $StatsFile -Raw | ConvertFrom-Json
        $hasStats = $false
        $stats.PSObject.Properties | ForEach-Object {
            if ($_.Value -gt 0) { $hasStats = $true }
        }
        if ($hasStats) {
            Write-Host "[stop] Tool usage this session:"
            $stats.PSObject.Properties | Sort-Object { $_.Value } -Descending | ForEach-Object {
                if ($_.Value -gt 0) { Write-Host "  -> $($_.Name): $($_.Value) uses" }
            }
        }
    } catch {}
}

# 4. Append session summary to handover (capped to last 10 entries)
# PR1: Named Mutex serializes concurrent hook-stop invocations; atomic temp-file write
# prevents readers from seeing a truncated handover file during the cap operation.
$HandoverFile = "$RepoRoot/.agent/memory/session-handover.md"
$ActiveFile = "$RepoRoot/.agent/memory/active-session.md"
if (Test-Path $ActiveFile) {
    # Check if active-session has real content (not just template placeholders)
    $ActiveContent = Get-Content $ActiveFile -Raw
    if ($ActiveContent -notmatch '\[Date\]' -and $ActiveContent -notmatch 'Awaiting task analysis') {
        if (Test-Path $HandoverFile) {
            $mutex = [System.Threading.Mutex]::new($false, "AI_Toolbox_Handover")
            try {
                $mutex.WaitOne(5000) | Out-Null

                # Cap handover to last 10 session summaries to prevent unbounded growth
                $HandoverContent = Get-Content $HandoverFile -Raw
                $Sections = [regex]::Matches($HandoverContent, '(?m)^## Session Summary')
                if ($Sections.Count -ge 10) {
                    # Keep only the last 9 summaries + header content before first summary
                    $FirstSummaryPos = $Sections[0].Index
                    $RecentContent = $HandoverContent.Substring($FirstSummaryPos)
                    $RecentSections = $RecentContent -split '(?m)^## Session Summary' |
                        Where-Object { $_.Trim() } | Select-Object -Last 9
                    $HeaderContent = $HandoverContent.Substring(0, $FirstSummaryPos)
                    $HandoverContent = $HeaderContent + ($RecentSections |
                        ForEach-Object { "## Session Summary$_" }) -join "`n"
                    # Atomic write: temp file then rename — no truncated file visible to readers
                    $TmpFile = "$HandoverFile.tmp"
                    $HandoverContent | Set-Content $TmpFile -Encoding utf8
                    Move-Item -Path $TmpFile -Destination $HandoverFile -Force
                }

                "`n## Session Summary - $(Get-Date -Format 'yyyy-MM-dd HH:mm UTC')" |
                    Out-File -FilePath $HandoverFile -Append -Encoding utf8
                $ActiveContent | Out-File -FilePath $HandoverFile -Append -Encoding utf8
            } finally {
                try { $mutex.ReleaseMutex() } catch {}
                $mutex.Dispose()
            }
        }
    }
}

Write-Host "[stop] repository left in recoverable state"
