# hook-session-end-ps1-qwen.ps1 - Qwen Code SessionEnd hook
# Triggered when the session is ending.
# Runs the existing hook-stop.ps1 for full memory consolidation.
# Also triggers bd prime if available.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

try {
    $InputData = $null
    $RawInput = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($RawInput)) {
        try { $InputData = $RawInput | ConvertFrom-Json } catch {
            Write-Host '{"decision":"allow","reason":"Non-JSON input, passing through"}'
            exit 0
        }
    }

    # Find repo root
    $RepoRoot = Get-Location
    $maxDepth = 5
    $depth = 0
    while ($depth -lt $maxDepth) {
        if (Test-Path (Join-Path $RepoRoot ".agent")) { break }
        $parent = Split-Path $RepoRoot -Parent
        if ($parent -eq $RepoRoot) { break }
        $RepoRoot = $parent
        $depth++
    }

    # Run the existing hook-stop.ps1 (it handles sync-task + tool stats + handover)
    $StopHook = Join-Path $RepoRoot ".agent\scripts\hook-stop.ps1"
    if (Test-Path $StopHook) {
        try {
            $Shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
            & $Shell -ExecutionPolicy Bypass -File $StopHook 2>$null | Out-Null
        } catch {}
    }

    # Try bd prime if available (refreshes task context)
    $BdPath = Get-Command bd.exe -ErrorAction SilentlyContinue
    if ($BdPath) {
        try { & $BdPath.Source prime 2>$null } catch {}
    }

    $Response = @{
        decision = "allow"
        reason = "Session end consolidation complete"
        hookSpecificOutput = @{
            hookEventName = "SessionEnd"
            additionalContext = "AI Toolbox: Session memory consolidated. Next session will recover full context from .agent/memory/ files."
        }
    }
    Write-Host ($Response | ConvertTo-Json -Depth 5 -Compress)
    exit 0

} catch {
    Write-Host '{"decision":"allow","reason":"Hook error, passing through"}'
    exit 0
}
