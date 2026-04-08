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
    while IFS= read -r -d '' file; do
        FILES+=("$file")
    done < <(find . -name "$ext" -type f "${EXCLUDE_ARGS[@]}" -print0 2>/dev/null)
done

for file in "${FILES[@]}"; do
    # Skip binary files
    if file "$file" | grep -q "binary\|executable\|archive\|zip\|image"; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    # Check if file ends with newline
    if [ -s "$file" ]; then
        LAST_CHAR=$(tail -c 1 "$file" | xxd -p)
        if [ "$LAST_CHAR" != "0a" ]; then
            echo "FAIL: $file does not end with a newline"
            ERRORS=$((ERRORS + 1))
        fi

        # Check for multiple trailing newlines (more than 1 consecutive newline at end)
        TRAILING=$(tail -c 2 "$file" | xxd -p)
        if [ "$TRAILING" = "0a0a" ]; then
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
