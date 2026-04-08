# hook-pre-command.ps1 - Qwen Code PreToolUse hook
# Reads tool_name and tool_input from stdin, validates heavy commands.
# Outputs JSON decision: allow/deny with reason.
# Exit 0 = allow, Exit 2 = block (Qwen Code convention).

try {
    $InputData = $null
    $RawInput = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($RawInput)) {
        try {
            $InputData = $RawInput | ConvertFrom-Json
        } catch {
            # Not JSON - skip silently (not a blocking error)
            Write-Host '{"decision":"allow","reason":"Non-JSON input, passing through"}'
            exit 0
        }
    }

    # Extract tool info (Qwen Code provides these fields)
    $ToolName = ""
    $ToolInput = ""
    if ($InputData) {
        $ToolName = $InputData.tool_name 2>$null
        $ToolInput = $InputData.tool_input 2>$null
        # tool_input might be an object with "command" field
        if ($ToolInput -and $ToolInput.GetType().Name -eq "PSCustomObject") {
            $ToolInput = $ToolInput.command 2>$null
        }
    }

    # If we can't determine the command, allow by default
    if ([string]::IsNullOrWhiteSpace($ToolInput)) {
        Write-Host '{"decision":"allow","reason":"No command detected"}'
        exit 0
    }

    $HeavyCommandRegex = "^(python|python3|mvn|gradle|gradlew|pytest|npm run|npm test|pnpm run|pnpm test|yarn run|yarn test|db2cli|hdbcli|sqlplus|ansible-playbook|javac|java -jar|cargo build|cargo test|cargo run|cargo check|go build|go test|go run|docker build|docker compose build|docker-compose build)"

    if ($ToolInput -match $HeavyCommandRegex -and $ToolInput -notmatch '^rtk ') {
        $Response = @{
            decision = "ask"
            reason = "Heavy command detected - consider using 'rtk' wrapper for token optimization"
            hookSpecificOutput = @{
                hookEventName = "PreToolUse"
                permissionDecision = "ask"
                permissionDecisionReason = "AI Toolbox: Heavy command detected. Prefix with 'rtk ' to optimize token usage. Example: rtk $ToolInput"
            }
        }
        Write-Host ($Response | ConvertTo-Json -Depth 5 -Compress)
        exit 0
    }

    if ($ToolInput -match '^(cat|less|tail|head) .+\.log' -and $ToolInput -notmatch '^rtk ') {
        $Response = @{
            decision = "allow"
            reason = "Log file detected - consider 'rtk read <file>' for efficient reading"
            hookSpecificOutput = @{
                hookEventName = "PreToolUse"
                additionalContext = "AI Toolbox: Large log file detected. Consider using 'rtk read <file>' for efficient reading."
            }
        }
        Write-Host ($Response | ConvertTo-Json -Depth 5 -Compress)
        exit 0
    }

    # Allow by default
    Write-Host '{"decision":"allow","reason":"Command approved"}'
    exit 0

} catch {
    # On any error, allow the command through (don't block on hook failure)
    Write-Host '{"decision":"allow","reason":"Hook error, passing through"}'
    exit 0
}
