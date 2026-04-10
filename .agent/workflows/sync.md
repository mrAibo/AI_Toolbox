---
description: Synchronize the current task tracker state to static memory and Antigravity artifacts
---

1. Run `.agent/scripts/sync-task.sh` (or `.ps1` on Windows)
2. Read the updated `.agent/memory/current-task.md`
3. Update the Antigravity `task.md` artifact to reflect the current state
4. Summarize the next ready tasks

## Verification

After syncing task state:
- Verify the sync output file (.agent/memory/current-task.md) exists and has content
- Check that the task state matches the source (Beads graph or manual entries)
- Confirm the active-session.md is updated with current task info
- Run `.agent/scripts/doctor.sh` and verify no errors related to task state
- Check that the session-handover.md reflects the latest sync timestamp
