#!/bin/bash
set -e

echo "[bootstrap] preparing AI Toolbox structure..."
mkdir -p .agent/rules .agent/memory .agent/templates .agent/scripts .agent/workflows docs examples prompts

touch README.md AGENT.md  # ensure files exist if someone deleted them

TODAY=$(date +%Y-%m-%d)
if [ ! -s .agent/memory/architecture-decisions.md ]; then
cat << EOF > .agent/memory/architecture-decisions.md
# Architecture Decision Records (ADRs)

This file tracks major architectural decisions. Use the format from \`../templates/adr-template.md\`.

### ADR-0000: Use AI Toolbox for Repository Governance
- Status: accepted
- Date: $TODAY
- Context: Need a standardized, agent-agnostic way to maintain project memory and rules.
- Decision: Adopt AI Toolbox framework.
- Consequences: All agents must follow AGENT.md; memory is stored in .agent/.
- Rejected alternatives: Manual documentation, client-specific rules only.
EOF
fi

if [ ! -s .agent/memory/integration-contracts.md ]; then
cat << 'EOF' > .agent/memory/integration-contracts.md
# Integration Contracts

This file documents the contracts between different components, services, or third-party integrations (e.g. APIs, database schemas, library versions).

## Active Contracts
- [None yet]

## Potential Conflicts
- [None yet]
EOF
fi

if [ ! -s .agent/memory/session-handover.md ]; then
cat << 'EOF' > .agent/memory/session-handover.md
# Session Handover

## Completed
- [What was done]
- [Files changed]
- [Tests added/passed]

## In Progress
- [Current task ID and status]
- [Next recommended step]
- [Any blockers]

## Stats
- Tokens saved (rtk): ~0
- MCP queries: 0
- Sub-agents used: 0
EOF
fi

if [ ! -s .agent/memory/current-task.md ]; then
cat << 'EOF' > .agent/memory/current-task.md
# Task: Short title

- Status: ready
- Priority: medium
- Owner: AI agent
- Related files:
- Goal:
- Steps:
    - [ ] Step 1
- Verification:
- Notes:
EOF
fi

if [ ! -s .agent/memory/runbook.md ]; then
cat << 'EOF' > .agent/memory/runbook.md
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
EOF
fi

if [ ! -s .agent/memory/active-session.md ]; then
cat << 'EOF' > .agent/memory/active-session.md
# Active Session — [Date]

## Current Step
- **Workflow:** [Workflow name] (Step X/9 — [STEP NAME])
- **Task:** [Task description] ([beads-id])
- **Phase:** [Current phase, e.g. RED, GREEN, REVIEW]

## Active Skills & Rules
- [.agent/rules/file.md] — [What it's enforcing]

## Active Tools
- [tool] — [Usage stats]

## Active MCPs
- [mcp-server] — [Query count or last result]

## Multi-Agent Status
- Agents spawned: 0
- Agents active: 0

## Progress
- Steps completed: 0/9
- Subtasks done: 0/0
- Tokens saved (rtk): ~0
EOF
fi

# Initialize tool usage tracking file
if [ ! -f .agent/memory/.tool-stats.json ]; then
cat << 'EOF' > .agent/memory/.tool-stats.json
{"rtk": 0, "beads": 0, "mcp": 0}
EOF
fi

# Initialize memory index (READ FIRST during boot sequence)
if [ ! -s .agent/memory/memory-index.md ]; then
cat << 'EOF' > .agent/memory/memory-index.md
# Memory Index

This file provides a quick overview of all memory files. Read this first during boot, then load detail files only when relevant.

## Memory Files

- **architecture-decisions.md** — ADR log (architectural decisions)
- **integration-contracts.md** — API/schema contracts
- **session-handover.md** — Unfinished work from last session
- **current-task.md** — Active todo list (Beads tracker mirror)
- **runbook.md** — Operational procedures (if present)
- **active-session.md** — Live session state

## ADRs

See `.agent/memory/adrs/` for individual Architecture Decision Records.

EOF
fi

if [ ! -s .agent/rules/safety-rules.md ]; then
cat << 'EOF' > .agent/rules/safety-rules.md
# Safety Rules

This file defines the repository safety constraints for AI-assisted work.

Its purpose is to reduce accidental damage, unsafe assumptions, and destructive actions.

---

## Core safety principle

Do not perform destructive, irreversible, or high-risk actions unless the user clearly intended them.

If the intent is unclear, stop and clarify.

---

## Forbidden without explicit intent

Do not do the following unless the user explicitly wants it:
- delete files or directories
- rewrite large parts of the repository
- replace major technologies
- force-push or rewrite git history
- overwrite working configurations blindly
- remove tests, validation, or safety checks

---

## Required caution areas

Be extra careful when working with:
- database schema changes
- migration scripts
- authentication or authorization logic
- secrets, credentials, and tokens
- deployment configuration
- production-like data
- destructive shell commands

---

## Assumption rule

Do not treat assumptions as facts.

If something is inferred rather than verified:
- say so
- document the uncertainty
- avoid irreversible actions based on the assumption

---

## Smallest safe change

Always prefer the smallest change that achieves the goal.

Before implementing, ask: is there a smaller, safer version of this change?
If yes, do that first. Expand only when the smaller version proves insufficient.

Do not refactor, rename, or reorganize anything not directly related to the current task.
Stop and surface scope questions to the user rather than deciding silently.

---

## Scope control

Do not expand the scope of a task without explicit user approval.

If you discover something related that seems worth fixing:
- note it
- finish the current task
- propose the additional work separately

Silent scope expansion is a safety violation, not a helpful bonus.

---

## High-risk and public surfaces

Apply extra scrutiny before changing:
- public APIs and interfaces used by callers outside this module
- schema or protocol definitions that other systems depend on
- authentication, authorization, and security boundaries
- external-facing behavior (webhooks, events, CLI outputs)

For these surfaces: describe the change and its impact before implementing.

---

## Repository integrity rule

The repository should remain understandable and recoverable after each session.

That means:
- memory files should be updated when needed
- unfinished work should be handed over clearly
- no silent breaking changes should be introduced
- the next session should be able to continue safely

---

## Communication rule

If a task has real risk, communicate the risk before proceeding — not after.

Always communicate before acting when:
- the change touches a public or high-risk surface
- you are about to delete, overwrite, or restructure something significant
- you are making an assumption that the user has not confirmed
- scope is growing beyond what was originally requested
EOF
fi

if [ ! -s .agent/rules/testing-rules.md ]; then
cat << 'EOF' > .agent/rules/testing-rules.md
# Testing Rules

This file defines how work must be verified before it is considered complete.

The purpose is to prevent false completion, unverified assumptions, and silent regressions.

For the mandatory TDD process (RED-GREEN-REFACTOR), see **[tdd-rules.md](tdd-rules.md)**.

---

## Core rule

Do not claim that something works unless it has been checked.

Verification is mandatory.
If something cannot be verified, state that clearly.

---

## Evidence ladder

State only what evidence you actually have. The tiers are:

1. **Code written** — the code exists; behavior not yet verified
2. **Command ran** — a command was executed; output not yet reviewed
3. **Output reviewed** — the output was inspected; behavior not fully tested
4. **Tests pass** — automated tests pass; side effects not yet checked
5. **Behavior verified** — the intended behavior is confirmed end-to-end

Never skip a tier implicitly. If you are at tier 2, say so.

---

## Preferred workflow

When possible, use one of these approaches:
- test-first
- verification-first
- reproduce -> fix -> verify

The chosen approach depends on the task, but verification is always required.

---

## Required behavior

- Run tests when tests exist
- If there are no tests, run the most relevant verification command
- If no command exists, inspect the result in the most direct practical way
- Check the actual output instead of assuming success
- Mention what was verified and what remains unverified

---

## Terminal output discipline

- Prefer concise test output
- Use `rtk` for heavy test runs where possible
- Avoid pasting very large raw output into context
- Summarize failures clearly and precisely

---

## Change validation

For each meaningful code change, verify at least one of the following:
- tests pass
- build succeeds
- command output is correct
- file output is correct
- integration behavior matches the expected contract

---

## Bug fix workflow

For bug fixes, prefer this sequence:
1. Reproduce the problem
2. Identify the likely cause
3. Implement the fix
4. Re-run verification
5. Record durable knowledge if the bug was non-trivial

---

## Side-effect check

After verifying the primary behavior, check neighboring behavior:
- Did other tests still pass?
- Did adjacent functionality remain intact?
- Were any files, state, or outputs changed that were not intended?

A fix is not complete until side effects are ruled out.

---

## Verified vs. unclear

When reporting, explicitly separate:
- **Verified:** what was directly observed or tested
- **Assumed:** what was inferred but not directly confirmed
- **Unknown:** what was not checked

Do not collapse these categories. "It should work" or "it looks right" without evidence is not verification.

---

## Reporting rule

When reporting completion, mention:
- what was changed
- how it was verified
- what is still uncertain, if anything
EOF
fi

if [ ! -s .agent/rules/stack-rules.md ]; then
cat << 'EOF' > .agent/rules/stack-rules.md
# Stack Rules

This file defines stack-level constraints and preferences for the project.

Its purpose is to prevent random tool choices, uncontrolled framework drift, and unnecessary complexity.

---

## General rule

Do not introduce a new language, framework, library, database, or major build tool without a reason.

If a new dependency is necessary:
- explain why it is needed
- explain what problem it solves
- compare it with at least one simpler alternative
- record the decision in `architecture-decisions.md`

---

## Simplicity first

Prefer the simplest solution that correctly solves the problem.

Before adding complexity:
- ask whether a simpler mechanism already exists in the project
- ask whether the added complexity will outlast this task
- prefer boring and predictable over clever and fragile

A solution that requires explanation is harder to maintain than one that does not.

---

## Abstraction discipline

Do not introduce a new abstraction unless it eliminates repeated, concrete complexity.

An abstraction is justified only when:
- the same pattern recurs in at least two real places
- a simpler mechanism does not already handle it
- the abstraction makes the code easier to understand, not harder

When in doubt, duplicate first. Refactor only when the duplication pattern is clear.

---

## Stack selection principles

- Prefer the smallest stack that solves the problem
- Prefer existing project tools over new tools
- Prefer standard libraries over extra dependencies when practical
- Prefer stable, well-documented technologies over trendy ones
- Prefer explicit compatibility over assumptions

---

## Language and framework discipline

- Do not mix multiple paradigms or frameworks without a clear reason
- Do not introduce a framework just to avoid writing a small amount of code
- Avoid dependency sprawl
- Keep the stack understandable for future sessions

---

## Build and runtime discipline

- Keep the build process simple and reproducible
- Avoid unnecessary code generation layers
- Avoid hidden magic in setup and execution
- Prefer commands and workflows that can be explained in a short runbook

---

## AI workflow tools

The following tools are preferred in this repository when available:

- `rtk` for heavy terminal output and log compression
- `Beads` for task tracking and execution order
- `AGENT.md` and `.agent/memory/*.md` for durable workflow memory

---

## Documentation rule

Any meaningful stack decision must be reflected in:
- `architecture-decisions.md` for the decision itself
- `integration-contracts.md` if interfaces are affected
- `runbook.md` if operating procedures are affected
EOF
fi

if [ ! -s .agent/rules/antigravity.md ]; then
cat << 'EOF' > .agent/rules/antigravity.md
# Antigravity Environment Specifics

This file defines how to work with the **AI Toolbox** when using the **Antigravity** assistant environment.

---

## 🚀 Native Workflows (Slash Commands)

Use the built-in slash commands defined in `.agent/workflows/` for routine operations:

- `/start`: Performs the **Boot Sequence** (restores context, syncs tasks).
- `/plan`: Generates an **Implementation Plan** from the template.
- `/sync`: Synchronizes `bd` (Beads) state with project memory and artifacts.
- `/adr`: Records an **Architecture Decision Record** (ADR).
- `/handover`: Finalizes the session, updates memory, and generates a walkthrough.

---

## 📄 Artifact Management

Antigravity uses native artifacts to display structured project information. Maintain these as first-class citizens:

- **Implementation Plan:** Use `/plan` to trigger the `implementation_plan.md` artifact.
- **Task Tracking:** Always maintain the `task.md` artifact. Sync it with `/sync`.
- **Session Walkthrough:** Always generate a `walkthrough.md` artifact during the `/handover` workflow.

---

## 🧩 Antigravity Memory Coordination

While the AI Toolbox uses `.agent/memory/` for universal storage, Antigravity-specific artifacts provide the visual representation. Ensure they are always synchronized before concluding a session.
EOF
fi

if [ ! -s .agent/rules/qwen-code.md ]; then
cat << 'EOF' > .agent/rules/qwen-code.md
# Qwen Code Environment Specifics

Qwen Code is a **Full-Tier** client with access to hooks, multi-agent orchestration, plan mode, and sync automation.

## SubAgent Configuration
- Use the `agent` tool to spawn sub-agents for parallel task execution.
- Specify `subagent_type` as `general-purpose` for complex research/tasks or `Explore` for fast codebase exploration.
- Coordinate sub-agents via `.agent/memory/` files to maintain shared state.

## Hook Setup
- **Pre-command hook:** `.agent/scripts/hook-pre-command.sh` (or `.ps1`) — enforces `rtk` prefix for heavy commands.
- **Stop hook:** `.agent/scripts/hook-stop.sh` (or `.ps1`) — triggers memory consolidation on session end.
- Configure hooks in your Qwen Code settings analogously to Claude Code's `.claude.json` hook configuration.

## Plan Mode
- Use plan mode before major architectural changes.
- Document plans in `.agent/memory/current-task.md` after approval.

## Multi-Agent Coordination
- When spawning multiple agents, provide clear, independent prompts.
- Use `.agent/memory/session-handover.md` to track sub-agent outcomes.
- Refer to `QWEN.md` for Full-Tier feature details.
EOF
fi

if [ ! -s .agent/rules/tdd-rules.md ]; then
cat << 'EOF' > .agent/rules/tdd-rules.md
# TDD Rules

**When TDD is mandatory:** For all code changes.
**Cycle:** RED → GREEN → REFACTOR. Never write production code without a failing test.
- Write the smallest failing test first
- Make it pass with the simplest possible code
- Refactor only when tests are green
- Run tests via `rtk test` after every change

See also: [testing-rules.md](testing-rules.md)
EOF
fi

if [ ! -s .agent/rules/mcp-rules.md ]; then
cat << 'EOF' > .agent/rules/mcp-rules.md
# MCP Server Rules

**Before connecting:** Verify server identity and auth requirements.
**During sessions:** Log all tool calls, handle errors gracefully.
**After sessions:** Document which servers were used and what was accomplished.
- Never expose secrets in tool output
- Validate tool responses before passing to the model
- Use MCP only when local skills are insufficient

See also: [integration-contracts.md](../memory/integration-contracts.md)
EOF
fi

if [ ! -s .agent/rules/status-reporting.md ]; then
cat << 'EOF' > .agent/rules/status-reporting.md
# Status Reporting Rules

**Report at these moments:**
1. Step transitions (unified workflow steps)
2. Skill activation (which rule/workflow was triggered)
3. Tool usage (rtk, beads, MCP calls)
4. Multi-agent spawn/complete
5. Errors/blockers

**Status file format:** Update `.agent/memory/active-session.md` with current step, active skills/tools, multi-agent status.
**Session end:** Write summary to `.agent/memory/session-handover.md`.
EOF
fi

if [ ! -s .agent/rules/template-usage.md ]; then
cat << 'EOF' > .agent/rules/template-usage.md
# Template Usage Rules

**When to use templates:**
- Existing skills don't cover the need
- Specialized technology or pattern
- User explicitly asks for template guidance

**Process:**
1. Gap analysis — what's missing?
2. Search available templates (`.agent/templates/`)
3. Select most appropriate template
4. Adapt to project context
5. Document any deviations
6. Execute with the template as guide

See also: [architecture-decisions.md](../memory/architecture-decisions.md)
EOF
fi

if [ ! -s .agent/rules/tool-integrations.md ]; then
cat << 'EOF' > .agent/rules/tool-integrations.md
# Tool Integration Guide

## rtk (Runtime Toolkit)
- Wraps heavy commands: `rtk test`, `rtk build`, `rtk lint`
- Tracks token usage across sessions
- Hook integration via `rtk init -g`

## Beads (Task Tracker)
- `bd create`, `bd ready`, `bd list`, `bd close`
- Task state exported to `.agent/memory/current-task.md`

## MCP Servers
- context7 (documentation lookup)
- sequential-thinking (complex reasoning)

## Superpowers → AI Toolbox Mapping
| Superpower Skill | AI Toolbox Equivalent |
|---|---|
| TDD Workflow | `.agent/rules/tdd-rules.md` |
| Code Review | `.agent/workflows/code-review.md` |
| Multi-Agent | `.agent/workflows/multi-agent.md` |
| Templates | `.agent/rules/template-usage.md` |

See also: [template-usage.md](template-usage.md), [unified-workflow.md](../workflows/unified-workflow.md), [mcp-guide.md](../../docs/mcp-guide.md)
EOF
fi

echo "[bootstrap] creating AI auto-discovery router files..."
# CLAUDE.md is a committed file — only create/update if missing or empty
if [ ! -s CLAUDE.md ]; then
cat << 'EOF' > CLAUDE.md
# AI Toolbox Protocol (Claude Code) -- Tier: Full

This project uses the **AI Toolbox** workflow. As a **Full-Tier** client you have access to hooks, multi-agent orchestration, and plan mode.

Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
EOF
fi

# Create client-specific config folder
mkdir -p .agent/templates/clients
if [ -f ".agent/templates/clients/.claude.json" ] && [ ! -s .claude.json ]; then
    cp .agent/templates/clients/.claude.json .claude.json
    echo "[bootstrap] Installed .claude.json hooks"
fi

if [ ! -s GEMINI.md ]; then
cat << 'EOF' > GEMINI.md
# AI Toolbox Protocol (Gemini CLI) -- Tier: Basic

> **Tier Note:** Gemini CLI is a Basic-Tier client. Hooks are not available.
> All safety rules below are **soft reminders**, not enforced guardrails.

This project uses the **AI Toolbox** workflow framework. Read this file carefully at the start of every session.

## Session Guidelines (Soft Reminders)

1. **BOOT:** Read `.agent/memory/current-task.md` to understand the current task state before starting.
2. **SAFETY:** Prefer safe, reversible operations. Avoid destructive commands without explicit user confirmation.
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing your session.

## 1. Project Overview & Purpose
* **Primary Goal:** [Describe your project's main purpose here]
* **Workflow Standard:** This project adheres to the AI Toolbox development lifecycle.

## 2. Core Technologies & Stack
* **Workflow Engine:** AI Toolbox (AGENT.md)
* **Task Tracker:** Beads (bd)
* **Execution Wrapper:** RTK (Token-Safe Execution)
* **Languages/Frameworks:** [List your project's languages here, e.g. TypeScript, Python]

## 3. Architectural Patterns
* **Memory Management:** Repository-based project memory in `.agent/memory/`.
* **Decision Tracking:** Architecture Decision Records (ADRs) in `.agent/memory/architecture-decisions.md`.

## 4. Coding Conventions & Style Guide
* **Workflow Rule:** Follow the [AGENT.md](AGENT.md) Boot Sequence.
* **Naming:** [Inferred: Standard kebab-case for files, camelCase for variables]

## 5. Key Files & Entrypoints
* **Main Contract:** [AGENT.md](AGENT.md)
* **Handover Log:** [.agent/memory/session-handover.md](.agent/memory/session-handover.md)
* **Rules:** [.agent/rules/](.agent/rules/)

## 6. Development & Testing Workflow
* **Booting:** Start every session by reading AGENT.md and the memory files listed above.
* **Testing:** Prefer running tests explicitly. Avoid large automated commands if token budgets are a concern.

## 7. Limitations (Basic Tier)
* No hook automation -- sync and handover must be done manually.
* No multi-agent support.
* Safety rules are recommendations only, not enforced by the toolchain.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
EOF
fi

# Create specialized router files (guard: preserve manual edits)
if [ ! -s .cursorrules ]; then
cat << 'EOF' > .cursorrules
# AI Toolbox Protocol (Cursor) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF
fi

if [ ! -s .clinerules ]; then
cat << 'EOF' > .clinerules
# AI Toolbox Protocol (RooCode / Cline) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF
fi

if [ ! -s .windsurfrules ]; then
cat << 'EOF' > .windsurfrules
# AI Toolbox Protocol (Windsurf) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF
fi

# Full-Tier: Qwen Code CLI router (guard: preserve manual edits)
if [ -f ".agent/templates/clients/QWEN.md" ] && [ ! -s QWEN.md ]; then
    cp .agent/templates/clients/QWEN.md QWEN.md
    echo "[bootstrap] Installed QWEN.md (Full Tier)"
elif [ ! -s QWEN.md ]; then
cat << 'EOF' > QWEN.md
# AI Toolbox Protocol (Qwen Code) -- Tier: Full

This project uses the **AI Toolbox** workflow framework. As a **Full-Tier** client, you have access to all features: hooks, multi-agent orchestration, plan mode, and sync automation.

## Critical Session Rules

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
2. **SAFETY:** All heavy terminal commands (builds, tests, package installs) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

## Full-Tier Features Available

- **Hooks:** Pre/post-command hooks auto-sync state and enforce safety rules.
- **Multi-Agent:** Spawn sub-agents for parallel task execution. Coordinate via `.agent/memory/`.
- **Plan Mode:** Use plan mode before major changes. Document in `.agent/memory/current-task.md`.
- **Sync:** Run `.agent/scripts/sync-task.sh` (or `.ps1`) to refresh your task view at any time.

## Memory Layer

Read these files at session start (in order):
1. `.agent/memory/architecture-decisions.md` -- ADR log
2. `.agent/memory/integration-contracts.md` -- API/schema contracts
3. `.agent/memory/session-handover.md` -- Unfinished work from last session
4. `.agent/memory/current-task.md` -- Active todo list
5. `.agent/memory/runbook.md` -- Operational procedures (if present)

Refer to [AGENT.md](AGENT.md) for the full operational contract.
EOF
fi

# Basic-Tier: Aider router + config (guard: preserve manual edits)
if [ -f ".agent/templates/clients/CONVENTIONS.md" ] && [ ! -s CONVENTIONS.md ]; then
    cp .agent/templates/clients/CONVENTIONS.md CONVENTIONS.md
    echo "[bootstrap] Installed CONVENTIONS.md (Basic Tier)"
elif [ ! -s CONVENTIONS.md ]; then
cat << 'EOF' > CONVENTIONS.md
# AI Toolbox Protocol (Aider) -- Tier: Basic

This project uses the **AI Toolbox** workflow framework. As a **Basic-Tier** client, you have access to the Memory Layer and Rules Layer. Hooks are not available -- all safety rules are soft reminders.

## Session Guidelines (Soft Reminders)

> **Note:** These are recommendations, not enforced guardrails. Please follow them to maintain project consistency.

1. **BOOT:** Before starting, read `.agent/memory/current-task.md` to understand the current task state.
2. **SAFETY:** Prefer safe, reversible operations. Avoid destructive commands without explicit user confirmation. Prefer `--dry-run` where available.
3. **HANDOVER:** Before finishing, update `.agent/memory/session-handover.md` with what was completed and what remains.

## Memory Layer

Please read these files at the start of your session:
- `.agent/memory/architecture-decisions.md` -- Architectural decisions log
- `.agent/memory/integration-contracts.md` -- API/schema contracts
- `.agent/memory/session-handover.md` -- Unfinished work from the last session
- `.agent/memory/current-task.md` -- Active todo list (Beads tracker)

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
EOF
fi

if [ -f ".agent/templates/clients/.aider.conf.yml" ] && [ ! -s .aider.conf.yml ]; then
    cp .agent/templates/clients/.aider.conf.yml .aider.conf.yml
    echo "[bootstrap] Installed .aider.conf.yml"
fi

if [ -d ".git" ] && [ "${AITB_INSTALL_GIT_HOOKS:-true}" != "false" ]; then
    echo "[bootstrap] Updating Git pre-commit safeguards..."
    NEEDS_UPDATE=0
    if [ ! -f .git/hooks/pre-commit ]; then
        NEEDS_UPDATE=1
    elif grep -q "AI Toolbox" .git/hooks/pre-commit 2>/dev/null; then
        # Our hook exists — check if it's the current version
        if ! grep -q "verify-commit.sh" .git/hooks/pre-commit 2>/dev/null; then
            NEEDS_UPDATE=1
        fi
    fi
    if [ "$NEEDS_UPDATE" -eq 1 ]; then
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# AI Toolbox Pre-commit wrapper
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.agent/scripts/verify-commit.sh" ]; then
    bash "$REPO_ROOT/.agent/scripts/verify-commit.sh"
fi
EOF
        echo "[bootstrap] Updated .git/hooks/pre-commit"
    fi
    chmod +x .git/hooks/pre-commit 2>/dev/null || true

    echo "[bootstrap] Updating Git commit-msg safeguards..."
    NEEDS_UPDATE=0
    if [ ! -f .git/hooks/commit-msg ]; then
        NEEDS_UPDATE=1
    elif grep -q "AI Toolbox" .git/hooks/commit-msg 2>/dev/null; then
        if ! grep -q "commit-msg.sh" .git/hooks/commit-msg 2>/dev/null; then
            NEEDS_UPDATE=1
        fi
    fi
    if [ "$NEEDS_UPDATE" -eq 1 ]; then
    cat << 'EOF' > .git/hooks/commit-msg
#!/bin/bash
# AI Toolbox Commit-Message wrapper
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.agent/scripts/commit-msg.sh" ]; then
    bash "$REPO_ROOT/.agent/scripts/commit-msg.sh" "$1"
fi
EOF
        echo "[bootstrap] Updated .git/hooks/commit-msg"
    fi
    chmod +x .git/hooks/commit-msg 2>/dev/null || true
fi


# Update .gitignore if needed
GITIGNORE=".gitignore"
if [ ! -f "$GITIGNORE" ]; then
    touch "$GITIGNORE"
fi

REQUIRED_IGNORES=(
    ".beads/"
    ".agent/memory/session-handover.md"
    ".agent/memory/current-task.md"
)

for ignore in "${REQUIRED_IGNORES[@]}"; do
    if ! grep -qxF "$ignore" "$GITIGNORE"; then
        printf '\n%s\n' "$ignore" >> "$GITIGNORE"
        echo "[bootstrap] Added $ignore to .gitignore"
    fi
done

chmod +x .agent/scripts/*.sh
echo "[bootstrap] checking for recommended developer tools..."
RECOMMENDED_TOOLS=("rtk" "bd" "bat" "rg")
for tool in "${RECOMMENDED_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "[bootstrap] Found $tool"
    else
        echo "[bootstrap] Recommended tool '$tool' not found. Visit https://github.com/mrAibo/AI_Toolbox for installation info."
    fi
done

# Fix 1: Prompt for rtk hooks if rtk is installed
if command -v rtk &> /dev/null; then
    echo "[bootstrap] rtk detected! To enable automatic hook interception, run: rtk init -g"
fi

# Configure Qwen Code hooks if qwen is available
QWEN_SETTINGS=".qwen/settings.json"
if command -v qwen &> /dev/null || [ -d ".qwen" ]; then
    mkdir -p .qwen
    if [ ! -f "$QWEN_SETTINGS" ]; then
        cat << 'QWENEOF' > "$QWEN_SETTINGS"
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "bash .agent/scripts/sync-task.sh", "name": "ai-toolbox-sync", "description": "Sync task state from tracker", "timeout": 15000}]}],
    "PreToolUse": [{"matcher": "^bash$", "hooks": [{"type": "command", "command": "bash .agent/scripts/hook-pre-command-qwen.sh", "name": "ai-toolbox-pre-command", "description": "Validate heavy commands", "timeout": 10000}]}],
    "PostToolUse": [
      {"matcher": "^write$", "hooks": [{"type": "command", "command": "bash .agent/scripts/hook-post-tool-qwen.sh", "name": "ai-toolbox-security-check", "description": "Scan written files for secrets", "timeout": 10000}]},
      {"matcher": "^edit$", "hooks": [{"type": "command", "command": "bash .agent/scripts/hook-post-tool-qwen.sh", "name": "ai-toolbox-security-check", "description": "Scan edited files for secrets", "timeout": 10000}]}
    ],
    "Stop": [{"hooks": [{"type": "command", "command": "bash .agent/scripts/hook-stop-qwen.sh", "name": "ai-toolbox-memory-update", "description": "Update memory before response", "timeout": 15000}]}],
    "SessionEnd": [{"hooks": [{"type": "command", "command": "bash .agent/scripts/hook-session-end-qwen.sh", "name": "ai-toolbox-session-handover", "description": "Consolidate memory at session end", "timeout": 30000}]}],
    "PreCompact": [{"hooks": [{"type": "command", "command": "bash .agent/scripts/hook-pre-compact-qwen.sh", "name": "ai-toolbox-architect-context", "description": "Inject architecture context", "timeout": 10000}]}]
  }
}
QWENEOF
        echo "[bootstrap] Created $QWEN_SETTINGS with AI Toolbox hooks"
    else
        echo "[bootstrap] $QWEN_SETTINGS already exists — skipping hook creation"
    fi
fi

# Configure OpenAI Codex CLI hooks if codex is available
CODEX_SETTINGS=".codex"
if command -v codex &>/dev/null || [ -d "$CODEX_SETTINGS" ]; then
    mkdir -p .codex
    if [ ! -f ".codex/hooks.json" ]; then
        if [ -f ".agent/templates/clients/.codex-hooks.json" ]; then
            cp .agent/templates/clients/.codex-hooks.json .codex/hooks.json
            echo "[bootstrap] Created .codex/hooks.json with AI Toolbox hooks"
        else
            echo "[bootstrap] Codex detected but .codex-hooks.json template not found"
        fi
    else
        echo "[bootstrap] .codex/hooks.json already exists — skipping hook creation"
    fi
    if [ ! -f ".codex/config.toml" ]; then
        if [ -f ".agent/templates/clients/.codex-config.toml" ]; then
            cp .agent/templates/clients/.codex-config.toml .codex/config.toml
            echo "[bootstrap] Created .codex/config.toml with AI Toolbox config"
        fi
    else
        echo "[bootstrap] .codex/config.toml already exists — skipping config creation"
    fi
    # Create CODERULES.md if not present (Codex router file)
    if [ ! -f "CODERULES.md" ]; then
        if [ -f ".agent/templates/clients/CODERULES.md" ]; then
            cp .agent/templates/clients/CODERULES.md CODERULES.md
            echo "[bootstrap] Created CODERULES.md (Codex router file)"
        fi
    fi
fi

# Configure OpenCode CLI if opencode is available
if command -v opencode &>/dev/null || [ -f "opencode.json" ] || [ -f "opencode.jsonc" ]; then
    # Create opencode.json if not present
    if [ ! -f "opencode.json" ] && [ ! -f "opencode.jsonc" ]; then
        if [ -f ".agent/templates/clients/opencode-config.json" ]; then
            cp .agent/templates/clients/opencode-config.json opencode.json
            echo "[bootstrap] Created opencode.json with AI Toolbox configuration"
        else
            echo "[bootstrap] OpenCode detected but opencode-config.json template not found"
        fi
    else
        echo "[bootstrap] opencode.json already exists — skipping config creation"
    fi
    # Create OPENCODERULES.md if not present
    if [ ! -f "OPENCODERULES.md" ]; then
        if [ -f ".agent/templates/clients/OPENCODERULES.md" ]; then
            cp .agent/templates/clients/OPENCODERULES.md OPENCODERULES.md
            echo "[bootstrap] Created OPENCODERULES.md (OpenCode router file)"
        fi
    fi
fi

echo "[bootstrap] structure ready"
