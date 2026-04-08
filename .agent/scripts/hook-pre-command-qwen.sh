#!/bin/bash
# hook-pre-command-qwen.sh - Qwen Code PreToolUse hook for Unix/Linux/macOS
# Validates heavy commands and recommends rtk wrapper.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

INPUT=$(cat 2>/dev/null)
if [ -z "$INPUT" ]; then
    echo '{"decision":"allow","reason":"No input received"}'
    exit 0
fi

# Extract tool_input.command using env var to prevent injection
TOOL_INPUT=""
if command -v python3 &>/dev/null; then
    TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('command', '') if isinstance(ti, dict) else '')
" 2>/dev/null)
elif command -v jq &>/dev/null; then
    TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
fi

if [ -z "$TOOL_INPUT" ]; then
    echo '{"decision":"allow","reason":"No command detected"}'
    exit 0
fi

HEAVY_REGEX="^(python|python3|mvn|gradle|gradlew|pytest|npm run|npm test|pnpm run|pnpm test|yarn run|yarn test|cargo build|cargo test|cargo run|cargo check|go build|go test|go run|docker build|docker compose build|docker-compose build)"

if echo "$TOOL_INPUT" | grep -qE "$HEAVY_REGEX" && ! echo "$TOOL_INPUT" | grep -q "^rtk "; then
    export HOOK_TOOL_INPUT="$TOOL_INPUT"
    python3 -c "
import json, os
tool_input = os.environ.get('HOOK_TOOL_INPUT', '')
print(json.dumps({
    'decision': 'ask',
    'reason': 'Heavy command detected - consider using rtk wrapper',
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'ask',
        'permissionDecisionReason': 'AI Toolbox: Heavy command detected. Prefix with rtk to optimize token usage. Example: rtk ' + tool_input
    }
}))
"
elif echo "$TOOL_INPUT" | grep -qE "^(cat|less|tail|head) .+\.log" && ! echo "$TOOL_INPUT" | grep -q "^rtk "; then
    python3 -c "
import json
print(json.dumps({
    'decision': 'allow',
    'reason': 'Log file detected - consider rtk read',
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'additionalContext': 'AI Toolbox: Large log file detected. Consider using rtk read <file> for efficient reading.'
    }
}))
"
else
    echo '{"decision":"allow","reason":"Command approved"}'
fi
exit 0
