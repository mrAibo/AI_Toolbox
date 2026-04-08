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

## 9-Step Workflow Quick Reference

1. **EPIC** → `bd create -t epic "Goal"`
2. **BRAINSTORM** → `superpowers:brainstorming` (design before code)
3. **PLAN** → `superpowers:writing-plans` (2-5 min tasks)
4. **SUB-TASKS** → `bd create` for each + `bd dep add`
5. **ISOLATE** → `superpowers:using-git-worktrees`
6. **IMPLEMENT** → `bd ready` → pick → TDD (RED → GREEN → REFACTOR)
7. **REVIEW** → `superpowers:requesting-code-review`
8. **VERIFY** → `superpowers:verification-before-completion`
9. **FINISH** → `superpowers:finishing-a-development-branch` → `bd close`

### 4 Hard Rules
- No production code without a failing test first
- No completion claims without running verification
- No work without a beads task
- Always query Context7 before implementing with external libraries

**Parallelize independent operations** — see [.agent/rules/parallel-execution.md](.agent/rules/parallel-execution.md). Never sequentially fetch URLs or read files that don't depend on each other.
