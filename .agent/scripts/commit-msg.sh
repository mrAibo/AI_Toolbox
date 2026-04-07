#!/bin/bash
# AI Toolbox Commit-Message Verification (BASH)
# Called by Git as commit-msg hook with $1 = commit message file path.
# Checks that code changes include test updates, unless tdd-skip is in the message.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
COMMIT_MSG_FILE="$1"
COMMIT_MSG="$(cat "$COMMIT_MSG_FILE" 2>/dev/null || echo "")"
ERRORS=0

# Check if staged code changes have corresponding test updates
STAGED_CODE=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|rs|go|java|kt|rb)$' || true)
STAGED_TESTS=$(git diff --cached --name-only 2>/dev/null | grep -iE '(^|/)(test|tests|spec|specs)(/|$)|(_test\.|\.test\.|\.spec\.)' || true)

if [ -n "$STAGED_CODE" ] && [ -z "$STAGED_TESTS" ]; then
    if echo "$COMMIT_MSG" | grep -qi 'tdd-skip'; then
        echo "⏭️  AI Toolbox: TDD skip requested via commit message."
    else
        echo "🚨 AI Toolbox: Code changes without test updates."
        echo "   Per .agent/rules/tdd-rules.md, all code changes must have tests."
        echo "   Staged code files:"
        echo "$STAGED_CODE" | sed 's/^/     /'
        echo ""
        echo "   To fix: Stage corresponding test files and commit again."
        echo "   To skip (emergency only): Include 'tdd-skip' in the commit message."
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "❌ AI Toolbox: Commit blocked. Fix the issue above and try again."
    exit 1
fi

exit 0
