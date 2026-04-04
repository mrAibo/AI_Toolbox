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
# AI Toolbox Protocol (Claude)

This project uses the **AI Toolbox** workflow. Adhere to these **Critical 3 Session Rules**:

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and run `.agent/scripts/sync-task.sh` before starting any task.
2. **SAFETY:** All heavy terminal commands (python, cargo, go) MUST be run via `rtk`.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every task or session.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
EOF

# Create client-specific config folder
mkdir -p .agent/templates/clients
if [ -f ".agent/templates/clients/.claude.json" ]; then
    cp .agent/templates/clients/.claude.json .claude.json
    echo "[bootstrap] Installed .claude.json hooks"
fi

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

# Create specialized router files
cat << 'EOF' > .cursorrules
# AI Toolbox Protocol (Cursor)

1. **BOOT:** Run `.agent/scripts/sync-task.sh` and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF

cp .cursorrules .clinerules
cp .cursorrules .windsurfrules

if [ -d ".git" ]; then
    echo "[bootstrap] Updating Git pre-commit safeguards..."
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# AI Toolbox Pre-commit wrapper
# Calls the cross-platform verification logic.

if [ -f ".agent/scripts/verify-commit.sh" ]; then
    bash .agent/scripts/verify-commit.sh
fi
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
