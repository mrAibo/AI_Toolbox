#!/bin/bash
# AI Toolbox Commit Verification (BASH)
# Runs lightweight checks on staged changes to preserve project quality.

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
ERRORS=0

# ---------------------------------------------------------------
# Check 1: Tier Badge on Router Files
# If a router file is staged, it must contain a "-- Tier:" badge.
# ---------------------------------------------------------------
ROUTER_FILES="CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md .cursorrules .clinerules .windsurfrules"

for file in $ROUTER_FILES; do
    # Only check if this file is in the staged changes
    if git diff --cached --name-only 2>/dev/null | grep -qxF "$file"; then
        if ! grep -q "\-\- Tier:" "$REPO_ROOT/$file" 2>/dev/null; then
            echo "🚨 AI Toolbox Warning: $file is missing the '-- Tier: X' badge."
            echo "   Every router file must declare its tier (Full, Standard, or Basic)."
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# ---------------------------------------------------------------
# Check 2: ADR Format (existing check, relaxed)
# If architecture-decisions.md is non-empty, it should have ADR entries.
# ---------------------------------------------------------------
ADR_FILE="$REPO_ROOT/.agent/memory/architecture-decisions.md"

if [ -f "$ADR_FILE" ] && [ -s "$ADR_FILE" ]; then
    if ! grep -q "^### ADR-" "$ADR_FILE"; then
        echo "⚠️  AI Toolbox Note: $ADR_FILE exists but contains no ADR entries."
        echo "   Use the '### ADR-XXXX' format to document architectural decisions."
        # Note: This is a warning, not a block — does not increment ERRORS
    fi
fi

# ---------------------------------------------------------------
# Check 3: Broken References in Modified .md Files
# Only check files that are staged for commit.
# ---------------------------------------------------------------
STAGED_MD=$(git diff --cached --name-only 2>/dev/null | grep '\.md$' || true)

for file in $STAGED_MD; do
    full_path="$REPO_ROOT/$file"
    if [ -f "$full_path" ]; then
        # Find all markdown links [text](path) where path starts with . or ./
        while IFS= read -r link; do
            # Extract the path from the link [text](path)
            target=$(echo "$link" | sed -n 's/.*\](\(.*\))/\1/p' | sed 's/#.*//')
            # Skip external links, anchors, and root-relative paths
            if echo "$target" | grep -qE '^https?://|^mailto:|^#|^/'; then
                continue
            fi
            # Resolve relative to the file's directory
            dir=$(dirname "$full_path")
            resolved="$dir/$target"
            if [ ! -e "$resolved" ]; then
                echo "⚠️  AI Toolbox Note: $file → broken link to '$target'"
                # Note: Warning only, does not block commit
            fi
        done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$full_path" 2>/dev/null || true)
    fi
done

# ---------------------------------------------------------------
# Check 4: Enforce TDD — code changes must have test updates
# Blocks commit unless tests are included OR commit message contains "tdd-skip"
# ---------------------------------------------------------------
STAGED_CODE=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|rs|go|java|kt|rb)$' || true)

if [ -n "$STAGED_CODE" ]; then
    # Check if any test files are also staged
    STAGED_TESTS=$(git diff --cached --name-only 2>/dev/null | grep -iE '(test|spec|_test\.|\.test\.)' || true)

    if [ -z "$STAGED_TESTS" ]; then
        # Allow override via commit message (stored in COMMIT_EDITMSG during commit)
        COMMIT_MSG=""
        if [ -f "$REPO_ROOT/.git/COMMIT_EDITMSG" ]; then
            COMMIT_MSG=$(cat "$REPO_ROOT/.git/COMMIT_EDITMSG" 2>/dev/null || echo "")
        fi
        if echo "$COMMIT_MSG" | grep -qi "tdd-skip"; then
            echo "⏭️  AI Toolbox: TDD skip requested via commit message. Proceeding."
        else
            echo "🚨 AI Toolbox TDD Enforcement: Code changes without test updates."
            echo "   Per .agent/rules/tdd-rules.md, all code changes must have tests."
            echo "   Staged code files:"
            echo "$STAGED_CODE" | sed 's/^/     /'
            echo ""
            echo "   To fix: Stage corresponding test files and commit again."
            echo "   To skip (emergency only): Include 'tdd-skip' in commit message."
            ERRORS=$((ERRORS + 1))
        fi
    fi
fi

# ---------------------------------------------------------------
# Result
# ---------------------------------------------------------------
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ AI Toolbox: $ERRORS error(s) found. Commit blocked."
    exit 1
fi

exit 0
