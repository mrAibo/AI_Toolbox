#!/bin/bash
# sync-task.sh
# Export current task state to a static file for the AI to read.

echo "[sync-task] Exporting current task tracker state to memory..."
if command -v bd &> /dev/null; then
    bd list > .agent/memory/current-task.md
    echo "[sync-task] Task state exported to .agent/memory/current-task.md"
else
    # Fallback: Preserve existing manual entries or initialize if missing/empty
    if [ ! -f .agent/memory/current-task.md ] || [ ! -s .agent/memory/current-task.md ]; then
        cat << 'EOF' > .agent/memory/current-task.md
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
        echo "[sync-task] Initialized structured task in .agent/memory/current-task.md"
    else
        echo "[sync-task] Beads (bd) not installed. Keeping existing manual task entries."
    fi
fi
