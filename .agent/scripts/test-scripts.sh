#!/bin/bash
# test-scripts.sh — validates shell and PowerShell scripts for syntax errors

echo "[script-tests] Validating script syntax..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0

# 1. Shell script syntax validation
echo "[script-tests] Checking shell script syntax..."
SH_COUNT=0
for script in "$SCRIPT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    SH_COUNT=$((SH_COUNT + 1))
    if bash -n "$script" 2>&1; then
        echo "  OK: $(basename "$script")"
    else
        echo "  FAIL: $(basename "$script")"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "[script-tests] Checked $SH_COUNT shell scripts"

# 2. PowerShell syntax validation (skip if pwsh not available)
echo "[script-tests] Checking PowerShell script syntax..."
PS1_COUNT=0
for script in "$SCRIPT_DIR"/*.ps1; do
    [ -f "$script" ] || continue
    PS1_COUNT=$((PS1_COUNT + 1))
    if command -v pwsh &>/dev/null; then
        pwsh -NoProfile -Command "
            \$null = [System.Management.Automation.Language.Parser]::ParseFile('$script', [ref]\$null, [ref]\$errors)
            if (\$errors.Count -gt 0) { exit 1 }
        " 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  OK: $(basename "$script")"
        else
            echo "  FAIL: $(basename "$script")"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "  SKIP: $(basename "$script") (pwsh not available)"
    fi
done
echo "[script-tests] Checked $PS1_COUNT PowerShell scripts"

if [ "$ERRORS" -gt 0 ]; then
    echo "FAIL: $ERRORS script(s) have syntax errors"
    exit 1
fi

echo "[script-tests] OK — all scripts are syntactically valid"
