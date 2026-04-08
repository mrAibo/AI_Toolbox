#!/bin/bash
# test-scripts.sh — validates shell and PowerShell scripts for syntax errors
# No set -e — we want to check all files even if one fails.

echo "[script-tests] Validating script syntax..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0
FAILED_FILES=""

# 1. Shell script syntax validation
echo "[script-tests] Checking shell script syntax..."
SH_COUNT=0
for script in "$SCRIPT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    SH_COUNT=$((SH_COUNT + 1))
    name="$(basename "$script")"
    # Capture both stdout and stderr from bash -n
    if output=$(bash -n "$script" 2>&1); then
        echo "  OK:   $name"
    else
        echo "  FAIL: $name"
        echo "        $output"
        ERRORS=$((ERRORS + 1))
        FAILED_FILES="$FAILED_FILES $name"
    fi
done
echo "[script-tests] Checked $SH_COUNT shell scripts, $ERRORS failed"

# 2. PowerShell syntax validation (skip if pwsh not available)
echo "[script-tests] Checking PowerShell script syntax..."
PS1_COUNT=0
PS1_ERRORS=0
for script in "$SCRIPT_DIR"/*.ps1; do
    [ -f "$script" ] || continue
    PS1_COUNT=$((PS1_COUNT + 1))
    name="$(basename "$script")"
    if command -v pwsh &>/dev/null; then
        # Declare $null vars before [ref] usage (pwsh 7+ requirement)
        # Use double quotes with escaped pwsh $ signs so bash $script expands
        if output=$(pwsh -NoProfile -Command "\$errors = \$null; \$tokens = \$null; \$null = [System.Management.Automation.Language.Parser]::ParseFile('$script', [ref]\$tokens, [ref]\$errors); if (\$errors.Count -gt 0) { \$errors | ForEach-Object { \$_.ToString() }; exit 1 }" 2>&1); then
            echo "  OK:   $name"
        else
            echo "  FAIL: $name"
            echo "        $output"
            ERRORS=$((ERRORS + 1))
            PS1_ERRORS=$((PS1_ERRORS + 1))
            FAILED_FILES="$FAILED_FILES $name"
        fi
    else
        echo "  SKIP: $name (pwsh not available)"
    fi
done
echo "[script-tests] Checked $PS1_COUNT PowerShell scripts, $PS1_ERRORS failed"

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "FAIL: $ERRORS script(s) have syntax errors:$FAILED_FILES"
    exit 1
fi

echo "[script-tests] OK — all scripts are syntactically valid"
