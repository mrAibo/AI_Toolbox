# AI Toolbox Protocol (Qwen Code) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

This project uses the **AI Toolbox** workflow framework. As a **Full-Tier** client, you have access to all features: hooks, multi-agent orchestration, plan mode, and sync automation.

## Critical Session Rules

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
   ```powershell
   # Windows: Run this at session start
   powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1
   ```
   ```bash
   # Unix/macOS: Run this at session start
   bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md
   ```
2. **SAFETY:** All heavy terminal commands (builds, tests, package installs) MUST be run via `rtk`.
   - Before heavy commands, the pre-command hook validates them:
   ```powershell
   # Windows: Run before heavy commands
   powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1 "your command here"
   ```
   - If hook passes, execute with `rtk`:
   ```powershell
   rtk your command here
   ```
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.
   ```powershell
   # Windows: Run at session end
   powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1
   ```

## Full-Tier Features Available

- **Hooks:** Pre/post-command hooks auto-sync state and enforce safety rules.
- **Multi-Agent:** Spawn sub-agents for parallel task execution. **Always parallelize independent operations** — see [.agent/rules/parallel-execution.md](.agent/rules/parallel-execution.md).
- **Plan Mode:** Use plan mode before major changes. Document in `.agent/memory/current-task.md`.
- **Sync:** Run `.agent/scripts/sync-task.sh` (or `.ps1`) to refresh your task view at any time.

## Memory Layer

> Boot order: see [memory-index.md](.agent/memory/memory-index.md) — it lists all memory files in priority order.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
