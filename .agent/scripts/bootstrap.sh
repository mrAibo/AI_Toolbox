#!/bin/bash
set -e

echo "[bootstrap] preparing AI Toolbox structure..."
mkdir -p .agent/rules .agent/memory .agent/templates .agent/scripts .agent/workflows docs examples prompts

touch README.md AGENT.md

TODAY=$(date +%Y-%m-%d)
if [ ! -s .agent/memory/architecture-decisions.md ]; then
cat << EOF > .agent/memory/architecture-decisions.md
# Architecture Decision Records (ADRs)

This file tracks major architectural decisions. Use the format from \`.agent/templates/adr-template.md\`.

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
echo "# Session Handover" > .agent/memory/session-handover.md
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
- Use `rtk` for heavy test/build commands where available (e.g. `rtk run "npm test"`)
- Avoid raw long log dumps into model context

## 4. Memory maintenance
- Record architecture changes in `architecture-decisions.md`
- Record integration expectations in `integration-contracts.md`
- Record current unfinished state in `session-handover.md`
EOF
fi

if [ ! -s .agent/rules/safety-rules.md ]; then
cat << 'EOF' > .agent/rules/safety-rules.md
# Safety Rules
Core principle: Do not perform destructive, irreversible, or high-risk actions without explicit user intent.

1. **No Blind Deletion:** Do not delete files or directories without verifying their content and importance.
2. **No Silent Rewrites:** Do not rewrite large parts of the repository silently or without a plan.
3. **Git Integrity:** Do not force-push or rewrite git history unless explicitly requested.
4. **Safety wrapper:** Always use `rtk` for heavy terminal operations to manage token usage and risk.
EOF
fi

if [ ! -s .agent/rules/testing-rules.md ]; then
cat << 'EOF' > .agent/rules/testing-rules.md
# Testing Rules
Core principle: Do not claim completion without verification.

1. **Verify Always:** Run tests whenever they exist.
2. **Bug Fix Sequence:** Use Reproduce -> Identify -> Fix -> Verify -> Record.
3. **Red-Green-Refactor:** Ensure tests fail before they pass for new features.
4. **Tooling:** Prefer concise test output via `rtk` to avoid context flooding.
EOF
fi

if [ ! -s .agent/rules/stack-rules.md ]; then
cat << 'EOF' > .agent/rules/stack-rules.md
# Stack Rules
- Follow the project's established coding standards (check `.editorconfig`, `.eslintrc`, etc.).
- Prefer idiomatic solutions for the detected language/framework.
- Document third-party library additions in `.agent/memory/integration-contracts.md`.
- Keep dependencies updated and minimize security vulnerabilities.
EOF
fi

if [ ! -s .agent/rules/antigravity.md ]; then
cat << 'EOF' > .agent/rules/antigravity.md
# Antigravity Environment Specifics
Use native slash commands in `.agent/workflows/` (`/start`, `/plan`, `/sync`, `/handover`).
Maintain native artifacts: `implementation_plan.md`, `task.md`, `walkthrough.md`.
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
if [ -f ".agent/templates/clients/.claude.json" ]; then
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
* **Languages/Frameworks:** [List your project's languages here]

## 3. Key Files & Entrypoints
* **Main Contract:** [AGENT.md](AGENT.md)
* **Handover Log:** [.agent/memory/session-handover.md](.agent/memory/session-handover.md)
* **Rules:** [.agent/rules/](.agent/rules/)

## 4. Limitations (Basic Tier)
* No hook automation -- sync and handover must be done manually.
* No multi-agent support.
* Safety rules are recommendations only, not enforced by the toolchain.

Refer to [AGENT.md](AGENT.md) for the full operational contract.
EOF
fi

# Create specialized router files
cat << 'EOF' > .cursorrules
# AI Toolbox Protocol (Cursor) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF

cat << 'EOF' > .clinerules
# AI Toolbox Protocol (RooCode / Cline) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF

cat << 'EOF' > .windsurfrules
# AI Toolbox Protocol (Windsurf) -- Tier: Standard

1. **BOOT:** Run the sync-task script (`.sh` on Unix, `.ps1` on Windows) and read `.agent/memory/current-task.md` before starting.
2. **SAFETY:** Use `rtk` for all heavy executions (tests, builds).
3. **HANDOVER:** Update `.agent/memory/session-handover.md` before finishing.

Details in [AGENT.md](AGENT.md).
EOF

# Full-Tier: Qwen Code CLI router
if [ -f ".agent/templates/clients/QWEN.md" ]; then
    cp .agent/templates/clients/QWEN.md QWEN.md
    echo "[bootstrap] Installed QWEN.md (Full Tier)"
else
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

Refer to [AGENT.md](AGENT.md) for the full operational contract.
EOF
fi

# Basic-Tier: Aider router + config
if [ -f ".agent/templates/clients/CONVENTIONS.md" ]; then
    cp .agent/templates/clients/CONVENTIONS.md CONVENTIONS.md
    echo "[bootstrap] Installed CONVENTIONS.md (Basic Tier)"
else
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

if [ -f ".agent/templates/clients/.aider.conf.yml" ]; then
    cp .agent/templates/clients/.aider.conf.yml .aider.conf.yml
    echo "[bootstrap] Installed .aider.conf.yml"
fi

if [ -d ".git" ]; then
    echo "[bootstrap] Updating Git pre-commit safeguards..."
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash
# AI Toolbox Pre-commit wrapper
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$REPO_ROOT/.agent/scripts/verify-commit.sh" ]; then
    bash "$REPO_ROOT/.agent/scripts/verify-commit.sh"
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
