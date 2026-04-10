#!/bin/bash
set -e

echo "[stop] consolidating session memory..."

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(pwd)"
fi

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
  echo "[stop] [STATS] Session summary available in .agent/memory/active-session.md"

  # Display tool usage stats if available
  STATS_FILE="$REPO_ROOT/.agent/memory/.tool-stats.json"
  if [ -f "$STATS_FILE" ]; then
    echo "[stop] [USAGE] Tool usage this session:"
    if command -v python3 &> /dev/null; then
      python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    stats = json.load(f)
for tool, count in sorted(stats.items(), key=lambda x: -x[1]):
    print(f'  -> {tool}: {count} uses')
" "$STATS_FILE" 2>/dev/null || echo "  (stats file unreadable)"
    elif command -v python &> /dev/null; then
      python -c "
import json, sys
with open(sys.argv[1]) as f:
    stats = json.load(f)
for tool, count in sorted(stats.items(), key=lambda x: -x[1]):
    print(f'  -> {tool}: {count} uses')
" "$STATS_FILE" 2>/dev/null || echo "  (stats file unreadable)"
    else
      cat "$STATS_FILE"
    fi
  fi

  echo "[stop] Writing final summary to session-handover.md..."
  if [ -f "$REPO_ROOT/.agent/memory/session-handover.md" ]; then
    echo "" >> "$REPO_ROOT/.agent/memory/session-handover.md"
    echo "## Session Summary - $(date -u '+%Y-%m-%d %H:%M UTC')" >> "$REPO_ROOT/.agent/memory/session-handover.md"
    cat "$REPO_ROOT/.agent/memory/active-session.md" >> "$REPO_ROOT/.agent/memory/session-handover.md"

    # Cap session-handover.md to last 10 session summaries to prevent unbounded growth
    HANDOVER_FILE="$REPO_ROOT/.agent/memory/session-handover.md"
    SUMMARY_COUNT=$(grep -c "^## Session Summary " "$HANDOVER_FILE" 2>/dev/null || echo "0")
    if [ "$SUMMARY_COUNT" -gt 10 ]; then
      TRIM_COUNT=$((SUMMARY_COUNT - 10))
      # Find the line number of the (TRIM_COUNT+1)-th "## Session Summary" header
      KEEP_FROM=$(grep -n "^## Session Summary " "$HANDOVER_FILE" | sed -n "$((TRIM_COUNT + 1))p" | cut -d: -f1)
      if [ -n "$KEEP_FROM" ]; then
        # Preserve content before the first summary header (e.g., project info, instructions)
        FIRST_SUMMARY=$(grep -n "^## Session Summary " "$HANDOVER_FILE" | head -1 | cut -d: -f1)
        if [ -n "$FIRST_SUMMARY" ] && [ "$FIRST_SUMMARY" -gt 1 ]; then
          HEADER=$(head -n $((FIRST_SUMMARY - 1)) "$HANDOVER_FILE")
        else
          HEADER=""
        fi
        tail -n +"$KEEP_FROM" "$HANDOVER_FILE" > "$HANDOVER_FILE.tmp"
        if [ -n "$HEADER" ]; then
          echo "$HEADER" > "$HANDOVER_FILE"
          echo "" >> "$HANDOVER_FILE"
        else
          : > "$HANDOVER_FILE"
        fi
        cat "$HANDOVER_FILE.tmp" >> "$HANDOVER_FILE"
        rm -f "$HANDOVER_FILE.tmp"
      fi
    fi
  fi
fi

echo "[stop] repository left in recoverable state"

