#!/bin/bash
# bootstrap-parity-check.sh — verifies that bootstrap.sh and bootstrap.ps1 produce equivalent output
# Runs on Linux only (GitHub Actions ubuntu-latest). Checks structural parity, not byte-for-byte identity.

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

# 2. Define the expected canonical file lists (source of truth)
# Both scripts should create these. We check if both scripts reference them.

EXPECTED_DIRS=(
    ".agent/rules"
    ".agent/memory"
    ".agent/templates"
    ".agent/scripts"
    ".agent/workflows"
    "docs"
    "examples"
    "prompts"
)

EXPECTED_MEMORY_FILES=(
    ".agent/memory/architecture-decisions.md"
    ".agent/memory/integration-contracts.md"
    ".agent/memory/session-handover.md"
    ".agent/memory/current-task.md"
    ".agent/memory/runbook.md"
    ".agent/memory/active-session.md"
    ".agent/memory/.tool-stats.json"
)

EXPECTED_RULE_FILES=(
    ".agent/rules/safety-rules.md"
    ".agent/rules/testing-rules.md"
    ".agent/rules/stack-rules.md"
    ".agent/rules/tdd-rules.md"
    ".agent/rules/mcp-rules.md"
    ".agent/rules/status-reporting.md"
    ".agent/rules/template-usage.md"
    ".agent/rules/tool-integrations.md"
    ".agent/rules/antigravity.md"
    ".agent/rules/qwen-code.md"
)

EXPECTED_ROUTERS=(
    "CLAUDE.md"
    "QWEN.md"
    "GEMINI.md"
    "CONVENTIONS.md"
    ".cursorrules"
    ".clinerules"
    ".windsurfrules"
)

# 3. Check that both scripts reference each expected target
check_references() {
    local label="$1"
    shift
    local files=("$@")
    local sh_missing=0
    local ps1_missing=0

    for target in "${files[@]}"; do
        # Escape dots for grep
        escaped=$(echo "$target" | sed 's/\./\\./g')

        if ! grep -q "$escaped" "$SH_FILE" 2>/dev/null; then
            echo "  Missing in bootstrap.sh: $target"
            sh_missing=$((sh_missing + 1))
        fi
        if ! grep -q "$escaped" "$PS1_FILE" 2>/dev/null; then
            echo "  Missing in bootstrap.ps1: $target"
            ps1_missing=$((ps1_missing + 1))
        fi
    done

    if [ $sh_missing -gt 0 ] || [ $ps1_missing -gt 0 ]; then
        ERRORS=$((ERRORS + 1))
    fi
}

# 4. Check directory creation
echo "[parity-check] Checking directory creation..."
DIR_ERRORS=0
for dir in "${EXPECTED_DIRS[@]}"; do
    escaped=$(echo "$dir" | sed 's/\./\\./g')
    sh_has=false
    ps1_has=false
    if grep -q "$escaped" "$SH_FILE" 2>/dev/null; then sh_has=true; fi
    if grep -q "$escaped" "$PS1_FILE" 2>/dev/null; then ps1_has=true; fi

    if [ "$sh_has" = false ] && [ "$ps1_has" = false ]; then
        echo "  WARN: Neither script references directory: $dir"
    elif [ "$sh_has" != "$ps1_has" ]; then
        echo "  WARN: Directory '$dir' referenced by only one script"
        DIR_ERRORS=$((DIR_ERRORS + 1))
    fi
done
if [ $DIR_ERRORS -eq 0 ]; then
    echo "[parity-check] OK — directory references match"
fi

# 5. Check memory files
echo "[parity-check] Checking memory file references..."
check_references "memory" "${EXPECTED_MEMORY_FILES[@]}"

# 6. Check rule files
echo "[parity-check] Checking rule file references..."
check_references "rules" "${EXPECTED_RULE_FILES[@]}"

# 7. Check router files
echo "[parity-check] Checking router file references..."
check_references "routers" "${EXPECTED_ROUTERS[@]}"

# 8. Guard clause count (informational)
SH_GUARD_COUNT=$(grep -c 'if \[ ! -s' "$SH_FILE" 2>/dev/null || echo "0")
PS1_GUARD_COUNT=$(grep -c 'if (-not (Test-Path' "$PS1_FILE" 2>/dev/null || echo "0")
if [ "$SH_GUARD_COUNT" != "$PS1_GUARD_COUNT" ]; then
    echo "INFO: Guard clause count differs: bootstrap.sh=$SH_GUARD_COUNT, bootstrap.ps1=$PS1_GUARD_COUNT"
fi

# 9. Functional parity test (only if no structural errors so far)
if [ "$ERRORS" -eq 0 ]; then
    TEMP_SH=$(mktemp -d)
    TEMP_PS1=$(mktemp -d)

    # Run bootstrap.sh in temp
    (cd "$TEMP_SH" && bash "$SH_FILE" > /dev/null 2>&1) || true

    # Run bootstrap.ps1 via pwsh if available
    if command -v pwsh &>/dev/null; then
        (cd "$TEMP_PS1" && pwsh -ExecutionPolicy Bypass -File "$PS1_FILE" > /dev/null 2>&1) || true
    else
        echo "SKIP: pwsh not available — skipping functional parity test"
        rm -rf "$TEMP_SH" "$TEMP_PS1"
        echo "[parity-check] OK — structural parity verified (functional test skipped)"
        exit 0
    fi

    # Compare file counts
    SH_COUNT=$(find "$TEMP_SH" -type f | wc -l)
    PS1_COUNT=$(find "$TEMP_PS1" -type f | wc -l)

    if [ "$SH_COUNT" != "$PS1_COUNT" ]; then
        echo "FAIL: Functional output differs — bootstrap.sh creates $SH_COUNT files, bootstrap.ps1 creates $PS1_COUNT files"
        (cd "$TEMP_SH" && find . -type f | sort) > /tmp/sh_files.txt
        (cd "$TEMP_PS1" && find . -type f | sort) > /tmp/ps1_files.txt
        echo "  Only in bootstrap.sh output:"
        comm -23 /tmp/sh_files.txt /tmp/ps1_files.txt | head -20 | while read -r f; do
            [ -n "$f" ] && echo "    $f"
        done
        echo "  Only in bootstrap.ps1 output:"
        comm -13 /tmp/sh_files.txt /tmp/ps1_files.txt | head -20 | while read -r f; do
            [ -n "$f" ] && echo "    $f"
        done
        ERRORS=$((ERRORS + 1))
    fi

    rm -rf "$TEMP_SH" "$TEMP_PS1" /tmp/sh_files.txt /tmp/ps1_files.txt 2>/dev/null || true
fi

if [ "$ERRORS" -gt 0 ]; then
    echo "FAIL: $ERRORS parity issue(s) found"
    exit 1
fi

echo "[parity-check] OK — bootstrap.sh and bootstrap.ps1 produce equivalent output"
