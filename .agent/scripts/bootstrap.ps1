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

$files = @(
  "README.md",
  "AGENT.md",
  ".agent/memory/architecture-decisions.md",
  ".agent/memory/integration-contracts.md",
  ".agent/memory/session-handover.md",
  ".agent/memory/runbook.md",
  ".agent/memory/current-task.md",
  ".agent/rules/stack-rules.md",
  ".agent/rules/testing-rules.md",
  ".agent/rules/safety-rules.md"
)

foreach ($file in $files) {
  if (-not (Test-Path $file)) {
    New-Item -ItemType File -Path $file | Out-Null
  }
}

Write-Host "[bootstrap] creating AI auto-discovery router files..."
$RouterContent = @"
# AI Toolbox Workflow

Please refer strictly to [AGENT.md](AGENT.md) for the universal project guidelines, rules, and memory contracts. 
Do not begin any work or code without reading and following the Boot Sequence in AGENT.md!
"@

$GeminiContent = @"
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
* **Memory Management:** Repository-based project memory in \`.agent/memory/\`.
* **Decision Tracking:** Architecture Decision Records (ADRs) in \`.agent/memory/architecture-decisions.md\`.

## 4. Coding Conventions & Style Guide
* **Workflow Rule:** Follow the [AGENT.md](AGENT.md) Boot Sequence.
* **Naming:** [Inferred: Standard kebab-case for files, camelCase for variables]

## 5. Key Files & Entrypoints
* **Main Contract:** [AGENT.md](AGENT.md)
* **Handover Log:** [.agent/memory/session-handover.md](.agent/memory/session-handover.md)
* **Rules:** [.agent/rules/](.agent/rules/)

## 6. Development & Testing Workflow
* **Booting:** Start every session by reading AGENT.md and running \`.agent/scripts/sync-task.sh\`.
* **Testing:** All heavy commands MUST be run through \`rtk\`.

## 7. Specific Instructions for AI Collaboration
* **MANDATORY:** You MUST run the Boot Sequence defined in [AGENT.md](AGENT.md) before starting any task.
* **Handover:** Always update \`.agent/memory/session-handover.md\` at the end of a session.
* **Native Workflows:** Use Antigravity slash commands in \`.agent/workflows/\` (/start, /sync, /handover)."
"@

$AgentFiles = @("CLAUDE.md", ".clinerules", ".cursorrules", ".windsurfrules")
foreach ($AgentFile in $AgentFiles) {
    Set-Content -Path $AgentFile -Value $RouterContent -Encoding utf8
}
Set-Content -Path "GEMINI.md" -Value $GeminiContent -Encoding utf8

if ((Test-Path ".git") -and -not (Test-Path ".git/hooks/pre-commit")) {
    Write-Host "[bootstrap] Installing Git pre-commit safeguards..."
    $HookContent = @"
#!/bin/bash
# AI Toolbox Pre-commit hook

HANDOVER_FILE=".agent/memory/session-handover.md"

if [ -f "`$HANDOVER_FILE" ]; then
    if [ ! -s "`$HANDOVER_FILE" ]; then
        echo "🚨 AI Toolbox Block: session-handover.md is empty!"
        echo "Please update handover notes before committing your work to preserve context."
        exit 1
    fi
fi
exit 0
"@
    Set-Content -Path ".git/hooks/pre-commit" -Value $HookContent -Encoding utf8
}

Write-Host "[bootstrap] structure ready"
