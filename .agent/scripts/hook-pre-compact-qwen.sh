#!/bin/bash
# hook-pre-compact-qwen.sh - Qwen Code PreCompact hook for Unix/Linux/macOS
# Triggered before conversation compaction (context pruning).
# Injects important architecture context so it survives compaction.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

INPUT=$(cat 2>/dev/null)
if [ -z "$INPUT" ]; then
    echo '{"decision":"allow","reason":"No input received"}'
    exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ADR_FILE="$REPO_ROOT/.agent/memory/architecture-decisions.md"
CURRENT_TASK="$REPO_ROOT/.agent/memory/current-task.md"

# Build context
CONTEXT=""

# Current task summary
if [ -f "$CURRENT_TASK" ]; then
    TASK_SUMMARY=$(head -5 "$CURRENT_TASK" 2>/dev/null | tr '\n' ' ')
    CONTEXT="${CONTEXT}### Current Task: ${TASK_SUMMARY}\n\n"
fi

# Latest ADR
if [ -f "$ADR_FILE" ]; then
    LATEST_ADR=$(grep -A10 "^### ADR-" "$ADR_FILE" 2>/dev/null | tail -10 | tr '\n' ' ')
    if [ -n "$LATEST_ADR" ]; then
        CONTEXT="${CONTEXT}### Latest Architecture Decision: ${LATEST_ADR}\n\n"
    fi
fi

CONTEXT="${CONTEXT}## Key Rules\n- Use rtk for heavy commands\n- Update .agent/memory/ files when state changes\n- Follow .agent/rules/*.md"

python3 -c "
import json
context = '''$CONTEXT'''
print(json.dumps({
    'decision': 'allow',
    'reason': 'Architecture context injected',
    'hookSpecificOutput': {
        'hookEventName': 'PreCompact',
        'additionalContext': '## AI Toolbox Architecture Context (survives compaction)\n\n' + context
    }
}))
"
exit 0
