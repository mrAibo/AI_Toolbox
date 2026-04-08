---
name: sync
description: Sync task state from Beads/task tracker to AI Toolbox memory files
---
# Sync Command

Synchronize the current task state from the task tracker to AI Toolbox memory files.

## What This Does

1. Run sync-task script to export task state
2. Update `.agent/memory/current-task.md`
3. Update `.agent/memory/active-session.md`

## Execution

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1
```

```bash
# Unix/macOS
bash .agent/scripts/sync-task.sh
```

## When to Use

- At session start (via /boot)
- After task changes (bd create, bd close, bd update)
- Before planning or implementation
