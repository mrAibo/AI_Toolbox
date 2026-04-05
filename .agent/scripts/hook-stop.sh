#!/bin/bash
set -e

echo "[stop] consolidating session memory..."

REPO_ROOT="$(git rev-parse --show-toplevel)"

if [ -f "$REPO_ROOT/.agent/memory/session-handover.md" ]; then
  echo "[stop] session handover file exists"
fi

if [ -x "$REPO_ROOT/.agent/scripts/sync-task.sh" ]; then
  "$REPO_ROOT/.agent/scripts/sync-task.sh"
fi

# Auto-refresh Beads task context (like Template Bridge PreCompact hook)
if command -v bd &> /dev/null; then
  bd prime 2>/dev/null || true
fi

echo "[stop] remember to update:"
echo "  - .agent/memory/architecture-decisions.md"
echo "  - .agent/memory/integration-contracts.md"
echo "  - .agent/memory/session-handover.md"

# Write session summary to session-handover.md if active-session.md exists
if [ -f "$REPO_ROOT/.agent/memory/active-session.md" ]; then
  echo ""
  echo "[stop] 📊 Session summary available in .agent/memory/active-session.md"
  echo "[stop] Writing final summary to session-handover.md..."
  if [ -f "$REPO_ROOT/.agent/memory/session-handover.md" ]; then
    echo "" >> "$REPO_ROOT/.agent/memory/session-handover.md"
    echo "## Session Summary — $(date -u '+%Y-%m-%d %H:%M UTC')" >> "$REPO_ROOT/.agent/memory/session-handover.md"
    cat "$REPO_ROOT/.agent/memory/active-session.md" >> "$REPO_ROOT/.agent/memory/session-handover.md"
  fi
fi

echo "[stop] repository left in recoverable state"
