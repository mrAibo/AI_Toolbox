#!/bin/bash
# hook-pre-command-qwen.sh - Qwen Code PreToolUse hook for Unix/Linux/macOS
# Validates heavy commands and recommends rtk wrapper.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

if [ -t 0 ]; then
    INPUT=""
else
    INPUT=$(cat 2>/dev/null)
fi
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

# Align with Claude hook: include all heavy command families.
HEAVY_REGEX="^(python|python3|mvn|gradle|gradlew|pytest|npm run|npm test|pnpm run|pnpm test|yarn run|yarn test|db2cli|hdbcli|sqlplus|ansible-playbook|javac|java -jar|cargo build|cargo test|cargo run|cargo check|go build|go test|go run|docker build|docker compose build|docker-compose build)"

# Normalize: strip leading whitespace and env/VAR=val prefixes to prevent trivial bypasses.
# Handles: "  python", "env python", "VAR=1 python".
TOOL_INPUT_CHECK="$(printf '%s' "$TOOL_INPUT" | sed 's/^[[:space:]]*//' | sed 's/^env[[:space:]]*//' | sed 's/^\([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]*\)*//')"

if echo "$TOOL_INPUT_CHECK" | grep -qE "$HEAVY_REGEX" && ! echo "$TOOL_INPUT_CHECK" | grep -q "^rtk "; then
    if ! command -v python3 &>/dev/null; then
        echo '{"decision":"ask","reason":"Heavy command detected — consider rtk wrapper","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"AI Toolbox: Heavy command. Prefix with rtk."}}'
        exit 0
    fi
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
elif echo "$TOOL_INPUT_CHECK" | grep -qE "^(cat|less|tail|head) .+\.log" && ! echo "$TOOL_INPUT_CHECK" | grep -q "^rtk "; then
    if ! command -v python3 &>/dev/null; then
        echo '{"decision":"allow","reason":"Log file detected — consider rtk read","hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"AI Toolbox: Large log file detected. Consider using rtk read <file> for efficient reading."}}'
        exit 0
    fi
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
