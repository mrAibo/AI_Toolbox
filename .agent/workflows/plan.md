---
description: Initialize a native Antigravity implementation plan from the template
---

1. Read `.agent/templates/antigravity-plan.md`
2. Create or update the `implementation_plan.md` artifact with the template structure
3. Summarize the goal and proposed changes to the user
4. Set `request_feedback = true` in the artifact metadata

## Verification

Before executing a plan:
- Verify all tasks are broken into 2-5 minute increments
- Check that each task has a clear verification step
- Confirm dependencies between tasks are identified
- Verify the plan addresses the original requirements
- Check that rollback/undo steps are documented for risky changes
- Run a dry-run verification: read the plan, check for gaps, verify completeness
