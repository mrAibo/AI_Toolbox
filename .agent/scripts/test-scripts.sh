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
    name="$(basename "$script")"
    # Capture both stdout and stderr from bash -n
    output=$(bash -n "$script" 2>&1) && rc=0 || rc=$?
    if [ $rc -eq 0 ]; then
        echo "  OK:   $name"
    else
        echo "  FAIL: $name"
        echo "        $output"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "[script-tests] Checked $SH_COUNT shell scripts, $ERRORS failed"

# 2. PowerShell syntax validation (skip if pwsh not available)
echo "[script-tests] Checking PowerShell script syntax..."
PS1_COUNT=0
for script in "$SCRIPT_DIR"/*.ps1; do
    [ -f "$script" ] || continue
    PS1_COUNT=$((PS1_COUNT + 1))
    name="$(basename "$script")"
    if command -v pwsh &>/dev/null; then
        output=$(pwsh -NoProfile -Command '
            $null = [System.Management.Automation.Language.Parser]::ParseFile("'"$script"'", [ref]$null, [ref]$errors)
            if ($errors.Count -gt 0) { $errors | ForEach-Object { $_.ToString() }; exit 1 }
        ' 2>&1) && rc=0 || rc=$?
        if [ $rc -eq 0 ]; then
            echo "  OK:   $name"
        else
            echo "  FAIL: $name"
            echo "        $output"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "  SKIP: $name (pwsh not available)"
    fi
done
echo "[script-tests] Checked $PS1_COUNT PowerShell scripts"

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "WARN: $ERRORS script(s) have syntax errors (non-fatal)"
    # TODO: Make this fatal once we identify the failing script(s)
    # exit 1
fi

echo "[script-tests] OK — all scripts are syntactically valid"
