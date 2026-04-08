#!/bin/bash
# test-scripts.sh — validates shell and PowerShell scripts for syntax errors
# Runs on Linux (GitHub Actions). PowerShell syntax is checked via pwsh if available.

set -e

echo "[script-tests] Validating script syntax..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0

# 1. Shell script syntax validation
echo "[script-tests] Checking shell script syntax..."
SH_COUNT=0
for script in "$SCRIPT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    SH_COUNT=$((SH_COUNT + 1))

    # Check bash syntax
    if ! bash -n "$script" 2>&1; then
        echo "FAIL: Syntax error in $script"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for common shellcheck issues (if shellcheck is available)
    if command -v shellcheck &>/dev/null; then
        if ! shellcheck -e SC1090,SC1091 "$script" 2>&1; then
            echo "WARN: shellcheck warnings in $script"
            # Not a hard failure — informational
        fi
    fi
done
echo "[script-tests] Checked $SH_COUNT shell scripts"

# 2. PowerShell script syntax validation
echo "[script-tests] Checking PowerShell script syntax..."
PS1_COUNT=0
for script in "$SCRIPT_DIR"/*.ps1; do
    [ -f "$script" ] || continue
    PS1_COUNT=$((PS1_COUNT + 1))

    # Check PowerShell syntax via pwsh if available
    if command -v pwsh &>/dev/null; then
        if ! pwsh -NoProfile -Command "
            \$null = [System.Management.Automation.Language.Parser]::ParseFile('$script', [ref]\$null, [ref]\$errors)
            if (\$errors.Count -gt 0) {
                \$errors | ForEach-Object { Write-Host \"  \$($_.Extent.Text) at line \$($_.Extent.StartLineNumber)\" }
                exit 1
            }
        " 2>&1; then
            echo "FAIL: Syntax error in $script"
            ERRORS=$((ERRORS + 1))
        fi
    elif command -v powershell &>/dev/null; then
        if ! powershell -NoProfile -Command "
            \$null = [System.Management.Automation.Language.Parser]::ParseFile('$script', [ref]\$null, [ref]\$errors)
            if (\$errors.Count -gt 0) {
                \$errors | ForEach-Object { Write-Host \"  \$($_.Extent.Text) at line \$($_.Extent.StartLineNumber)\" }
                exit 1
            }
        " 2>&1; then
            echo "FAIL: Syntax error in $script"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "SKIP: PowerShell not available — skipping $script syntax check"
    fi
done
echo "[script-tests] Checked $PS1_COUNT PowerShell scripts"

if [ "$ERRORS" -gt 0 ]; then
    echo "FAIL: $ERRORS script(s) have syntax errors"
    exit 1
fi

echo "[script-tests] OK — all scripts are syntactically valid"
