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
    # Remove old Current Step section (portable: works on Linux and macOS)
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i '/## Current Step/,$d' "$ACTIVE_SESSION" 2>/dev/null || true
    else
      sed -i '' '/## Current Step/,$d' "$ACTIVE_SESSION" 2>/dev/null || true
    fi
    cat << EOF >> "$ACTIVE_SESSION"
## Current Step
- **Workflow:** Awaiting task analysis
- **Task:** $TASK_INFO
EOF
fi

# Fix 4: Count ready tasks and suggest Multi-Agent if >= 3
if command -v bd &> /dev/null; then
    READY_COUNT=$(bd ready 2>/dev/null | wc -l | tr -d ' ')
    if [ "$READY_COUNT" -ge 3 ]; then
        echo "[sync-task] 💡 $READY_COUNT tasks ready — consider Multi-Agent Workflow"
    fi
fi

# Fix 5: Suggest specialist templates based on detected stack
if [ -f "package.json" ]; then
    echo "[sync-task] 💡 Templates available: api-rest, database, ui-analysis"

    # Fix 5b: Scan import statements for framework-specific templates
    FRAMEWORKS_FOUND=""
    if grep -rq '"next"' src/ . --include="*.tsx" --include="*.ts" --include="*.js" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        FRAMEWORKS_FOUND="$FRAMEWORKS_FOUND web-frameworks/nextjs"
    fi
    if grep -rq '"react"' src/ . --include="*.tsx" --include="*.ts" --include="*.js" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        FRAMEWORKS_FOUND="$FRAMEWORKS_FOUND frontend/react"
    fi
    if grep -rq '"express"' src/ . --include="*.ts" --include="*.js" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        FRAMEWORKS_FOUND="$FRAMEWORKS_FOUND api-rest/express"
    fi
    if grep -rq '"@prisma/client"' src/ . --include="*.ts" --include="*.js" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        FRAMEWORKS_FOUND="$FRAMEWORKS_FOUND database/prisma"
    fi
    if grep -rq '"jest"' . --include="*.json" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        FRAMEWORKS_FOUND="$FRAMEWORKS_FOUND testing/jest"
    fi

    if [ -n "$FRAMEWORKS_FOUND" ]; then
        echo "[sync-task] 💡 Detected frameworks:$FRAMEWORKS_FOUND"
    fi
elif [ -f "Cargo.toml" ]; then
    echo "[sync-task] 💡 Templates available: programming-languages/rust, devops-infrastructure"
    if grep -rq "tokio" Cargo.toml 2>/dev/null; then
        echo "[sync-task] 💡 Detected: tokio async runtime"
    fi
    if grep -rq "actix" Cargo.toml 2>/dev/null; then
        echo "[sync-task] 💡 Detected: actix-web framework"
    fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    echo "[sync-task] 💡 Templates available: programming-languages/python, ai-specialists"
    if grep -rq "django" pyproject.toml requirements.txt 2>/dev/null; then
        echo "[sync-task] 💡 Detected: Django framework"
    fi
    if grep -rq "fastapi" pyproject.toml requirements.txt 2>/dev/null; then
        echo "[sync-task] 💡 Detected: FastAPI framework"
    fi
elif [ -f "go.mod" ]; then
    echo "[sync-task] 💡 Templates available: programming-languages/go, devops-infrastructure"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
    echo "[sync-task] 💡 Templates available: programming-languages/java, database"
fi
