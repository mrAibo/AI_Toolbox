# hook-pre-compact-ps1-qwen.ps1 - Qwen Code PreCompact hook
# Triggered before conversation compaction (context pruning).
# Injects important architecture context so it survives compaction.
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

    # Collect important context files
    $ADRFile = Join-Path $RepoRoot ".agent\memory\architecture-decisions.md"
    $ContractsFile = Join-Path $RepoRoot ".agent\memory\integration-contracts.md"
    $CurrentTask = Join-Path $RepoRoot ".agent\memory\current-task.md"
    $Runbook = Join-Path $RepoRoot ".agent\memory\runbook.md"

    $ContextParts = @()

    # Get current task summary (first 5 lines)
    if (Test-Path $CurrentTask) {
        $task = Get-Content $CurrentTask -First 5 -ErrorAction SilentlyContinue
        if ($task) {
            $ContextParts += "### Current Task:`n$($task -join "`n")"
        }
    }

    # Get latest ADR (last ADR entry)
    if (Test-Path $ADRFile) {
        $content = Get-Content $ADRFile -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $lastADR = $content -split '(?=### ADR-)' | Select-Object -Last 2
            if ($lastADR.Count -ge 1) {
                $ContextParts += "### Latest Architecture Decision:`n$($lastADR[-1].Trim())"
            }
        }
    }

    # Build injection context
    $InjectedContext = "## AI Toolbox Architecture Context (survives compaction)`n`n"
    $InjectedContext += $ContextParts -join "`n`n"
    $InjectedContext += "`n`n## Key Rules`n- Use rtk for heavy commands`n- Update .agent/memory/ files when state changes`n- Follow .agent/rules/*.md"

    $Response = @{
        decision = "allow"
        reason = "Architecture context injected"
        hookSpecificOutput = @{
            hookEventName = "PreCompact"
            additionalContext = $InjectedContext
        }
    }
    Write-Host ($Response | ConvertTo-Json -Depth 5 -Compress)
    exit 0

} catch {
    Write-Host '{"decision":"allow","reason":"Hook error, passing through"}'
    exit 0
}
