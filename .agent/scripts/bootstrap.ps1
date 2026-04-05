$ErrorActionPreference = "Stop"

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

This file tracks major architectural decisions. Use the format from `.agent/templates/adr-template.md`.

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
- Use `rtk` for heavy test/build commands where available (e.g. `rtk run "npm test"`)
- Avoid raw long log dumps into model context

## 4. Memory maintenance
- Record architecture changes in `architecture-decisions.md`
- Record integration expectations in `integration-contracts.md`
- Record current unfinished state in `session-handover.md`
'@

if (-not (Test-Path ".agent/memory/runbook.md") -or (Get-Item ".agent/memory/runbook.md").Length -eq 0) {
    Set-Content -Path ".agent/memory/runbook.md" -Value $RunbookContent -Encoding utf8
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
    Set-Content -Path ".agent/memory/session-handover.md" -Value "# Session Handover" -Encoding utf8
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

Write-Host "[bootstrap] creating AI auto-discovery router files..."

$ClaudeContent = @'
# AI Toolbox Protocol (Claude Code) -- Tier: Full

This project uses the **AI Toolbox** workflow. As a **Full-Tier** client you have access to hooks, multi-agent orchestration, and plan mode.

Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@

$CursorContent = @'
# AI Toolbox Protocol (Cursor) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$ClineContent = @'
# AI Toolbox Protocol (RooCode / Cline) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$WindsurfContent = @'
# AI Toolbox Protocol (Windsurf) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$GeminiContent = @'
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
'@

# Write router files (guard: only create if not already present)
# NOTE: CLAUDE.md is a committed file — the guard ensures we don't overwrite manual edits
if (-not (Test-Path "CLAUDE.md") -or (Get-Item "CLAUDE.md").Length -eq 0) {
    Set-Content -Path "CLAUDE.md" -Value $ClaudeContent -Encoding utf8
}
if (-not (Test-Path "GEMINI.md") -or (Get-Item "GEMINI.md").Length -eq 0) {
    Set-Content -Path "GEMINI.md" -Value $GeminiContent -Encoding utf8
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

# Qwen Code router (Full Tier) — guard: preserve manual edits
$ClientDir = ".agent/templates/clients"
if ((Test-Path "$ClientDir/QWEN.md") -and (-not (Test-Path "QWEN.md") -or (Get-Item "QWEN.md").Length -eq 0)) {
    Copy-Item -Path "$ClientDir/QWEN.md" -Destination "QWEN.md" -Force
    Write-Host "[bootstrap] Installed QWEN.md (Full Tier)"
} elseif (-not (Test-Path "QWEN.md") -or (Get-Item "QWEN.md").Length -eq 0) {
    $QwenFull = @'
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
'@
    Set-Content -Path "QWEN.md" -Value $QwenFull -Encoding utf8
}

# Aider router + config (Basic Tier) — guard: preserve manual edits
if ((Test-Path "$ClientDir/CONVENTIONS.md") -and (-not (Test-Path "CONVENTIONS.md") -or (Get-Item "CONVENTIONS.md").Length -eq 0)) {
    Copy-Item -Path "$ClientDir/CONVENTIONS.md" -Destination "CONVENTIONS.md" -Force
    Write-Host "[bootstrap] Installed CONVENTIONS.md (Basic Tier)"
} elseif (-not (Test-Path "CONVENTIONS.md") -or (Get-Item "CONVENTIONS.md").Length -eq 0) {
    $AiderFull = @'
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
'@
    Set-Content -Path "CONVENTIONS.md" -Value $AiderFull -Encoding utf8
}
if ((Test-Path "$ClientDir/.aider.conf.yml") -and (-not (Test-Path ".aider.conf.yml") -or (Get-Item ".aider.conf.yml").Length -eq 0)) {
    Copy-Item -Path "$ClientDir/.aider.conf.yml" -Destination ".aider.conf.yml" -Force
    Write-Host "[bootstrap] Installed .aider.conf.yml"
}

# Client-specific templates (guard: preserve manual edits)
if ((Test-Path "$ClientDir/.claude.json") -and (-not (Test-Path ".claude.json") -or (Get-Item ".claude.json").Length -eq 0)) {
    Copy-Item -Path "$ClientDir/.claude.json" -Destination ".claude.json" -Force
    Write-Host "[bootstrap] Installed .claude.json hooks"
}

if (Test-Path ".git") {
    Write-Host "[bootstrap] Updating Git pre-commit safeguards..."

    # Only write hooks if they don't already exist (preserve manual customizations)
    if (-not (Test-Path ".git/hooks/pre-commit") -or (Get-Item ".git/hooks/pre-commit").Length -eq 0) {
        # 1. Bash wrapper (for Git Bash)
        $BashHook = @'
#!/bin/bash
# AI Toolbox Pre-commit wrapper (BASH)
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.agent/scripts/verify-commit.ps1" ]; then
    powershell.exe -ExecutionPolicy Bypass -File "$REPO_ROOT/.agent/scripts/verify-commit.ps1"
fi
'@
        Set-Content -Path ".git/hooks/pre-commit" -Value $BashHook -Encoding utf8
    }

    if (-not (Test-Path ".git/hooks/pre-commit.bat") -or (Get-Item ".git/hooks/pre-commit.bat").Length -eq 0) {
        # 2. Batch wrapper (for native Windows CMD/Git)
        $BatchHook = @'
@echo off
REM AI Toolbox Pre-commit wrapper (BATCH)
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel') do set REPO_ROOT=%%i
if exist "%REPO_ROOT%\.agent\scripts\verify-commit.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File "%REPO_ROOT%\.agent\scripts\verify-commit.ps1"
)
'@
        Set-Content -Path ".git/hooks/pre-commit.bat" -Value $BatchHook -Encoding utf8
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
    ".agent/memory/current-task.md"
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

Write-Host "[bootstrap] structure ready"
