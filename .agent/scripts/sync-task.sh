#!/bin/bash
# sync-task.sh
# Export current task state to a static file for the AI to read.

REPO_ROOT="$(git rev-parse --show-toplevel)"
TASK_FILE="$REPO_ROOT/.agent/memory/current-task.md"

echo "[sync-task] Exporting current task tracker state to memory..."
if command -v bd &> /dev/null; then
    bd list > "$TASK_FILE"
    echo "[sync-task] Task state exported to $TASK_FILE"
else
    # Fallback: Preserve existing manual entries or initialize if missing/empty
    if [ ! -f "$TASK_FILE" ] || [ ! -s "$TASK_FILE" ]; then
        cat << 'EOF' > "$TASK_FILE"
# Task: Short title

- Status: ready
- Priority: medium
- Owner: AI agent
- Related files:
- Goal:
- Steps:
    - [ ] Step 1
- Verification:
- Notes:
EOF
        echo "[sync-task] Initialized structured task in $TASK_FILE"
    else
        echo "[sync-task] Beads (bd) not installed. Keeping existing manual task entries."
    fi
fi
