# hook-post-tool-ps1-qwen.ps1 - Qwen Code PostToolUse hook
# Triggered after write/edit tool execution.
# Scans written files for secrets, credentials, or sensitive patterns.
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

    $ToolName = ""
    $FilePath = ""
    if ($InputData) {
        $ToolName = $InputData.tool_name 2>$null
        $ToolInput = $InputData.tool_input 2>$null
        if ($ToolInput -and $ToolInput.GetType().Name -eq "PSCustomObject") {
            $FilePath = $ToolInput.file_path 2>$null
        }
    }

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        Write-Host '{"decision":"allow","reason":"No file path detected"}'
        exit 0
    }

    # Path traversal guard: resolve and verify file is within repo root
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
    $ResolvedFile = [System.IO.Path]::GetFullPath($FilePath)
    $ResolvedRoot = [System.IO.Path]::GetFullPath($RepoRoot)
    if (-not $ResolvedFile.StartsWith($ResolvedRoot)) {
        Write-Host '{"decision":"allow","reason":"File outside repository"}'
        exit 0
    }

    # Security patterns to scan for in written files
    $SecretPatterns = @(
        '(?i)(password|passwd|pwd)\s*[=:]\s*["''][^"'']+["'']',
        '(?i)(api[_-]?key|apikey)\s*[=:]\s*["''][^"'']+["'']',
        '(?i)(secret|token|auth[_-]?key)\s*[=:]\s*["''][^"'']+["'']',
        '(?i)(aws[_-]?access|aws[_-]?secret)\s*[=:]\s*["''][^"'']+["'']',
        '(?i)BEGIN\s+(RSA|DSA|EC|OPENSSH)\s+PRIVATE\s+KEY',
        '(?i)(connection[_-]?string|database[_-]?url)\s*[=:]\s*["''][^"'']+["'']'
    )

    $Findings = @()
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if ($Content) {
            foreach ($pattern in $SecretPatterns) {
                $matches = [regex]::Matches($Content, $pattern)
                foreach ($m in $matches) {
                    $lineNum = ($Content.Substring(0, $m.Index) -split "`n").Count
                    $Findings += "Line ${lineNum}: potential secret detected"
                }
            }
        }
    }

    if ($Findings.Count -gt 0) {
        $Response = @{
            decision = "allow"
            reason = "Potential secrets detected in $FilePath - please review manually"
            hookSpecificOutput = @{
                hookEventName = "PostToolUse"
                additionalContext = "AI Toolbox Security: Potential secrets detected in $FilePath`:`n$($Findings -join "`n")`n`nPlease verify these are not accidental credentials. If they are placeholders or test fixtures, add to .gitignore or rename."
            }
        }
        Write-Host ($Response | ConvertTo-Json -Depth 5 -Compress)
    } else {
        Write-Host '{"decision":"allow","reason":"Security check passed"}'
    }
    exit 0

} catch {
    Write-Host '{"decision":"allow","reason":"Hook error, passing through"}'
    exit 0
}
