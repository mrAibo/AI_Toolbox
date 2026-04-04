#!/bin/bash
set -e

echo "[bootstrap] preparing AI Toolbox structure..."
mkdir -p .agent/rules .agent/memory .agent/templates .agent/scripts .agent/workflows docs examples prompts

touch README.md AGENT.md

echo "# Architecture Decision Records (ADRs)" > .agent/memory/architecture-decisions.md
echo "# Integration Contracts" > .agent/memory/integration-contracts.md
echo "# Session Handover" > .agent/memory/session-handover.md
echo "# Runbook" > .agent/memory/runbook.md
echo "# Current Task" > .agent/memory/current-task.md

touch .agent/rules/stack-rules.md
touch .agent/rules/testing-rules.md
touch .agent/rules/safety-rules.md

echo "[bootstrap] creating AI auto-discovery router files..."
cat << 'EOF' > CLAUDE.md
# AI Toolbox Workflow

Please refer strictly to [AGENT.md](AGENT.md) for the universal project guidelines, rules, and memory contracts. 
Do not begin any work or code without reading and following the Boot Sequence in AGENT.md!
EOF

cat << 'EOF' > GEMINI.md
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
EOF

# Copy CLAUDE.md to other router files
cp CLAUDE.md .clinerules
cp CLAUDE.md .cursorrules
cp CLAUDE.md .windsurfrules

if [ -d ".git" ]; then
    echo "[bootstrap] Updating Git pre-commit safeguards..."
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# AI Toolbox Pre-commit hook
# Validates that primary architectural intent is preserved.

ADR_FILE=".agent/memory/architecture-decisions.md"

if [ -f "$ADR_FILE" ]; then
    if [ ! -s "$ADR_FILE" ] || grep -q "^# Architecture Decision Records" "$ADR_FILE" && [ $(wc -l < "$ADR_FILE") -le 1 ]; then
        echo "🚨 AI Toolbox Block: architecture-decisions.md is empty or only contains a header!"
        echo "Please document your architectural decisions before committing to ensure project durability."
        exit 1
    fi
fi
exit 0
EOF
    chmod +x .git/hooks/pre-commit
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
        echo -e "\n$ignore" >> "$GITIGNORE"
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

echo "[bootstrap] structure ready"
