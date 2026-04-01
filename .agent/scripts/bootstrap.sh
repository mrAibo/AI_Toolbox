#!/bin/bash
set -e

echo "[bootstrap] preparing AI Toolbox structure..."
mkdir -p .agent/rules .agent/memory .agent/templates .agent/scripts docs examples prompts

touch README.md AGENT.md

touch .agent/memory/architecture-decisions.md
touch .agent/memory/integration-contracts.md
touch .agent/memory/session-handover.md
touch .agent/memory/runbook.md

touch .agent/rules/stack-rules.md
touch .agent/rules/testing-rules.md
touch .agent/rules/safety-rules.md

echo "[bootstrap] structure ready"
