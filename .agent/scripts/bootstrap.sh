#!/bin/bash
set -e

echo "[bootstrap] preparing AI Toolbox structure..."
mkdir -p .agent/rules .agent/memory .agent/templates .agent/scripts docs examples prompts

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

echo "$ROUTER_CONTENT" > CLAUDE.md
echo "$ROUTER_CONTENT" > GEMINI.md
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
