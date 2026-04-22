#!/bin/bash
# AI Toolbox Commit Verification (BASH)
# Runs lightweight checks on staged changes to preserve project quality.
# No set -e — must be resilient; individual failures must not block the commit silently.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-audit.sh
. "$SCRIPT_DIR/lib-audit.sh"
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
# Check 3: Secret Patterns in Staged Diffs (not entire files)
# Scans only newly added lines in staged text files for secrets.
# Blocks the commit if secrets are detected (unlike broken links).
# This provides baseline protection for all clients at commit time.
# ---------------------------------------------------------------

if [ "$SKIP_SECRET_SCAN" = "true" ]; then
    echo "[INFO] AI Toolbox: Secret scanning skipped via SKIP_SECRET_SCAN."
    audit_event "secret_scan_bypassed" "hook=verify-commit"
else
    STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
    if [ -n "$STAGED_FILES" ]; then
        SECRET_FILES=""
        HARD_BLOCKED_FILES=""
        for file in $STAGED_FILES; do
            filename=$(basename "$file")
            full_path="$REPO_ROOT/$file"

            # Hard block: Never commit sensitive file types regardless of content
            case "$filename" in
                .env|*.pem|*.key|*.p12|*.pfx|*.jks)
                    HARD_BLOCKED_FILES="${HARD_BLOCKED_FILES} $file"
                    continue
                    ;;
            esac

            # Skip deleted files (they don't exist on disk)
            if [ ! -f "$full_path" ]; then
                continue
            fi

            # Only scan text files (skip binaries efficiently)
            if file "$full_path" | grep -qi "text"; then
                # Scan only newly added lines (lines starting with + in the diff)
                DIFF_ADDITIONS=$(git diff --cached "$file" 2>/dev/null | grep '^+' | grep -v '^+++' || true)
                if [ -n "$DIFF_ADDITIONS" ]; then
                    # Filter out common false positives (empty values, placeholders)
                    REAL_ADDITIONS=$(echo "$DIFF_ADDITIONS" | grep -viE '[=:]\s*(""|'"'"''"'"'|null|undefined|PLACEHOLDER|YOUR_.*_HERE|change[_-]?me|todo)' || true)
                    if [ -n "$REAL_ADDITIONS" ]; then
                        # Check for secret assignments in added lines (quoted and unquoted)
                        if echo "$REAL_ADDITIONS" | grep -qiE '(password|passwd|pwd|api[_-]?key|secret|token|auth[_-]?key|connection[_-]?string|database[_-]?url)\s*[=:]\s*["'"'"']?[^"'"'"'[:space:]]{8,}'; then
                            SECRET_FILES="${SECRET_FILES} $file"
                        fi
                        # Check for private key blocks in added lines
                        if echo "$REAL_ADDITIONS" | grep -qE 'BEGIN\s+(RSA|DSA|EC|OPENSSH)\s+PRIVATE\s+KEY'; then
                            SECRET_FILES="${SECRET_FILES} $file"
                        fi
                    fi
                fi
            fi
        done

        # Report hard-blocked files first (always block)
        if [ -n "$HARD_BLOCKED_FILES" ]; then
            echo "[FAIL] AI Toolbox: Sensitive file types must never be committed:$HARD_BLOCKED_FILES"
            echo "       Remove these files and use .env.example or placeholder files instead."
            ERRORS=$((ERRORS + 1))
        fi

        # Report secret pattern matches (always block)
        if [ -n "$SECRET_FILES" ]; then
            echo "[FAIL] AI Toolbox: Potential secrets detected in:$SECRET_FILES"
            echo "       This commit is blocked to prevent accidental secret exposure."
            echo "       Verify these are not accidental credentials."
            echo "       If they are intentional test fixtures, bypass with:"
            echo "         SKIP_SECRET_SCAN=true git commit -m \"your message\""
            ERRORS=$((ERRORS + 1))
        fi
    fi
fi

# ---------------------------------------------------------------
# Check 4: Broken References in Modified .md Files
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
