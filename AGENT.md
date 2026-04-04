# Universal AI Workflow & Triggers

This file defines the workflow contract for the AI agent working inside this repository.

The agent must treat this file as the primary execution standard for project work.

---

## 1. General behavior

- Do not jump directly into coding when the task is large, unclear, or architectural.
- Prefer structured execution over improvisation.
- Keep the project state durable in files, not only in chat context.
- Use the repository memory and task structure before asking the user to repeat context.
- Do not claim completion without verification.

### Universal vs. Client-Specific
This framework is architechurally **universal**. While this `AGENT.md` is the **Master Protocol**, individual AI agents should prioritize their optimized entry points:
- **Claude Code:** Uses `CLAUDE.md` and `.claude.json`.
- **Cursor / Windsurf:** Uses `.cursorrules` and `.windsurfrules`.
- **Antigravity:** Uses `SKILL.md` and `.agent/workflows/`.

Each entry point contains **Critical Session Rules** to ensure session resilience.

---

## 2. Boot sequence

This is the **Definitive Boot Sequence**. All agents must follow this procedure at the start of a fresh session:

1. **Environmental Check:** Check for the presence of `.agent/` folder and recommended binaries (`rtk`, `bd`).
2. **Context Recovery:** Read `.agent/memory/architecture-decisions.md` and `.agent/memory/integration-contracts.md`.
3. **Work-in-Progress Check:** Read `.agent/memory/session-handover.md` if it exists.
4. **Task Synchronization:** Run `.agent/scripts/sync-task.sh` (or `.ps1` on Windows) to update `.agent/memory/current-task.md` with the latest state from the task tracker.
5. **Summarization:** Briefly summarize the recovered context, current state, and the next planned task before continuing.

Purpose:
- Restore architecture and integration context.
- Restore work exactly where it was left off.
- Avoid context drift after a restart.

---

## 3. New project / large feature workflow

If the user asks for a new project, a new subsystem, or a large feature:

1. Do not code immediately
2. Start with brainstorming
3. Propose multiple possible approaches if appropriate
4. Ask for confirmation if the architectural direction is unclear
5. Record the selected direction in `.agent/memory/architecture-decisions.md`
6. Create the work structure in Beads
7. Execute only the next ready task

The workflow order is:

Brainstorm -> Architecture decision -> Task creation -> Implementation -> Verification -> Memory update

---

## 4. Execution rules

- Run `.agent/scripts/sync-task.sh` regularly to ensure your view of the task tracker is up-to-date
- Work from the `.agent/memory/current-task.md` state whenever available
- Prefer small, verifiable steps
- Prefer test-first or verification-first execution where possible
- Keep changes focused and reversible
- Update memory when the project state changes
- Do not silently introduce new frameworks, libraries, or major architecture changes without recording them

---

## 5. Terminal rules

When using the terminal, adhere to the **[.agent/rules/safety-rules.md](.agent/rules/safety-rules.md)**.

**Quick Reference:**
- Use **rtk** for all heavy terminal commands (python, cargo, tests, etc.).
- Avoid dumping raw long logs directly into context.
- Prefer concise, inspectable command output.

Examples:
- `rtk pytest`
- `rtk mvn test`
- `rtk cat large_output.log`

---

## 6. Memory rules

### Architecture memory
Use `.agent/memory/architecture-decisions.md` for:
- architecture choices
- rejected alternatives
- important tool or framework decisions
- workflow decisions that should persist

### Integration memory
Use `.agent/memory/integration-contracts.md` for:
- API contracts
- schema expectations
- file format expectations
- important input/output assumptions

### Session handover
Use `.agent/memory/session-handover.md` for:
- unfinished work
- blockers
- next recommended step
- current task handoff

### Runbook
Use `.agent/memory/runbook.md` for:
- operational procedures
- setup notes
- recovery steps
- recurring commands or maintenance instructions

---

## 7. Brainstorming rules

When a request is exploratory, unclear, or architectural:

- start with analysis instead of implementation
- identify constraints first
- propose a small number of realistic approaches
- prefer practical approaches over impressive ones
- only move into implementation after the direction is stable

Brainstorming should produce structure, not noise.

---

## 8. Verification rules

Before reporting success, follow the **[.agent/rules/testing-rules.md](.agent/rules/testing-rules.md)**.

**Bug Fix Sequence:**
1. **Reproduce** the problem with a test or command.
2. **Identify** the likely cause.
3. **Implement** the fix.
4. **Verify** using the reproduction step.
5. **Record** durable knowledge if the bug was non-trivial.

Never say that something works unless it has been checked.

---

## 9. Safety rules

For all behavioral constraints and destroyer-prevention, refer to **[.agent/rules/safety-rules.md](.agent/rules/safety-rules.md)**.

**Core Safety Principle:**
Do not perform destructive, irreversible, or high-risk actions (delete files, rewrite large parts, force-push) without explicit user intent.

---

## 10. End-of-session behavior

Before ending a meaningful work session:

1. Update memory files if needed
2. Update session handover
3. Make sure the next step is clear
4. Leave the repository in a recoverable state

The next session should be able to continue with minimal explanation.

---

---

## 11. Client-Specific Extensions

Some AI assistant environments provide additional capabilities or specific rules. If an extension exists for your environment in the `[.agent/rules/](.agent/rules/)` directory, please follow it:

- **Antigravity:** Refer to **[.agent/rules/antigravity.md](.agent/rules/antigravity.md)** for native slash commands and artifact workflows.
- [Other Clients]: Add your specific client instructions to `.agent/rules/` and reference them here.

These artifacts are first-class citizens in Antigravity and should be used to provide a premium agentic experience.

---

## 12. The Toolbox Toolkit

For maximum efficiency and context safety, use these recommended binary tools:

- **rtk (Rust Token Killer):** Mandatory console proxy for heavy commands.
- **Beads (bd):** Git-backed CLI task tracker for out-of-context planning.
- **bat & rg (ripgrep):** Modern alternatives to `cat` and `grep` for faster, cleaner file inspection.

AI Toolbox scripts (like `bootstrap`) automatically check for these tools and provide installation hints.

---
