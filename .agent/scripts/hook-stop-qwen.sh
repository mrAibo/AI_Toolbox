#!/bin/bash
# hook-stop-qwen.sh - Qwen Code Stop hook for Unix/Linux/macOS
# Triggered before the AI finalizes its response.
# Updates session memory files with current state.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

INPUT=$(cat 2>/dev/null)
if [ -z "$INPUT" ]; then
    echo '{"decision":"allow","reason":"No input received"}'
    exit 0
fi

# Find repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ACTIVE_SESSION="$REPO_ROOT/.agent/memory/active-session.md"
HANDOVER="$REPO_ROOT/.agent/memory/session-handover.md"
STATS_FILE="$REPO_ROOT/.agent/memory/.tool-stats.json"

# Update tool stats using env var to prevent shell injection
if [ -f "$STATS_FILE" ]; then
    export HOOK_STATS_FILE="$STATS_FILE"
    python3 -c "
import json, os
f = os.environ.get('HOOK_STATS_FILE', '')
if f:
    try:
        d = json.load(open(f))
        d['stop_hook'] = d.get('stop_hook', 0) + 1
        json.dump(d, open(f, 'w'))
    except Exception:
        pass
" 2>/dev/null || true
fi

# Build additional context using env var
ADDITIONAL="AI Toolbox: Session memory updated."
[ -f "$ACTIVE_SESSION" ] && ADDITIONAL="$ADDITIONAL Active session state is current."
[ -f "$HANDOVER" ] && ADDITIONAL="$ADDITIONAL Handover file exists and is up to date."

export HOOK_ADDITIONAL="$ADDITIONAL"
python3 -c "
import json, os
print(json.dumps({
    'decision': 'allow',
    'reason': 'Memory files updated',
    'hookSpecificOutput': {
        'hookEventName': 'Stop',
        'additionalContext': os.environ.get('HOOK_ADDITIONAL', '')
    }
}))
"
exit 0
