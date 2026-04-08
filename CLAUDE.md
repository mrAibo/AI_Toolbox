# AI Toolbox Protocol (Claude Code) -- Tier: Full

This project uses the **AI Toolbox** workflow. As a **Full-Tier** client you have access to hooks, multi-agent orchestration, and plan mode.

Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
   ```bash
   # Unix/macOS
   bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md
   ```
   ```powershell
   # Windows
   powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1
   ```
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
   - Before heavy commands, the pre-command hook validates:
   ```bash
   # Unix/macOS
   .agent/scripts/hook-pre-command.sh "command"
   ```
   ```powershell
   # Windows
   powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1 "command"
   ```
   - If blocked (exit 1), prefix with `rtk`: `rtk command`
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.
   ```bash
   # Unix/macOS
   .agent/scripts/hook-stop.sh
   ```
   ```powershell
   # Windows
   powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1
   ```

**Parallelize independent operations** — see [.agent/rules/parallel-execution.md](.agent/rules/parallel-execution.md). Never sequentially fetch URLs or read files that don't depend on each other.
