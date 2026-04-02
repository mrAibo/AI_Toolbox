#!/bin/bash
set -e

echo "[bootstrap] preparing AI Toolbox structure..."
mkdir -p .agent/rules .agent/memory .agent/templates .agent/scripts .agent/workflows docs examples prompts

touch README.md AGENT.md

touch .agent/memory/architecture-decisions.md
touch .agent/memory/integration-contracts.md
touch .agent/memory/session-handover.md
touch .agent/memory/runbook.md
touch .agent/memory/current-task.md

touch .agent/rules/stack-rules.md
touch .agent/rules/testing-rules.md
touch .agent/rules/safety-rules.md

echo "[bootstrap] creating AI auto-discovery router files..."
ROUTER_CONTENT="# AI Toolbox Workflow

Please refer strictly to [AGENT.md](AGENT.md) for the universal project guidelines, rules, and memory contracts. 
Do not begin any work or code without reading and following the Boot Sequence in AGENT.md!"

GEMINI_CONTENT="# GEMINI.MD: AI Collaboration Guide (AI Toolbox)

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

echo "$ROUTER_CONTENT" > CLAUDE.md
echo "$GEMINI_CONTENT" > GEMINI.md
echo "$ROUTER_CONTENT" > .clinerules
echo "$ROUTER_CONTENT" > .cursorrules
echo "$ROUTER_CONTENT" > .windsurfrules

if [ -d ".git" ] && [ ! -f ".git/hooks/pre-commit" ]; then
    echo "[bootstrap] Installing Git pre-commit safeguards..."
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# AI Toolbox Pre-commit hook

HANDOVER_FILE=".agent/memory/session-handover.md"

if [ -f "$HANDOVER_FILE" ]; then
    if [ ! -s "$HANDOVER_FILE" ]; then
        echo "🚨 AI Toolbox Block: session-handover.md is empty!"
        echo "Please update handover notes before committing your work to preserve context."
        exit 1
    fi
fi
exit 0
EOF
    chmod +x .git/hooks/pre-commit
fi

chmod +x .agent/scripts/*.sh
echo "[bootstrap] structure ready"
