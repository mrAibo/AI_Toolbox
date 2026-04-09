#!/bin/bash
# hook-session-end-qwen.sh - Qwen Code SessionEnd hook for Unix/Linux/macOS
# Triggered when the session is ending.
# Runs existing hook-stop.sh for full memory consolidation.
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

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Run existing hook-stop.sh
STOP_HOOK="$REPO_ROOT/.agent/scripts/hook-stop.sh"
if [ -f "$STOP_HOOK" ]; then
    bash "$STOP_HOOK" >/dev/null 2>&1 || true
fi

# Try bd prime
if command -v bd &>/dev/null; then
    bd prime 2>/dev/null || true
fi

python3 -c "
import json
print(json.dumps({
    'decision': 'allow',
    'reason': 'Session end consolidation complete',
    'hookSpecificOutput': {
        'hookEventName': 'SessionEnd',
        'additionalContext': 'AI Toolbox: Session memory consolidated. Next session will recover full context from .agent/memory/ files.'
    }
}))
"
exit 0
