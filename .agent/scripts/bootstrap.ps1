# bootstrap.ps1 — AI Toolbox repo initialization (Windows)
# No $ErrorActionPreference = "Stop" — must be resilient; one failure must not kill the whole script.

Write-Host "[bootstrap] preparing AI Toolbox structure..."

$dirs = @(
  ".agent/rules",
  ".agent/memory",
  ".agent/templates",
  ".agent/scripts",
  ".agent/workflows",
  "docs",
  "examples",
  "prompts"
)

foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$Today = Get-Date -Format "yyyy-MM-dd"
$ADRContent = @"
# Architecture Decision Records (ADRs)

This file tracks major architectural decisions. Use the format from `` `../templates/adr-template.md`` `.

### ADR-0000: Use AI Toolbox for Repository Governance
- Status: accepted
- Date: $Today
- Context: Need a standardized, agent-agnostic way to maintain project memory and rules.
- Decision: Adopt AI Toolbox framework.
- Consequences: All agents must follow AGENT.md; memory is stored in .agent/.
- Rejected alternatives: Manual documentation, client-specific rules only.
"@

if (-not (Test-Path ".agent/memory/architecture-decisions.md") -or (Get-Item ".agent/memory/architecture-decisions.md").Length -eq 0) {
    Set-Content -Path ".agent/memory/architecture-decisions.md" -Value $ADRContent -Encoding utf8
}

$RunbookContent = @'
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
'@

if (-not (Test-Path ".agent/memory/runbook.md") -or (Get-Item ".agent/memory/runbook.md").Length -eq 0) {
    Set-Content -Path ".agent/memory/runbook.md" -Value $RunbookContent -Encoding utf8
}

if (-not (Test-Path ".agent/memory/active-session.md") -or (Get-Item ".agent/memory/active-session.md").Length -eq 0) {
    $ActiveSessionContent = @'
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
'@
    Set-Content -Path ".agent/memory/active-session.md" -Value $ActiveSessionContent -Encoding utf8
}

# Initialize tool usage tracking file
if (-not (Test-Path ".agent/memory/.tool-stats.json") -or (Get-Item ".agent/memory/.tool-stats.json").Length -eq 0) {
    Set-Content -Path ".agent/memory/.tool-stats.json" -Value '{"rtk": 0, "beads": 0, "mcp": 0}' -Encoding utf8
}

# Initialize memory index (READ FIRST during boot sequence)
if (-not (Test-Path ".agent/memory/memory-index.md") -or (Get-Item ".agent/memory/memory-index.md").Length -eq 0) {
    $MIContent = @'
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

'@
    Set-Content -Path ".agent/memory/memory-index.md" -Value $MIContent -Encoding utf8
}

if (-not (Test-Path ".agent/memory/integration-contracts.md") -or (Get-Item ".agent/memory/integration-contracts.md").Length -eq 0) {
    $ICContent = @'
# Integration Contracts

This file documents the contracts between different components, services, or third-party integrations (e.g. APIs, database schemas, library versions).

## Active Contracts
- [None yet]

## Potential Conflicts
- [None yet]
'@
    Set-Content -Path ".agent/memory/integration-contracts.md" -Value $ICContent -Encoding utf8
}

if (-not (Test-Path ".agent/memory/session-handover.md") -or (Get-Item ".agent/memory/session-handover.md").Length -eq 0) {
    Set-Content -Path ".agent/memory/session-handover.md" -Value @"
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
"@ -Encoding utf8
}

if (-not (Test-Path ".agent/memory/current-task.md") -or (Get-Item ".agent/memory/current-task.md").Length -eq 0) {
    $TaskTemplate = @"
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
"@
    Set-Content -Path ".agent/memory/current-task.md" -Value $TaskTemplate -Encoding utf8
}

$SafetyContent = @'
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

## Change scope rule

Keep changes as small and local as possible.

Avoid broad rewrites when a focused change is enough.
Do not refactor unrelated parts of the system during a targeted fix unless the user asks for it.

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

If a task has real risk, communicate the risk before proceeding.

Examples:
- destructive migrations
- removing compatibility layers
- changing public interfaces
- replacing a key dependency
'@
if (-not (Test-Path ".agent/rules/safety-rules.md") -or (Get-Item ".agent/rules/safety-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/safety-rules.md" -Value $SafetyContent -Encoding utf8
}

$TestingContent = @'
# Testing Rules

This file defines how work must be verified before it is considered complete.

The purpose is to prevent false completion, unverified assumptions, and silent regressions.

---

## Core rule

Do not claim that something works unless it has been checked.

Verification is mandatory.
If something cannot be verified, state that clearly.

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

## Reporting rule

When reporting completion, mention:
- what was changed
- how it was verified
- what is still uncertain, if anything
'@
if (-not (Test-Path ".agent/rules/testing-rules.md") -or (Get-Item ".agent/rules/testing-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/testing-rules.md" -Value $TestingContent -Encoding utf8
}

$StackContent = @'
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
'@
if (-not (Test-Path ".agent/rules/stack-rules.md") -or (Get-Item ".agent/rules/stack-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/stack-rules.md" -Value $StackContent -Encoding utf8
}

$AntigravityContent = @'
# Antigravity Environment Specifics

This file defines how to work with the **AI Toolbox** when using the **Antigravity** assistant environment.

---

## [NEXT] Native Workflows (Slash Commands)

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
'@
if (-not (Test-Path ".agent/rules/antigravity.md") -or (Get-Item ".agent/rules/antigravity.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/antigravity.md" -Value $AntigravityContent -Encoding utf8
}

$QwenCodeContent = @'
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
'@
if (-not (Test-Path ".agent/rules/qwen-code.md") -or (Get-Item ".agent/rules/qwen-code.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/qwen-code.md" -Value $QwenCodeContent -Encoding utf8
}

# TDD Rules
$TddContent = @'
# TDD Rules

**When TDD is mandatory:** For all code changes.
**Cycle:** RED → GREEN → REFACTOR. Never write production code without a failing test.
- Write the smallest failing test first
- Make it pass with the simplest possible code
- Refactor only when tests are green
- Run tests via `rtk test` after every change

See also: [testing-rules.md](testing-rules.md)
'@
if (-not (Test-Path ".agent/rules/tdd-rules.md") -or (Get-Item ".agent/rules/tdd-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/tdd-rules.md" -Value $TddContent -Encoding utf8
}

# MCP Server Rules
$McpContent = @'
# MCP Server Rules

**Before connecting:** Verify server identity and auth requirements.
**During sessions:** Log all tool calls, handle errors gracefully.
**After sessions:** Document which servers were used and what was accomplished.
- Never expose secrets in tool output
- Validate tool responses before passing to the model
- Use MCP only when local skills are insufficient

See also: [integration-contracts.md](../memory/integration-contracts.md)
'@
if (-not (Test-Path ".agent/rules/mcp-rules.md") -or (Get-Item ".agent/rules/mcp-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/mcp-rules.md" -Value $McpContent -Encoding utf8
}

# Status Reporting Rules
$StatusContent = @'
# Status Reporting Rules

**Report at these moments:**
1. Step transitions (unified workflow steps)
2. Skill activation (which rule/workflow was triggered)
3. Tool usage (rtk, beads, MCP calls)
4. Multi-agent spawn/complete
5. Errors/blockers

**Status file format:** Update `.agent/memory/active-session.md` with current step, active skills/tools, multi-agent status.
**Session end:** Write summary to `.agent/memory/session-handover.md`.
'@
if (-not (Test-Path ".agent/rules/status-reporting.md") -or (Get-Item ".agent/rules/status-reporting.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/status-reporting.md" -Value $StatusContent -Encoding utf8
}

# Template Usage Rules
$TemplateContent = @'
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
'@
if (-not (Test-Path ".agent/rules/template-usage.md") -or (Get-Item ".agent/rules/template-usage.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/template-usage.md" -Value $TemplateContent -Encoding utf8
}

# Tool Integration Guide
$ToolIntContent = @'
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
'@
if (-not (Test-Path ".agent/rules/tool-integrations.md") -or (Get-Item ".agent/rules/tool-integrations.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/tool-integrations.md" -Value $ToolIntContent -Encoding utf8
}

Write-Host "[bootstrap] creating AI auto-discovery router files..."

$ClaudeContent = @'
# AI Toolbox Protocol (Claude Code) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

This project uses the **AI Toolbox** workflow. As a **Full-Tier** client you have access to hooks, multi-agent orchestration, and plan mode.

Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@

$CursorContent = @'
# AI Toolbox Protocol (Cursor) -- Tier: Standard
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$ClineContent = @'
# AI Toolbox Protocol (RooCode / Cline) -- Tier: Standard
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$WindsurfContent = @'
# AI Toolbox Protocol (Windsurf) -- Tier: Standard
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$GeminiContent = @'
# AI Toolbox Protocol (Gemini CLI) -- Tier: Basic
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

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
'@

$PiContent = @'
# AI Toolbox Protocol (Pi by Inflection) -- Tier: Basic
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

> **Tier Note:** Pi is a Basic-Tier client. It is a web-based chat interface with no CLI,
> no config file, and no hook support. All safety rules below are **soft reminders**, not enforced guardrails.

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
* No CLI integration -- paste relevant context (this file, memory files) into the Pi chat manually.
* Safety rules are recommendations only, not enforced by the toolchain.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@

# Write router files (guard: only create if not already present)
# NOTE: CLAUDE.md is a committed file — the guard ensures we don't overwrite manual edits
if (-not (Test-Path "CLAUDE.md") -or (Get-Item "CLAUDE.md").Length -eq 0) {
    Set-Content -Path "CLAUDE.md" -Value $ClaudeContent -Encoding utf8
}
if (-not (Test-Path "GEMINI.md") -or (Get-Item "GEMINI.md").Length -eq 0) {
    Set-Content -Path "GEMINI.md" -Value $GeminiContent -Encoding utf8
}
if (-not (Test-Path "PI.md") -or (Get-Item "PI.md").Length -eq 0) {
    Set-Content -Path "PI.md" -Value $PiContent -Encoding utf8
}
# Standard-Tier routers: guard to preserve manual edits
if (-not (Test-Path ".cursorrules") -or (Get-Item ".cursorrules").Length -eq 0) {
    Set-Content -Path ".cursorrules"   -Value $CursorContent   -Encoding utf8
}
if (-not (Test-Path ".clinerules") -or (Get-Item ".clinerules").Length -eq 0) {
    Set-Content -Path ".clinerules"    -Value $ClineContent    -Encoding utf8
}
if (-not (Test-Path ".windsurfrules") -or (Get-Item ".windsurfrules").Length -eq 0) {
    Set-Content -Path ".windsurfrules" -Value $WindsurfContent -Encoding utf8
}

# Antigravity router (SKILL.md — Full Tier) — guard: preserve manual edits
if (-not (Test-Path "SKILL.md") -or (Get-Item "SKILL.md").Length -eq 0) {
    $SkillContent = @'
---
name: AI Toolbox
description: A strict, memory-backed agentic development framework for terminal-based AIs. (Antigravity Manifest)
---

# AI Toolbox Skill (Antigravity Manifest) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

> This file is the manifest for the **Antigravity** agentic framework.
> For Claude Code, Cursor, or other agents refer to their router files or AGENT.md.

Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script before starting any task.
2. **SAFETY:** All heavy terminal commands MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@
    Set-Content -Path "SKILL.md" -Value $SkillContent -Encoding utf8
    Write-Host "[bootstrap] Created SKILL.md (Antigravity Full-Tier router)"
}

# Qwen Code router (Full Tier) — guard: preserve manual edits (inline only, no template dependency)
if (-not (Test-Path "QWEN.md") -or (Get-Item "QWEN.md").Length -eq 0) {
    $QwenFull = @'
# AI Toolbox Protocol (Qwen Code) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

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

> Boot order: see [memory-index.md](.agent/memory/memory-index.md) — it lists all memory files in priority order.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@
    Set-Content -Path "QWEN.md" -Value $QwenFull -Encoding utf8
}

# Aider router (Basic Tier) — inline only, no template dependency
if (-not (Test-Path "CONVENTIONS.md") -or (Get-Item "CONVENTIONS.md").Length -eq 0) {
    $AiderFull = @'
# AI Toolbox Protocol (Aider) -- Tier: Basic
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

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
'@
    Set-Content -Path "CONVENTIONS.md" -Value $AiderFull -Encoding utf8
}
# Aider config file — inline fallback
if (-not (Test-Path ".aider.conf.yml") -or (Get-Item ".aider.conf.yml").Length -eq 0) {
    $AiderConf = @'
# Aider configuration -- AI Toolbox project
model: null
read:
  - AGENT.md
  - .agent/rules/safety-rules.md
  - .agent/rules/testing-rules.md
  - .agent/rules/stack-rules.md
auto-commits: true
'@
    Set-Content -Path ".aider.conf.yml" -Value $AiderConf -Encoding utf8
}

# Claude hooks config — inline fallback
if (-not (Test-Path ".claude.json") -or (Get-Item ".claude.json").Length -eq 0) {
    $ClaudeHooks = @'
{
  "hooks": {
    "pre-command": [
      "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1 \"$COMMAND\""
    ],
    "post-command": [
      "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1"
    ]
  }
}
'@
    Set-Content -Path ".claude.json" -Value $ClaudeHooks -Encoding utf8
}

if ((Test-Path ".git") -and ($env:AITB_INSTALL_GIT_HOOKS -ne "false")) {
    Write-Host "[bootstrap] Updating Git pre-commit safeguards..."

    # 1. Bash wrapper (for Git Bash / Linux / macOS)
    $NeedsUpdate = $false
    if (-not (Test-Path ".git/hooks/pre-commit")) {
        $NeedsUpdate = $true
    } elseif (Select-String -Path ".git/hooks/pre-commit" -Pattern "AI Toolbox" -Quiet -ErrorAction SilentlyContinue) {
        # Our hook exists — check if it references current scripts
        if (-not (Select-String -Path ".git/hooks/pre-commit" -Pattern "verify-commit\.sh" -Quiet -ErrorAction SilentlyContinue)) {
            $NeedsUpdate = $true
        }
    }
    if ($NeedsUpdate) {
        $BashHook = @'
#!/bin/bash
# AI Toolbox Pre-commit wrapper (BASH)
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.agent/scripts/verify-commit.sh" ]; then
    bash "$REPO_ROOT/.agent/scripts/verify-commit.sh"
fi
'@
        Set-Content -Path ".git/hooks/pre-commit" -Value $BashHook -Encoding utf8
        Write-Host "[bootstrap] Updated .git/hooks/pre-commit"
    }

    # 2. Batch wrapper (for native Windows CMD/Git)
    $NeedsUpdate = $false
    if (-not (Test-Path ".git/hooks/pre-commit.bat")) {
        $NeedsUpdate = $true
    } elseif (Select-String -Path ".git/hooks/pre-commit.bat" -Pattern "AI Toolbox" -Quiet -ErrorAction SilentlyContinue) {
        if (-not (Select-String -Path ".git/hooks/pre-commit.bat" -Pattern "verify-commit\.ps1" -Quiet -ErrorAction SilentlyContinue)) {
            $NeedsUpdate = $true
        }
    }
    if ($NeedsUpdate) {
        $BatchHook = @'
@echo off
REM AI Toolbox Pre-commit wrapper (BATCH)
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel') do set REPO_ROOT=%%i
if exist "%REPO_ROOT%\.agent\scripts\verify-commit.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File "%REPO_ROOT%\.agent\scripts\verify-commit.ps1"
)
'@
        Set-Content -Path ".git/hooks/pre-commit.bat" -Value $BatchHook -Encoding utf8
        Write-Host "[bootstrap] Updated .git/hooks/pre-commit.bat"
    }

    # Commit-msg hook — bash wrapper
    $NeedsUpdate = $false
    if (-not (Test-Path ".git/hooks/commit-msg")) {
        $NeedsUpdate = $true
    } elseif (Select-String -Path ".git/hooks/commit-msg" -Pattern "AI Toolbox" -Quiet -ErrorAction SilentlyContinue) {
        if (-not (Select-String -Path ".git/hooks/commit-msg" -Pattern "commit-msg\.sh" -Quiet -ErrorAction SilentlyContinue)) {
            $NeedsUpdate = $true
        }
    }
    if ($NeedsUpdate) {
        $CommitMsgBash = @'
#!/bin/bash
# AI Toolbox Commit-Message wrapper (BASH)
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.agent/scripts/commit-msg.sh" ]; then
    bash "$REPO_ROOT/.agent/scripts/commit-msg.sh" "$1"
fi
'@
        Set-Content -Path ".git/hooks/commit-msg" -Value $CommitMsgBash -Encoding utf8
        Write-Host "[bootstrap] Updated .git/hooks/commit-msg"
    }

    # Commit-msg hook — batch wrapper
    $NeedsUpdate = $false
    if (-not (Test-Path ".git/hooks/commit-msg.bat")) {
        $NeedsUpdate = $true
    } elseif (Select-String -Path ".git/hooks/commit-msg.bat" -Pattern "AI Toolbox" -Quiet -ErrorAction SilentlyContinue) {
        if (-not (Select-String -Path ".git/hooks/commit-msg.bat" -Pattern "commit-msg\.ps1" -Quiet -ErrorAction SilentlyContinue)) {
            $NeedsUpdate = $true
        }
    }
    if ($NeedsUpdate) {
        $CommitMsgBatch = @'
@echo off
REM AI Toolbox Commit-Message wrapper (BATCH)
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel') do set REPO_ROOT=%%i
if exist "%REPO_ROOT%\.agent\scripts\commit-msg.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File "%REPO_ROOT%\.agent\scripts\commit-msg.ps1" "%%1"
)
'@
        Set-Content -Path ".git/hooks/commit-msg.bat" -Value $CommitMsgBatch -Encoding utf8
        Write-Host "[bootstrap] Updated .git/hooks/commit-msg.bat"
    }
}


# Update .gitignore if needed
$GitignoreFile = ".gitignore"
if (-not (Test-Path $GitignoreFile)) {
    New-Item -ItemType File -Path $GitignoreFile | Out-Null
}

$RequiredIgnores = @(
    ".beads/",
    ".agent/memory/session-handover.md",
    ".agent/memory/current-task.md",
    ".agent/memory/.tool-stats.json"
)

$ExistingIgnores = Get-Content $GitignoreFile -ErrorAction SilentlyContinue
foreach ($Ignore in $RequiredIgnores) {
    if ($ExistingIgnores -notcontains $Ignore) {
        Add-Content -Path $GitignoreFile -Value "`n$Ignore"
        Write-Host "[bootstrap] Added $Ignore to .gitignore"
    }
}

Write-Host "[bootstrap] checking for recommended developer tools..."
$RecommendedTools = @("rtk", "bd", "bat", "rg")
foreach ($Tool in $RecommendedTools) {
    if (Get-Command $Tool -ErrorAction SilentlyContinue) {
        Write-Host "[bootstrap] Found $Tool"
    } else {
        Write-Host "[bootstrap] Recommended tool '$Tool' not found. Visit https://github.com/mrAibo/AI_Toolbox for installation info."
    }
}

# Fix 1: Prompt for rtk hooks if rtk is installed
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    Write-Host "[bootstrap] rtk detected! To enable automatic hook interception, run: rtk init -g" -ForegroundColor Yellow
}

# Configure Qwen Code hooks if qwen is available
$QwenSettings = ".qwen/settings.json"
if ((Get-Command qwen -ErrorAction SilentlyContinue) -or (Test-Path ".qwen")) {
    New-Item -ItemType Directory -Force -Path ".qwen" | Out-Null
    $QwenHooksJson = @'
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1", "name": "ai-toolbox-sync", "description": "Sync task state from tracker", "timeout": 15000}]}],
    "PreToolUse": [{"matcher": "^bash$", "hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command-ps1-qwen.ps1", "name": "ai-toolbox-pre-command", "description": "Validate heavy commands", "timeout": 10000}]}],
    "PostToolUse": [
      {"matcher": "^write$", "hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-post-tool-ps1-qwen.ps1", "name": "ai-toolbox-security-check", "description": "Scan written files for secrets", "timeout": 10000}]},
      {"matcher": "^edit$", "hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-post-tool-ps1-qwen.ps1", "name": "ai-toolbox-security-check", "description": "Scan edited files for secrets", "timeout": 10000}]}
    ],
    "Stop": [{"hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop-ps1-qwen.ps1", "name": "ai-toolbox-memory-update", "description": "Update memory before response", "timeout": 15000}]}],
    "SessionEnd": [{"hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-session-end-ps1-qwen.ps1", "name": "ai-toolbox-session-handover", "description": "Consolidate memory at session end", "timeout": 30000}]}],
    "PreCompact": [{"hooks": [{"type": "command", "command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-compact-ps1-qwen.ps1", "name": "ai-toolbox-architect-context", "description": "Inject architecture context", "timeout": 10000}]}]
  }
}
'@
    if (-not (Test-Path $QwenSettings)) {
        $QwenHooksJson | Set-Content -Path $QwenSettings -Encoding utf8
        Write-Host "[bootstrap] Created $QwenSettings with AI Toolbox hooks"
    } else {
        # Merge: add missing AI Toolbox hooks without overwriting existing Qwen config
        try {
            $existing = Get-Content $QwenSettings -Raw | ConvertFrom-Json
            if (($existing | ConvertTo-Json -Depth 10) -match 'ai-toolbox-sync') {
                Write-Host "[bootstrap] $QwenSettings already has AI Toolbox hooks — no changes"
            } else {
                $template = $QwenHooksJson | ConvertFrom-Json
                if (-not ($existing.PSObject.Properties.Name -contains 'hooks')) {
                    $existing | Add-Member -MemberType NoteProperty -Name 'hooks' -Value $template.hooks -Force
                } else {
                    foreach ($prop in $template.hooks.PSObject.Properties) {
                        if (-not ($existing.hooks.PSObject.Properties.Name -contains $prop.Name)) {
                            $existing.hooks | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                        }
                    }
                }
                $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $QwenSettings -Encoding utf8
                Write-Host "[bootstrap] Merged AI Toolbox hooks into $QwenSettings" -ForegroundColor Green
            }
        } catch {
            Write-Host "[bootstrap] Could not merge hooks into $QwenSettings`: $_" -ForegroundColor Yellow
        }
    }
}

# Configure OpenAI Codex CLI hooks if codex is available
$CodexSettings = ".codex"
if ((Get-Command codex -ErrorAction SilentlyContinue) -or (Test-Path $CodexSettings)) {
    New-Item -ItemType Directory -Force -Path ".codex" | Out-Null
    if (-not (Test-Path ".codex/hooks.json")) {
        if (Test-Path ".agent/templates/clients/.codex-hooks.json") {
            Copy-Item -Path ".agent/templates/clients/.codex-hooks.json" -Destination ".codex/hooks.json"
            Write-Host "[bootstrap] Created .codex/hooks.json with AI Toolbox hooks"
        } else {
            Write-Host "[bootstrap] Codex detected but .codex-hooks.json template not found"
        }
    } else {
        # Merge: add missing AI Toolbox hooks if marker absent
        try {
            $codexContent = Get-Content ".codex/hooks.json" -Raw
            if ($codexContent -match 'ai-toolbox-sync') {
                Write-Host "[bootstrap] .codex/hooks.json already has AI Toolbox hooks — no changes"
            } elseif (Test-Path ".agent/templates/clients/.codex-hooks.json") {
                $ex = $codexContent | ConvertFrom-Json
                $tpl = Get-Content ".agent/templates/clients/.codex-hooks.json" -Raw | ConvertFrom-Json
                foreach ($prop in $tpl.PSObject.Properties) {
                    if (-not ($ex.PSObject.Properties.Name -contains $prop.Name)) {
                        $ex | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                    }
                }
                $ex | ConvertTo-Json -Depth 10 | Set-Content ".codex/hooks.json" -Encoding utf8
                Write-Host "[bootstrap] Merged AI Toolbox hooks into .codex/hooks.json" -ForegroundColor Green
            }
        } catch {
            Write-Host "[bootstrap] Could not merge into .codex/hooks.json: $_" -ForegroundColor Yellow
        }
    }
    if (-not (Test-Path ".codex/config.toml")) {
        if (Test-Path ".agent/templates/clients/.codex-config.toml") {
            Copy-Item -Path ".agent/templates/clients/.codex-config.toml" -Destination ".codex/config.toml"
            Write-Host "[bootstrap] Created .codex/config.toml with AI Toolbox config"
        }
    } else {
        Write-Host "[bootstrap] .codex/config.toml already exists — skipping config creation"
    }
    # Create CODERULES.md if not present (Codex router file)
    if (-not (Test-Path "CODERULES.md")) {
        if (Test-Path ".agent/templates/clients/CODERULES.md") {
            Copy-Item -Path ".agent/templates/clients/CODERULES.md" -Destination "CODERULES.md"
            Write-Host "[bootstrap] Created CODERULES.md (Codex router file)"
        }
    }
}

# Configure OpenCode CLI if opencode is available
if ((Get-Command opencode -ErrorAction SilentlyContinue) -or (Test-Path "opencode.json") -or (Test-Path "opencode.jsonc")) {
    if (-not (Test-Path "opencode.json") -and -not (Test-Path "opencode.jsonc")) {
        if (Test-Path ".agent/templates/clients/opencode-config.json") {
            Copy-Item -Path ".agent/templates/clients/opencode-config.json" -Destination "opencode.json"
            Write-Host "[bootstrap] Created opencode.json with AI Toolbox configuration"
        } else {
            Write-Host "[bootstrap] OpenCode detected but opencode-config.json template not found"
        }
    } else {
        # Merge: add missing AI Toolbox top-level keys without overwriting existing OpenCode config
        try {
            $ocPath = if (Test-Path "opencode.json") { "opencode.json" } else { "opencode.jsonc" }
            $ocContent = Get-Content $ocPath -Raw
            if ($ocContent -match 'ai-toolbox') {
                Write-Host "[bootstrap] $ocPath already has AI Toolbox config — no changes"
            } elseif (Test-Path ".agent/templates/clients/opencode-config.json") {
                $ex = $ocContent | ConvertFrom-Json
                $tpl = Get-Content ".agent/templates/clients/opencode-config.json" -Raw | ConvertFrom-Json
                $added = @()
                foreach ($prop in $tpl.PSObject.Properties) {
                    if (-not ($ex.PSObject.Properties.Name -contains $prop.Name)) {
                        $ex | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                        $added += $prop.Name
                    }
                }
                if ($added.Count -gt 0) {
                    $ex | ConvertTo-Json -Depth 10 | Set-Content $ocPath -Encoding utf8
                    Write-Host "[bootstrap] Merged AI Toolbox config into $ocPath ($($added -join ', '))" -ForegroundColor Green
                } else {
                    Write-Host "[bootstrap] $ocPath already has all AI Toolbox keys — no changes"
                }
            }
        } catch {
            Write-Host "[bootstrap] Could not merge into opencode.json: $_" -ForegroundColor Yellow
        }
    }
    # Create OPENCODERULES.md if not present
    if (-not (Test-Path "OPENCODERULES.md")) {
        if (Test-Path ".agent/templates/clients/OPENCODERULES.md") {
            Copy-Item -Path ".agent/templates/clients/OPENCODERULES.md" -Destination "OPENCODERULES.md"
            Write-Host "[bootstrap] Created OPENCODERULES.md (OpenCode router file)"
        }
    }
}

Write-Host "[bootstrap] structure ready"

