# Runbook

This file stores recurring operational knowledge for the repository.

Use it for setup notes, recovery steps, repeated commands, and maintenance procedures.

It should answer:
- How do we start?
- How do we recover?
- How do we verify?
- What commands are commonly used?

---

## How to use this file

Write practical procedures here.
Do not use this file for architecture arguments or brainstorming.
Keep entries operational and repeatable.

---

## Sections

### 1. Startup procedure
Follow the **Definitive Boot Sequence** from `AGENT.md §2`. This procedure ensures all context and task states are recovered before starting work.

### 2. Verification procedure
- Run tests if tests exist
- If no tests exist, run the most relevant verification command
- Inspect the actual output
- Do not mark work as complete without verification

### 3. Terminal procedure
- Prefer concise command output
- Use `rtk` for heavy test/build commands where available
- Use `rtk read <file>` for large log files
- Avoid raw long log dumps into model context

### 4. Memory maintenance
- Record architecture changes in `architecture-decisions.md`
- Record integration expectations in `integration-contracts.md`
- Record current unfinished state in `session-handover.md`
- Keep entries short, durable, and useful

### 5. Recovery procedure
If the next session seems unclear:
1. Re-read all memory files
2. Reconstruct the intended architecture
3. Check the most recent unfinished work
4. Resume only after the project state is understandable


