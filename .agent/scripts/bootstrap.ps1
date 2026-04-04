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

Set-Content -Path ".agent/memory/architecture-decisions.md" -Value "# Architecture Decision Records (ADRs)" -Encoding utf8
Set-Content -Path ".agent/memory/integration-contracts.md" -Value "# Integration Contracts" -Encoding utf8
Set-Content -Path ".agent/memory/session-handover.md" -Value "# Session Handover" -Encoding utf8
Set-Content -Path ".agent/memory/runbook.md" -Value "# Runbook" -Encoding utf8
Set-Content -Path ".agent/memory/current-task.md" -Value "# Current Task" -Encoding utf8

$SafetyContent = "# Safety Rules`r`nCore principle: Do not perform destructive, irreversible, or high-risk actions without explicit user intent.`r`n- Do not delete files or directories blindly.`r`n- Do not rewrite large parts of the repository silently.`r`n- Do not force-push or rewrite git history."
if (-not (Test-Path ".agent/rules/safety-rules.md") -or (Get-Item ".agent/rules/safety-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/safety-rules.md" -Value $SafetyContent -Encoding utf8
}

$TestingContent = "# Testing Rules`r`nCore principle: Do not claim completion without verification.`r`n- Run tests when tests exist.`r`n- Use the Bug Fix Sequence: Reproduce -> Identify -> Fix -> Verify -> Record.`r`n- Prefer concise test output via rtk."
if (-not (Test-Path ".agent/rules/testing-rules.md") -or (Get-Item ".agent/rules/testing-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/testing-rules.md" -Value $TestingContent -Encoding utf8
}

$StackContent = "# Stack Rules`r`n- Follow the project's established coding standards.`r`n- Prefer idiomatic solutions for the detected language/framework.`r`n- Document third-party library additions in .agent/memory/integration-contracts.md."
if (-not (Test-Path ".agent/rules/stack-rules.md") -or (Get-Item ".agent/rules/stack-rules.md").Length -eq 0) {
    Set-Content -Path ".agent/rules/stack-rules.md" -Value $StackContent -Encoding utf8
}

$AntigravityContent = "# Antigravity Environment Specifics`r`nUse native slash commands in .agent/workflows/ (/start, /plan, /sync, /handover).`r`nMaintain native artifacts: implementation_plan.md, task.md, walkthrough.md."
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

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run `.agent/scripts/sync-task.sh` before starting any task.
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
'@

$CursorContent = @'
# AI Toolbox Protocol (Cursor)

1. **BOOT:** Run `.agent/scripts/sync-task.sh` and read `.agent/memory/current-task.md` before starting.
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
* **Booting:** Start every session by reading AGENT.md and running `.agent/scripts/sync-task.sh`.
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
powershell.exe -ExecutionPolicy Bypass -File .agent/scripts/verify-commit.ps1
'@
    Set-Content -Path ".git/hooks/pre-commit" -Value $BashHook -Encoding utf8

    # 2. Batch wrapper (for native Windows CMD/Git)
    $BatchHook = @'
@echo off
powershell.exe -ExecutionPolicy Bypass -File .agent/scripts/verify-commit.ps1
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
