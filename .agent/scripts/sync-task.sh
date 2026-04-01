#!/bin/bash
# sync-task.sh
# Export current task state to a static file for the AI to read.

echo "[sync-task] Exporting current task tracker state to memory..."
if command -v bd &> /dev/null; then
    bd list > .agent/memory/current-task.md
    echo "[sync-task] Task state exported to .agent/memory/current-task.md"
else
    echo "[sync-task] Beads (bd) is not installed. Cannot sync tasks."
    echo "No task tracker installed. Use manual instructions or issue trackers." > .agent/memory/current-task.md
fi
