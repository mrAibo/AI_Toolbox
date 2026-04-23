# AI Toolbox Protocol (Aider) -- Tier: Basic
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

This project uses the **AI Toolbox** workflow framework. As a **Basic-Tier** client, you have access to the Memory Layer and Rules Layer. Hooks are not available -- all safety rules are soft reminders.

## Session Guidelines (Soft Reminders)

> **Note:** These are recommendations, not enforced guardrails. Please follow them to maintain project consistency.

1. **BOOT:** Before starting, read `.agent/memory/current-task.md` to understand the current task state.
2. **SAFETY:** Prefer safe, reversible operations. Avoid destructive commands without explicit user confirmation. Prefer `--dry-run` where available.
3. **HANDOVER:** Before finishing, update `.agent/memory/session-handover.md` with what was completed and what remains.

## Memory Layer

> Boot order: see [memory-index.md](.agent/memory/memory-index.md) — it lists all memory files in priority order.

## Rules Layer

The following rule files define project standards. Please read and adhere to them:
- `.agent/rules/safety-rules.md`
- `.agent/rules/testing-rules.md`
- `.agent/rules/stack-rules.md`

## Limitations (Basic Tier)

- No hook automation -- sync and handover must be done manually.
- No multi-agent support.
- No plan mode integration.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
