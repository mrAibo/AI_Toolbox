#!/bin/bash
set -e

echo "[stop] consolidating session memory..."

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(pwd)"
fi
_HOOK_STOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-audit.sh
. "$_HOOK_STOP_DIR/lib-audit.sh"

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
    HANDOVER_FILE="$REPO_ROOT/.agent/memory/session-handover.md"
    ACTIVE_FILE="$REPO_ROOT/.agent/memory/active-session.md"

    # PR1: _update_handover bundles append + cap into one locked critical section.
    # flock serializes concurrent hook-stop invocations; atomic temp-file rename
    # prevents readers from ever seeing a truncated handover file.
    _update_handover() {
      local handover="$1"
      local active="$2"

      # Append new summary entry
      {
        echo ""
        echo "## Session Summary - $(date -u '+%Y-%m-%d %H:%M UTC')"
        cat "$active"
      } >> "$handover"

      # Cap to last 10 session summaries
      local SUMMARY_COUNT
      SUMMARY_COUNT=$(grep -c "^## Session Summary " "$handover" 2>/dev/null || echo "0")
      if [ "$SUMMARY_COUNT" -gt 10 ]; then
        local TRIM_COUNT=$((SUMMARY_COUNT - 10))
        local KEEP_FROM
        KEEP_FROM=$(grep -n "^## Session Summary " "$handover" | sed -n "$((TRIM_COUNT + 1))p" | cut -d: -f1)
        if [ -n "$KEEP_FROM" ]; then
          local FIRST_SUMMARY
          FIRST_SUMMARY=$(grep -n "^## Session Summary " "$handover" | head -1 | cut -d: -f1)
          local TMPFILE="${handover}.tmp.$$"
          if [ -n "$FIRST_SUMMARY" ] && [ "$FIRST_SUMMARY" -gt 1 ]; then
            head -n $((FIRST_SUMMARY - 1)) "$handover" > "$TMPFILE"
            echo "" >> "$TMPFILE"
          else
            : > "$TMPFILE"
          fi
          tail -n +"$KEEP_FROM" "$handover" >> "$TMPFILE"
          mv "$TMPFILE" "$handover"
        fi
      fi
    }

    if command -v flock >/dev/null 2>&1; then
      { flock -x 9; _update_handover "$HANDOVER_FILE" "$ACTIVE_FILE"; } \
          9>"${HANDOVER_FILE}.lock"
    else
      # No flock: atomic rename in cap still prevents truncated file; rare race accepted
      _update_handover "$HANDOVER_FILE" "$ACTIVE_FILE"
    fi
    audit_event "session_handover_written" "file=session-handover.md"
  fi
fi

echo "[stop] repository left in recoverable state"

