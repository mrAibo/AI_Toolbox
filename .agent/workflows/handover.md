---
description: Finalize the session and create an Antigravity walkthrough
---

1. Summarize finished work for this session
2. Identify any new blockers or unfinished tasks
3. Update `.agent/memory/session-handover.md`
4. Run `.agent/scripts/sync-task.sh` to finalize the task state
5. Create a native Antigravity `walkthrough.md` artifact to summarize the session's impact
6. Report to the user and yield control

## Verification

Before finalizing the handover:
- Verify all completed tasks are listed with their outcomes
- Check that in-progress tasks have clear next steps documented
- Confirm any blockers are explicitly stated
- Verify the next session can understand the current state without additional context
- Check that tool usage stats (rtk, beads, MCP) are updated if applicable
- Run `.agent/scripts/doctor.sh` to verify project health
