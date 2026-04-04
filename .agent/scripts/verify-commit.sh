#!/bin/bash
# AI Toolbox Commit Verification (BASH)
# Validates that primary architectural intent is preserved.

ADR_FILE=".agent/memory/architecture-decisions.md"

if [ -f "$ADR_FILE" ]; then
    # Check if file is empty OR only contains the default header
    if [ ! -s "$ADR_FILE" ] || (grep -q "^# Architecture Decision Records" "$ADR_FILE" && [ $(wc -l < "$ADR_FILE") -le 1 ]); then
        echo "🚨 AI Toolbox Block: architecture-decisions.md is empty or only contains a header!"
        echo "Please document your architectural decisions before committing to ensure project durability."
        exit 1
    fi
fi

exit 0
