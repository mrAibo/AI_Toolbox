#!/bin/bash
set -e

echo "[stop] consolidating session memory..."

if [ -f .agent/memory/session-handover.md ]; then
  echo "[stop] session handover file exists"
fi

echo "[stop] remember to update:"
echo "  - .agent/memory/architecture-decisions.md"
echo "  - .agent/memory/integration-contracts.md"
echo "  - .agent/memory/session-handover.md"

echo "[stop] repository left in recoverable state"
