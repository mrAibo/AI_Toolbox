#!/bin/bash
# AI Toolbox Commit Verification (BASH)
# Validates that primary architectural intent is preserved.

REPO_ROOT="$(git rev-parse --show-toplevel)"
ADR_FILE="$REPO_ROOT/.agent/memory/architecture-decisions.md"

if [ -f "$ADR_FILE" ]; then
    # Check if file contains at least one ADR entry
    if [ ! -s "$ADR_FILE" ] || ! grep -q "^### ADR-" "$ADR_FILE"; then
        echo "🚨 AI Toolbox Block: no architecture decisions found in $ADR_FILE!"
        echo "Please document your architectural decisions (use the '### ADR-XXXX' format) before committing to ensure project durability."
        exit 1
    fi
fi

exit 0
