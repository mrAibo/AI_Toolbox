---
name: handover
description: Consolidate session memory and create handover for next session
---
# Handover Command

Create a session handover so the next session can pick up seamlessly.

## What This Does

1. Update `.agent/memory/session-handover.md` with:
   - What was completed
   - What files were changed
   - What tests were added/passed
   - Current task status
   - Next recommended step
   - Any blockers
2. Run hook-stop to consolidate state
3. Update tool usage stats

## Execution

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1
```

```bash
# Unix/macOS
.agent/scripts/hook-stop.sh
```

## When to Use

- Before ending a session
- When switching tasks
- When taking a break from work
