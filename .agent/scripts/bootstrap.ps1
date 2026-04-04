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

$SafetyContent = @'
# Safety Rules
Core principle: Do not perform destructive, irreversible, or high-risk actions without explicit user intent.

1. **No Blind Deletion:** Do not delete files or directories without verifying their content and importance.
2. **No Silent Rewrites:** Do not rewrite large parts of the repository silently or without a plan.
3. **Git Integrity:** Do not force-push or rewrite git history unless explicitly requested.
4. **Safety wrapper:** Always use `rtk` for heavy terminal operations to manage token usage and risk.
'@
if (-not (Test-Path ".agent/rules/safety-rules.md") -or (Get-Item ".agent/rules/safety-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/safety-rules.md" -Value $SafetyContent -Encoding utf8
}

$TestingContent = @'
# Testing Rules
Core principle: Do not claim completion without verification.

1. **Verify Always:** Run tests whenever they exist.
2. **Bug Fix Sequence:** Use Reproduce -> Identify -> Fix -> Verify -> Record.
3. **Red-Green-Refactor:** Ensure tests fail before they pass for new features.
4. **Tooling:** Prefer concise test output via `rtk` to avoid context flooding.
'@
if (-not (Test-Path ".agent/rules/testing-rules.md") -or (Get-Item ".agent/rules/testing-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/testing-rules.md" -Value $TestingContent -Encoding utf8
}

$StackContent = @'
# Stack Rules
- Follow the project's established coding standards (check `.editorconfig`, `.eslintrc`, etc.).
- Prefer idiomatic solutions for the detected language/framework.
- Document third-party library additions in `.agent/memory/integration-contracts.md`.
- Keep dependencies updated and minimize security vulnerabilities.
'@
if (-not (Test-Path ".agent/rules/stack-rules.md") -or (Get-Item ".agent/rules/stack-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/stack-rules.md" -Value $StackContent -Encoding utf8
}

$AntigravityContent = @'
# Antigravity Environment Specifics
Use native slash commands in `.agent/workflows/` (`/start`, `/plan`, `/sync`, `/handover`).
Maintain native artifacts: `implementation_plan.md`, `task.md`, `walkthrough.md`.
'@
if (-not (Test-Path ".agent/rules/antigravity.md") -or (Get-Item ".agent/rules/antigravity.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/antigravity.md" -Value $AntigravityContent -Encoding utf8
}

$RootFiles = @("README.md", "AGENT.md")
foreach ($RootFile in $RootFiles) {
    if (-not (Test-Path $RootFile)) { New-Item -ItemType File -Path $RootFile | Out-Null }
}

Write-Host "[bootstrap] creating AI auto-discovery router files..."

$ClaudeContent = @'
# AI Toolbox Protocol (Claude)

This project uses the **AI Toolbox** workflow. Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run the sync-task script (`.sh` on Unix, `.ps1` on Windows) before starting any task.
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@

$CursorContent = @'
# AI Toolbox Protocol (Cursor)

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
'@

$GeminiContent = @'
# GEMINI.MD: AI Collaboration Guide (AI Toolbox)

This document provides essential context for AI models interacting with this project.

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
* **Booting:** Start every session by reading AGENT.md and running the sync-task script (`.sh` on Unix, `.ps1` on Windows).
* **Testing:** All heavy commands MUST be run through `rtk`.

## 7. Specific Instructions for AI Collaboration
* **MANDATORY:** You MUST run the Boot Sequence defined in [AGENT.md](AGENT.md) before starting any task.
* **Handover:** Always update `.agent/memory/session-handover.md` at the end of a session.
* **Gemini CLI:** This project uses `GEMINI.md` as its primary context file. Read this file carefully to understand the repository structure.
'@

Set-Content -Path "CLAUDE.md" -Value $ClaudeContent -Encoding utf8
Set-Content -Path "GEMINI.md" -Value $GeminiContent -Encoding utf8
Set-Content -Path ".cursorrules" -Value $CursorContent -Encoding utf8
Set-Content -Path ".clinerules" -Value $CursorContent -Encoding utf8
Set-Content -Path ".windsurfrules" -Value $CursorContent -Encoding utf8

# Client-specific templates
$ClientDir = ".agent/templates/clients"
if (-not (Test-Path $ClientDir)) { New-Item -ItemType Directory -Path $ClientDir | Out-Null }
if (Test-Path "$ClientDir/.claude.json") {
    Copy-Item -Path "$ClientDir/.claude.json" -Destination ".claude.json" -Force
    Write-Host "[bootstrap] Installed .claude.json hooks"
}

if (Test-Path ".git") {
    Write-Host "[bootstrap] Updating Git pre-commit safeguards..."
    
    # 1. Bash wrapper (for Git Bash)
    $BashHook = @'
#!/bin/bash
# AI Toolbox Pre-commit wrapper (BASH)
REPO_ROOT="$(git rev-parse --show-toplevel)"
powershell.exe -ExecutionPolicy Bypass -File "$REPO_ROOT/.agent/scripts/verify-commit.ps1"
'@
    Set-Content -Path ".git/hooks/pre-commit" -Value $BashHook -Encoding utf8

    # 2. Batch wrapper (for native Windows CMD/Git)
    $BatchHook = @'
@echo off
REM AI Toolbox Pre-commit wrapper (BATCH)
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel') do set REPO_ROOT=%%i
powershell.exe -ExecutionPolicy Bypass -File "%REPO_ROOT%\.agent\scripts\verify-commit.ps1"
'@
    Set-Content -Path ".git/hooks/pre-commit.bat" -Value $BatchHook -Encoding utf8
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
