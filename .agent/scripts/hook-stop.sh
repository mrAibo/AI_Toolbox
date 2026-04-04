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

echo "[stop] remember to update:"
echo "  - .agent/memory/architecture-decisions.md"
echo "  - .agent/memory/integration-contracts.md"
echo "  - .agent/memory/session-handover.md"

echo "[stop] repository left in recoverable state"
