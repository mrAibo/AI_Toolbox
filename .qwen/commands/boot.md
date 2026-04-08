---
name: boot
description: Run AI Toolbox boot sequence — check environment, sync tasks, load memory
---
# Boot Command

Run the AI Toolbox boot sequence to initialize the session.

## What This Does

1. Check environment (rtk, bd, MCP status)
2. Read architecture decisions and integration contracts
3. Read session handover from last session
4. Run sync-task to update current task state
5. Load available skills list
6. Summarize recovered context

## Execution

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1
```

```bash
# Unix/macOS
bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md
```

## After Boot

Report status:
```
✅ AI Toolbox Active
  → rtk: [installed / not installed]
  → Beads: [installed / not installed]
  → MCP: [configured / not configured]
  → Skills: brainstorming, tdd, testing, debugging, code-review, branch-finish, safety, parallel
```
