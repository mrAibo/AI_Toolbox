#!/bin/bash
# sync-task.sh
# Export current task state to a static file for the AI to read.
# Also detects task type and suggests the appropriate workflow.

REPO_ROOT="$(git rev-parse --show-toplevel)"
TASK_FILE="$REPO_ROOT/.agent/memory/current-task.md"
ACTIVE_SESSION="$REPO_ROOT/.agent/memory/active-session.md"

echo "[sync-task] Exporting current task tracker state to memory..."
if command -v bd &> /dev/null; then
    bd list > "$TASK_FILE"
    echo "[sync-task] Task state exported to $TASK_FILE"

    # Detect task type from Beads output and suggest workflow
    TASK_TITLE=$(head -1 "$TASK_FILE" 2>/dev/null || echo "")
    if echo "$TASK_TITLE" | grep -qiE 'fix|bug|issue|error|crash'; then
        echo "[sync-task] 🐛 Bug fix detected — suggesting Bug-Fix Workflow"
    elif echo "$TASK_TITLE" | grep -qiE 'refactor|rewrite|migrate|rename'; then
        echo "[sync-task] 🔧 Refactor detected — suggesting Code Review Workflow"
    elif echo "$TASK_TITLE" | grep -qiE 'feature|build|create|add|implement'; then
        echo "[sync-task] 🚀 Feature detected — suggesting Unified Workflow (9 steps)"
    fi
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

# Update active-session.md with current task info if it exists
if [ -f "$ACTIVE_SESSION" ]; then
    TASK_INFO=$(head -3 "$TASK_FILE" 2>/dev/null || echo "No task info")
    # Append task info to active session (overwrite old task section)
    sed -i '/## Current Step/,$d' "$ACTIVE_SESSION" 2>/dev/null || true
    cat << EOF >> "$ACTIVE_SESSION"
## Current Step
- **Workflow:** Awaiting task analysis
- **Task:** $TASK_INFO
EOF
fi
