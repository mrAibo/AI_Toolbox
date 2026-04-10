#!/bin/bash
# AI Toolbox Commit Verification (BASH)
# Runs lightweight checks on staged changes to preserve project quality.
# No set -e — must be resilient; individual failures must not block the commit silently.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ERRORS=0

# ---------------------------------------------------------------
# Check 1: Tier Badge on Router Files
# If a router file is staged, it must contain a "-- Tier:" badge.
# ---------------------------------------------------------------
ROUTER_FILES="CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md .cursorrules .clinerules .windsurfrules CODERULES.md OPENCODERULES.md"

for file in $ROUTER_FILES; do
    # Only check if this file is in the staged changes
    if git diff --cached --name-only 2>/dev/null | grep -qxF "$file"; then
        if ! grep -q "\-\- Tier:" "$REPO_ROOT/$file" 2>/dev/null; then
            echo "[WARN] AI Toolbox: $file is missing the '-- Tier: X' badge."
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
        echo "[INFO] AI Toolbox Note: $ADR_FILE exists but contains no ADR entries."
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
            # Extract the path from the link [text](path) using sed for reliability
            # This handles nested parens correctly: [text](path(with)paren)) -> path(with)paren)
            target=$(echo "$link" | sed 's/^[^(]*(//; s/)[^)]*$//')
            target="${target%%#*}"
            # Skip external links, anchors, and root-relative paths
            if [[ $target =~ ^https?://|^mailto:|^#|^/ ]]; then
                continue
            fi
            # Resolve relative to the file's directory
            dir=$(dirname "$full_path")
            resolved="$dir/$target"
            if [ ! -e "$resolved" ]; then
                echo "[INFO] AI Toolbox Note: $file -> broken link to '$target'"
                # Note: Warning only, does not block commit
            fi
        done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$full_path" 2>/dev/null || true)
    fi
done

# ---------------------------------------------------------------
# Result
# ---------------------------------------------------------------
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "[FAIL] AI Toolbox: $ERRORS error(s) found. Commit blocked."
    exit 1
fi

exit 0
