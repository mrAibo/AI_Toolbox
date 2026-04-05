# Runbook

This file stores recurring operational knowledge for the repository.
Use it for setup notes, recovery steps, repeated commands, and maintenance procedures.

## 1. Startup procedure
1. Read `AGENT.md`
2. Read `.agent/memory/architecture-decisions.md`
3. Read `.agent/memory/integration-contracts.md`
4. Read `.agent/memory/session-handover.md` if present
5. Check Beads for current task state (`.agent/memory/current-task.md`)
6. Continue with the next ready task

## 2. Verification procedure
- Run tests if tests exist
- If no tests exist, run the most relevant verification command
- Inspect the actual output
- Do not mark work as complete without verification

## 3. Terminal procedure
- Prefer concise command output
- Use `rtk` for heavy test/build commands where available (e.g. `rtk test`, `rtk build`)
- Avoid raw long log dumps into model context

## 4. Memory maintenance
- Record architecture changes in `architecture-decisions.md`
- Record integration expectations in `integration-contracts.md`
- Record current unfinished state in `session-handover.md`
