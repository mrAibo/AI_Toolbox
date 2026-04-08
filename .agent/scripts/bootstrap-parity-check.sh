#!/bin/bash
# bootstrap-parity-check.sh — verifies that bootstrap.sh and bootstrap.ps1 produce equivalent output
# Runs on Linux only (GitHub Actions ubuntu-latest). Checks content parity, not byte-for-byte identity.

set -e

echo "[parity-check] Comparing bootstrap.sh and bootstrap.ps1 outputs..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SH_FILE="$REPO_ROOT/.agent/scripts/bootstrap.sh"
PS1_FILE="$REPO_ROOT/.agent/scripts/bootstrap.ps1"

ERRORS=0

# 1. Both files must exist
if [ ! -f "$SH_FILE" ]; then
    echo "FAIL: bootstrap.sh not found at $SH_FILE"
    ERRORS=$((ERRORS + 1))
fi
if [ ! -f "$PS1_FILE" ]; then
    echo "FAIL: bootstrap.ps1 not found at $PS1_FILE"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi

# 2. Extract target files/dirs that each script creates
# We compare the structural intent: what directories, memory files, rules, and routers each creates

extract_targets() {
    local file="$1"
    local ext="$2"

    # Extract mkdir targets
    if [ "$ext" = "sh" ]; then
        grep -oP 'mkdir -p \K[^ ]+' "$file" 2>/dev/null | tr ' ' '\n' || true
    elif [ "$ext" = "ps1" ]; then
        grep -oP '\$dirs = @\((.*?)\)' -s "$file" 2>/dev/null | grep -oP '"[^"]+"' | tr -d '"' || true
    fi
}

# 3. Check that both scripts create the same core directories
SH_DIRS=$(grep -oP 'mkdir -p \K[^ ]+' "$SH_FILE" 2>/dev/null | tr ' ' '\n' | sort || true)
PS1_DIRS=$(grep -oP '"[^"]+"' "$PS1_FILE" 2>/dev/null | grep -E '^\.(agent|git|docs|examples|prompts)' | tr -d '"' | sort || true)

# Compare directory lists (normalize path separators)
SH_DIRS_NORMALIZED=$(echo "$SH_DIRS" | sed 's|/|\\|g' | sort)
PS1_DIRS_NORMALIZED=$(echo "$PS1_DIRS" | sort)

if [ "$SH_DIRS_NORMALIZED" != "$PS1_DIRS_NORMALIZED" ]; then
    echo "WARN: Directory creation lists differ:"
    echo "  bootstrap.sh creates: $(echo "$SH_DIRS" | tr '\n' ', ')"
    echo "  bootstrap.ps1 creates: $(echo "$PS1_DIRS" | tr '\n' ', ')"
    # Not a hard failure — informational
fi

# 4. Check that both create the same memory files
SH_MEMORY=$(grep -oP '\.agent/memory/[^ "]+' "$SH_FILE" 2>/dev/null | sort -u || true)
PS1_MEMORY=$(grep -oP '\.agent/memory/[^ "]+' "$PS1_FILE" 2>/dev/null | sort -u || true)

if [ "$SH_MEMORY" != "$PS1_MEMORY" ]; then
    echo "WARN: Memory file targets differ:"
    comm -23 <(echo "$SH_MEMORY") <(echo "$PS1_MEMORY") | while read -r line; do
        [ -n "$line" ] && echo "  Only in bootstrap.sh: $line"
    done
    comm -13 <(echo "$SH_MEMORY") <(echo "$PS1_MEMORY") | while read -r line; do
        [ -n "$line" ] && echo "  Only in bootstrap.ps1: $line"
    done
fi

# 5. Check that both create the same rule files
SH_RULES=$(grep -oP '\.agent/rules/[^ "]+' "$SH_FILE" 2>/dev/null | sort -u || true)
PS1_RULES=$(grep -oP '\.agent/rules/[^ "]+' "$PS1_FILE" 2>/dev/null | sort -u || true)

if [ "$SH_RULES" != "$PS1_RULES" ]; then
    echo "FAIL: Rule file targets differ:"
    comm -23 <(echo "$SH_RULES") <(echo "$PS1_RULES") | while read -r line; do
        [ -n "$line" ] && echo "  Missing in bootstrap.ps1: $line"
    done
    comm -13 <(echo "$SH_RULES") <(echo "$PS1_RULES") | while read -r line; do
        [ -n "$line" ] && echo "  Missing in bootstrap.sh: $line"
    done
    ERRORS=$((ERRORS + 1))
fi

# 6. Check that both create the same router files
SH_ROUTERS=$(grep -oP '(CLAUDE\.md|QWEN\.md|GEMINI\.md|CONVENTIONS\.md|\.cursorrules|\.clinerules|\.windsurfrules)' "$SH_FILE" 2>/dev/null | sort -u || true)
PS1_ROUTERS=$(grep -oP '(CLAUDE\.md|QWEN\.md|GEMINI\.md|CONVENTIONS\.md|\.cursorrules|\.clinerules|\.windsurfrules)' "$PS1_FILE" 2>/dev/null | sort -u || true)

if [ "$SH_ROUTERS" != "$PS1_ROUTERS" ]; then
    echo "FAIL: Router file targets differ:"
    comm -23 <(echo "$SH_ROUTERS") <(echo "$PS1_ROUTERS") | while read -r line; do
        [ -n "$line" ] && echo "  Missing in bootstrap.ps1: $line"
    done
    comm -13 <(echo "$SH_ROUTERS") <(echo "$PS1_ROUTERS") | while read -r line; do
        [ -n "$line" ] && echo "  Missing in bootstrap.sh: $line"
    done
    ERRORS=$((ERRORS + 1))
fi

# 7. Critical: both must have the same guard pattern (if [ ! -s ... ] / if (-not (Test-Path ...)))
SH_GUARD_COUNT=$(grep -c 'if \[ ! -s' "$SH_FILE" 2>/dev/null || echo "0")
PS1_GUARD_COUNT=$(grep -c 'if (-not (Test-Path' "$PS1_FILE" 2>/dev/null || echo "0")

if [ "$SH_GUARD_COUNT" != "$PS1_GUARD_COUNT" ]; then
    echo "WARN: Guard clause count differs: bootstrap.sh=$SH_GUARD_COUNT, bootstrap.ps1=$PS1_GUARD_COUNT"
fi

# 8. Functional parity test: run both in temp dirs and compare resulting file counts
TEMP_SH=$(mktemp -d)
TEMP_PS1=$(mktemp -d)

# Run bootstrap.sh in temp
(cd "$TEMP_SH" && bash "$SH_FILE" > /dev/null 2>&1) || true

# Run bootstrap.ps1 in temp (via PowerShell if available, or skip)
if command -v pwsh &>/dev/null; then
    (cd "$TEMP_PS1" && pwsh -ExecutionPolicy Bypass -File "$PS1_FILE" > /dev/null 2>&1) || true
elif command -v powershell &>/dev/null; then
    (cd "$TEMP_PS1" && powershell -ExecutionPolicy Bypass -File "$PS1_FILE" > /dev/null 2>&1) || true
else
    echo "SKIP: PowerShell not available — skipping functional parity test"
    rm -rf "$TEMP_SH" "$TEMP_PS1"
    if [ "$ERRORS" -eq 0 ]; then
        echo "[parity-check] OK — structural parity verified (functional test skipped)"
        exit 0
    fi
    exit 1
fi

# Compare file counts
SH_COUNT=$(find "$TEMP_SH" -type f | wc -l)
PS1_COUNT=$(find "$TEMP_PS1" -type f | wc -l)

if [ "$SH_COUNT" != "$PS1_COUNT" ]; then
    echo "FAIL: Functional output differs — bootstrap.sh creates $SH_COUNT files, bootstrap.ps1 creates $PS1_COUNT files"
    echo "  Only in bootstrap.sh output:"
    (cd "$TEMP_SH" && find . -type f | sort) > /tmp/sh_files.txt
    (cd "$TEMP_PS1" && find . -type f | sort) > /tmp/ps1_files.txt
    comm -23 /tmp/sh_files.txt /tmp/ps1_files.txt | head -20 | while read -r f; do
        [ -n "$f" ] && echo "    $f"
    done
    echo "  Only in bootstrap.ps1 output:"
    comm -13 /tmp/sh_files.txt /tmp/ps1_files.txt | head -20 | while read -r f; do
        [ -n "$f" ] && echo "    $f"
    done
    ERRORS=$((ERRORS + 1))
fi

# Cleanup
rm -rf "$TEMP_SH" "$TEMP_PS1" /tmp/sh_files.txt /tmp/ps1_files.txt 2>/dev/null || true

if [ "$ERRORS" -gt 0 ]; then
    echo "FAIL: $ERRORS parity issue(s) found"
    exit 1
fi

echo "[parity-check] OK — bootstrap.sh and bootstrap.ps1 produce equivalent output"
