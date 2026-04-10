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
This framework is architecturally **universal**. While this `AGENT.md` is the **Master Protocol**, individual AI agents should prioritize their optimized entry points:
- **Claude Code:** Uses `CLAUDE.md` and `.claude.json`.
- **Qwen Code:** Uses `QWEN.md`.
- **Gemini CLI:** Uses `GEMINI.md`.
- **Cursor:** Uses `.cursorrules`.
- **RooCode / Cline:** Uses `.clinerules`.
- **Windsurf:** Uses `.windsurfrules`.
- **Codex CLI:** Uses `CODERULES.md` and `.codex/` config.
- **OpenCode:** Uses `OPENCODERULES.md` and `opencode.json`.
- **Antigravity:** Uses `SKILL.md` and `.agent/workflows/`.
- **Aider:** Uses `CONVENTIONS.md` and `.aider.conf.yml`.

Each entry point contains **Critical Session Rules** to ensure session resilience.

---

## 2. Boot sequence

This is the **Definitive Boot Sequence**. All agents must follow this procedure at the start of a fresh session:

1. **Environmental Check:** Check for the presence of `.agent/` folder and recommended binaries (`rtk`, `bd`). Report status:
   ```
   ✅ AI Toolbox Active
     → rtk: [installed / not installed]
     → Beads: [installed / not installed]
     → MCP: [configured / not configured]
   ```
2. **Memory Index:** Read `.agent/memory/memory-index.md` first — it provides an overview of all memory files. Load detail files only on demand.
3. **Context Recovery:** Read `.agent/memory/architecture-decisions.md` (ADRs indexed in `adrs/`) and `.agent/memory/integration-contracts.md`.
4. **Work-in-Progress Check:** Read `.agent/memory/session-handover.md` if it exists.
5. **Task Synchronization:** Run `.agent/scripts/sync-task.sh` (or `.ps1` on Windows) to update `.agent/memory/current-task.md` with the latest state from the task tracker.
6. **Runbook:** Read `.agent/memory/runbook.md` if present (operational procedures).
7. **Session Status Init:** If `.agent/memory/active-session.md` is empty or missing, initialize it with the template structure (created by bootstrap at `.agent/memory/active-session.md`).
8. **Parallel Rules:** Read `.agent/rules/parallel-execution.md` to understand when parallel execution is required.
9. **Additional Rules (on demand):** The following rule files extend core behavior — read when relevant to the current task:
    - **[.agent/rules/receiving-code-review.md](.agent/rules/receiving-code-review.md)** — Anti-sycophancy: verify review feedback before blindly implementing
    - **[.agent/rules/root-cause-tracing.md](.agent/rules/root-cause-tracing.md)** — Backward trace through call stack, don't patch symptoms
    - **[.agent/rules/defense-in-depth.md](.agent/rules/defense-in-depth.md)** — Multi-layer post-fix validation (unit + integration + edge cases)
    - **[.agent/rules/condition-based-waiting.md](.agent/rules/condition-based-waiting.md)** — Poll for conditions instead of using arbitrary timeouts
    - **[.agent/rules/testing-anti-patterns.md](.agent/rules/testing-anti-patterns.md)** — Common testing mistakes to avoid
10. **Summarization:** Briefly summarize the recovered context, current state, available tools, and the next planned task before continuing.

Purpose:
- Restore architecture and integration context.
- Restore work exactly where it was left off.
- Avoid context drift after a restart.
- Make all available tools visible to the user.

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

For the complete 9-step process (TASK → BRAINSTORM → PLAN → ISOLATE → IMPLEMENT → REVIEW → VERIFY → FINISH → CLOSE), follow **[.agent/workflows/unified-workflow.md](.agent/workflows/unified-workflow.md)**.

---

## 4. Execution rules

- Run `.agent/scripts/sync-task.sh` (or `.ps1` on Windows) regularly to ensure your view of the task tracker is up-to-date
- Work from the `.agent/memory/current-task.md` state whenever available
- Prefer small, verifiable steps
- Prefer test-first or verification-first execution where possible
- Keep changes focused and reversible
- Update memory when the project state changes
- Do not silently introduce new frameworks, libraries, or major architecture changes without recording them
- **Parallelize independent operations** — see [.agent/rules/parallel-execution.md](.agent/rules/parallel-execution.md). Never sequentially fetch URLs or read files that don't depend on each other.
- **Test obligation:** All code changes MUST pass the test suite. Write tests before or alongside implementation (see [.agent/rules/tdd-rules.md](.agent/rules/tdd-rules.md)). If the project has an existing test suite, run it before claiming completion. If no tests exist, create at least one test that validates the core behavior.

---

## 5. Terminal rules

When using the terminal, adhere to the **[.agent/rules/safety-rules.md](.agent/rules/safety-rules.md)**.

### Hook execution
Before executing heavy commands, run the pre-command hook to validate:
```bash
# Unix/macOS
.agent/scripts/hook-pre-command.sh "your command"
```
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1 "your command"
```
If the hook passes (exit 0), proceed with command execution. If it fails (exit 1), you **MUST** prefix the command with `rtk` for token optimization, or review it for safety concerns before re-running.

At session end, run the stop hook to consolidate state:
```bash
# Unix/macOS
.agent/scripts/hook-stop.sh
```
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1
```

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

For the mandatory TDD process (RED-GREEN-REFACTOR), follow **[.agent/rules/tdd-rules.md](.agent/rules/tdd-rules.md)**.

**Bug Fix Sequence:**
For a structured bug-fix process, follow **[.agent/workflows/bug-fix.md](.agent/workflows/bug-fix.md)**:
1. **Reproduce** the problem with a test or command.
2. **Identify** the likely cause.
3. **Implement** the fix.
4. **Verify** using the reproduction step.
5. **Record** durable knowledge if the bug was non-trivial.

Before merging or marking a task complete, run the **[.agent/workflows/code-review.md](.agent/workflows/code-review.md)** self-review checklist.

Never say that something works unless it has been checked.

---

## 9. Safety rules

For all behavioral constraints and destructive-action prevention, refer to **[.agent/rules/safety-rules.md](.agent/rules/safety-rules.md)**.

For Model Context Protocol (MCP) usage constraints, refer to **[.agent/rules/mcp-rules.md](.agent/rules/mcp-rules.md)**.

For status reporting rules (when and how to report progress to the user), refer to **[.agent/rules/status-reporting.md](.agent/rules/status-reporting.md)**.

**Core Safety Principle:**
Do not perform destructive, irreversible, or high-risk actions (delete files, rewrite large parts, force-push) without explicit user intent.

---

## 10. End-of-session behavior

Before ending a meaningful work session:

1. Update memory files if needed
2. Update session handover
3. Make sure the next step is clear
4. Leave the repository in a recoverable state
5. If a task is complete, run **[.agent/workflows/branch-finish.md](.agent/workflows/branch-finish.md)** to finalize

The next session should be able to continue with minimal explanation.

---

## 11. Client-Specific Extensions

Some AI assistant environments provide additional capabilities or specific rules. If an extension exists for your environment in the `[.agent/rules/](.agent/rules/)` directory, please follow it:

- **Antigravity:** Refer to **[.agent/rules/antigravity.md](.agent/rules/antigravity.md)** for native slash commands and artifact workflows. These artifacts are first-class citizens in Antigravity and should be used to provide a premium agentic experience.
- **Qwen Code:** Refer to **[.agent/rules/qwen-code.md](.agent/rules/qwen-code.md)** for SubAgent configuration, hook setup, plan mode usage, and multi-agent coordination patterns.
- **Codex CLI:** Uses hooks via `.codex/hooks.json` and file-based rules via `CODERULES.md`. Full setup: **[docs/setup-codex.md](docs/setup-codex.md)**.
- **OpenCode:** Uses commands (`/boot`, `/sync`, `/handover`, `/templates`) and sub-agents via `opencode.json`. Full setup: **[docs/setup-opencode.md](docs/setup-opencode.md)**.
- **Other Clients:** Add your specific client instructions to the `[.agent/rules/](.agent/rules/)` directory and reference them here to ensure your environment's unique capabilities are leveraged.

---

## 12. Specialist Templates (Template Bridge)

When existing skills (TDD, Planning, Debugging) are insufficient, use the 413+ specialist templates:

- **Rules:** **[.agent/rules/template-usage.md](.agent/rules/template-usage.md)** — when to use, how to access, 26 categories
- **Workflow:** **[.agent/workflows/use-template.md](.agent/workflows/use-template.md)** — Gap Analysis → Search → Select → Adapt → Document → Execute

---

## 13. Context-Driven Skill Selection

**SHOULD:** When the agent recognizes one of the trigger patterns below, it **SHOULD** follow the referenced workflow. The `sync-task` script provides additional keyword-based hints at session start and end. The agent reads these signals and self-activates the appropriate skill.

**Note:** While "SHOULD" (not "MUST") is used because the agent self-regulates via reading these instructions, ignoring these triggers leads to degraded code quality, missed TDD cycles, and architectural drift. The workflows exist for a reason — use them.

| Trigger | Suggested Skill | What Happens |
|---------|----------------------|-------------|
| Test command detected (`rtk test`, `pytest`, etc.) | **[TDD Rules](.agent/rules/tdd-rules.md)** | **Enforce** RED-GREEN-REFACTOR cycle |
| Task title contains "fix", "bug", "issue" | **[Bug-Fix Workflow](.agent/workflows/bug-fix.md)** | **Run** 5 phases: Repro → Identify → Fix → Verify → Record |
| Task title contains "refactor", "rewrite", "migrate" | **[Code Review](.agent/workflows/code-review.md)** | **Run** checklist before finishing |
| Task title contains "feature", "build", "create" | **[Unified Workflow](.agent/workflows/unified-workflow.md)** | **Run** full 9-step process |
| 3+ independent sub-tasks identified | **[Multi-Agent](.agent/workflows/multi-agent.md)** | **Spawn** parallel agents automatically |
| Unfamiliar technology / specialized domain | **[Template Usage](.agent/rules/template-usage.md)** | **Suggest** and apply specialist templates |
| MCP query needed (docs, web, GitHub) | **[MCP Rules](.agent/rules/mcp-rules.md)** | **Use** configured MCP servers |

The agent announces skill activation:
```
📋 Skill activated: TDD Rules — RED phase
📋 Workflow: Bug-Fix — Phase 1/5: REPRODUCE
💡 Template available: devops-infrastructure/kubernetes (use /browse-templates)
```

---

## 14. The Toolbox Toolkit

For maximum efficiency and context safety, use these recommended binary tools:

- **rtk (Rust Token Killer):** Mandatory console proxy for heavy commands.
- **Beads (bd):** Git-backed CLI task tracker for out-of-context planning.
- **bat & rg (ripgrep):** Modern alternatives to `cat` and `grep` for faster, cleaner file inspection.

For detailed integration guides, setup commands, and how these tools work together, see **[.agent/rules/tool-integrations.md](.agent/rules/tool-integrations.md)**.

---

## 15. External Project Integrations

The AI Toolbox builds on established open-source projects. **AI Toolbox is the platform-universal adapter** — it translates external project methodologies for any AI client (Qwen Code, Claude Code, Cursor, etc.).

| Project | Role in AI Toolbox | How It's Used |
|---------|-------------------|---------------|
| **[rtk](https://github.com/rtk-ai/rtk)** | Token optimization (60-90% savings) | `cargo install --git https://github.com/rtk-ai/rtk --rev v0.35.0` + `rtk init -g` |
| **[Beads](https://github.com/steveyegge/beads)** | Graph-based task tracking | `go install github.com/steveyegge/beads/cmd/bd@v0.63.3` + `bd init` |
| **[Superpowers](https://github.com/obra/superpowers)** | **Methodology source** — TDD, brainstorming, debugging, code review, planning, worktrees | AI Toolbox `.agent/rules/` and `.agent/workflows/` are the **adapted versions** of Superpowers skills, translated for all platforms (not just Claude Code/Cursor) |
| **[Template Bridge](https://github.com/maslennikov-ig/template-bridge)** | **Template source** — 413+ specialist agents in 26 categories | Access via `npx claude-code-templates@0.1.0 --agent {category}/{name}` (pin version; check npm for latest). AI Toolbox `/templates` command provides unified access |
| **[MCP Servers](https://modelcontextprotocol.io/)** | External resources (docs, web, GitHub) | See [docs/mcp-guide.md](docs/mcp-guide.md) |

### Key Principle: No Duplication

- Superpowers provides the **methodology** → AI Toolbox rules are the **platform-universal adaptation**
- Template Bridge provides the **templates** → AI Toolbox commands provide **unified access**
- AI Toolbox provides the **adapter layer** → works with any AI client, not just Claude Code

Full integration details: **[.agent/rules/tool-integrations.md](.agent/rules/tool-integrations.md)**.

---
