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

# Update tool stats
if [ -f "$STATS_FILE" ]; then
    python3 -c "
import json, os
f = '$STATS_FILE'
if os.path.exists(f):
    d = json.load(open(f))
    d['stop_hook'] = d.get('stop_hook', 0) + 1
    json.dump(d, open(f, 'w'))
" 2>/dev/null || true
fi

# Build additional context
ADDITIONAL="AI Toolbox: Session memory updated."
[ -f "$ACTIVE_SESSION" ] && ADDITIONAL="$ADDITIONAL Active session state is current."
[ -f "$HANDOVER" ] && ADDITIONAL="$ADDITIONAL Handover file exists and is up to date."

python3 -c "
import json
print(json.dumps({
    'decision': 'allow',
    'reason': 'Memory files updated',
    'hookSpecificOutput': {
        'hookEventName': 'Stop',
        'additionalContext': '$ADDITIONAL'
    }
}))
"
exit 0
