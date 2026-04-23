# AI Toolbox Protocol (Claude Code) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

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

> **Note:** Entries prefixed with `superpowers:` are **skill names** from the [Superpowers methodology](https://github.com/obra/superpowers), not CLI commands. They indicate which skill's guidance to follow. `bd` commands are actual Beads CLI commands.

1. **EPIC** → `bd create -t epic "Goal"`
2. **BRAINSTORM** → follow *superpowers:brainstorming* skill (design before code)
3. **PLAN** → follow *superpowers:writing-plans* skill (2-5 min tasks)
4. **SUB-TASKS** → `bd create` for each + `bd dep add`
5. **ISOLATE** → follow *superpowers:using-git-worktrees* skill
6. **IMPLEMENT** → `bd ready` → pick → TDD (RED → GREEN → REFACTOR)
7. **REVIEW** → follow *superpowers:requesting-code-review* skill
8. **VERIFY** → follow *superpowers:verification-before-completion* skill
9. **FINISH** → follow *superpowers:finishing-a-development-branch* skill → `bd close`

### 4 Hard Rules
- No production code without a failing test first
- No completion claims without running verification
- No work without a beads task
- Always query Context7 before implementing with external libraries

**Parallelize independent operations** — see [.agent/rules/parallel-execution.md](.agent/rules/parallel-execution.md). Never sequentially fetch URLs or read files that don't depend on each other.
