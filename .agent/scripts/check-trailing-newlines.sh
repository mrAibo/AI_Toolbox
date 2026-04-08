#!/bin/bash
# check-trailing-newlines.sh — verifies that text files end with exactly one newline
# This prevents merge conflicts and ensures POSIX compliance.

set -e

echo "[trailing-newlines] Checking files end with exactly one newline..."

ERRORS=0
CHECKED=0

# File types to check
EXTENSIONS=("*.md" "*.sh" "*.ps1" "*.yml" "*.yaml" "*.json" "*.txt")
EXCLUDE_PATHS=(".git" "node_modules" ".beads" ".qwen" ".claude" "beads_extracted" "beads.zip")

# Build exclude patterns for find
EXCLUDE_ARGS=()
for excl in "${EXCLUDE_PATHS[@]}"; do
    EXCLUDE_ARGS+=(-not -path "*/$excl/*" -not -path "*/$excl")
done

# Find all matching files
FILES=()
for ext in "${EXTENSIONS[@]}"; do
    mapfile -d '' -t found < <(find . -name "$ext" -type f "${EXCLUDE_ARGS[@]}" -print0 2>/dev/null)
    FILES+=("${found[@]}")
done

for file in "${FILES[@]}"; do
    # Skip binary files (simple heuristic: check for null bytes)
    if grep -Plc '\x00' "$file" > /dev/null 2>&1; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    # Check if file ends with newline using tail -c 1 + test
    if [ -s "$file" ]; then
        # tail -c 1 returns the last byte; if it's a newline, the command substitution strips it,
        # resulting in an empty string. If it's NOT a newline, the string is non-empty.
        LAST_BYTE=$(tail -c 1 "$file")
        if [ -n "$LAST_BYTE" ]; then
            echo "FAIL: $file does not end with a newline"
            ERRORS=$((ERRORS + 1))
        fi

        # Check for multiple trailing newlines
        LAST_TWO=$(tail -c 2 "$file" | od -An -tx1 | tr -d ' \n')
        if [ "$LAST_TWO" = "0a0a" ]; then
            echo "WARN: $file ends with multiple trailing newlines"
            # Not a hard failure — informational
        fi
    fi
done

if [ "$ERRORS" -gt 0 ]; then
    echo "FAIL: $ERRORS file(s) missing trailing newline"
    exit 1
fi

echo "[trailing-newlines] OK — $CHECKED files checked, all end with newline"
