#!/bin/bash
# doctor.sh — AI Toolbox Health Check
# Validates all components are present and functional.
# Exit 0 = all green, Exit 1 = warnings only, Exit 2 = errors found

ERRORS=0
WARNINGS=0

echo "🩺 AI Toolbox Doctor"
echo "===================="
echo ""

# Helper functions
check_pass() { echo "  🟢 $1"; }
check_warn() { echo "  🟡 $1"; WARNINGS=$((WARNINGS + 1)); }
check_fail() { echo "  🔴 $1"; ERRORS=$((ERRORS + 1)); }

# Find repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# 1. Check .agent/ structure
echo "📁 Core Structure"
for dir in .agent/memory .agent/rules .agent/scripts .agent/workflows .agent/templates; do
    if [ -d "$REPO_ROOT/$dir" ]; then
        check_pass "$dir exists"
    else
        check_fail "$dir missing"
    fi
done

# 2. Check router files
echo ""
echo "🔌 Router Files"
for f in CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md .cursorrules .clinerules .windsurfrules SKILL.md; do
    if [ -f "$REPO_ROOT/$f" ]; then
        if grep -q "\-\- Tier:" "$REPO_ROOT/$f" 2>/dev/null; then
            check_pass "$f exists with tier badge"
        else
            check_warn "$f exists but missing tier badge"
        fi
    fi
done

# 3. Check hook scripts
echo ""
echo "🪝 Hook Scripts"
for script in bootstrap sync-task hook-pre-command hook-stop verify-commit commit-msg; do
    for ext in sh ps1; do
        if [ -f "$REPO_ROOT/.agent/scripts/${script}.${ext}" ]; then
            check_pass "${script}.${ext} exists"
        else
            check_warn "${script}.${ext} missing"
        fi
    done
done

# 4. Check Qwen hooks (if .qwen/settings.json exists)
if [ -f "$REPO_ROOT/.qwen/settings.json" ] 2>/dev/null || [ -f "$HOME/.qwen/settings.json" ] 2>/dev/null; then
    echo ""
    echo "🪝 Qwen Code Hooks"
    SETTINGS="${REPO_ROOT}/.qwen/settings.json"
    [ -f "$SETTINGS" ] || SETTINGS="$HOME/.qwen/settings.json"
    for hook in SessionStart PreToolUse PostToolUse Stop SessionEnd PreCompact; do
        if grep -q "$hook" "$SETTINGS" 2>/dev/null; then
            check_pass "$hook configured"
        else
            check_warn "$hook not configured"
        fi
    done
fi

# 5. Check tools
echo ""
echo "🛠️ Tooling"
if command -v rtk &>/dev/null; then
    check_pass "rtk installed ($(rtk --version 2>/dev/null || echo 'installed'))"
else
    check_warn "rtk not installed — heavy commands will use more tokens"
fi

if command -v bd &>/dev/null || command -v bd.exe &>/dev/null; then
    check_pass "Beads installed ($(bd version 2>/dev/null || bd.exe version 2>/dev/null || echo 'installed'))"
else
    check_warn "Beads not installed — task tracking will use manual mode"
fi

if command -v shellcheck &>/dev/null; then
    check_pass "shellcheck installed"
else
    check_warn "shellcheck not installed — shell script linting unavailable"
fi

# 6. Check memory files
echo ""
echo "🧠 Memory Files"
for f in memory-index.md architecture-decisions.md integration-contracts.md session-handover.md runbook.md; do
    if [ -f "$REPO_ROOT/.agent/memory/$f" ]; then
        check_pass "$f exists"
    else
        check_warn "$f missing"
    fi
done

# Check ADRs directory
if [ -d "$REPO_ROOT/.agent/memory/adrs" ]; then
    ADR_COUNT=$(find "$REPO_ROOT/.agent/memory/adrs" -name "*.md" 2>/dev/null | wc -l)
    check_pass "adrs/ directory exists ($ADR_COUNT ADRs)"
else
    check_warn "adrs/ directory missing"
fi

# 7. Check .gitignore
echo ""
echo "🚫 .gitignore"
if [ -f "$REPO_ROOT/.gitignore" ]; then
    for ignore in ".beads/" ".agent/memory/session-handover.md" ".agent/memory/current-task.md"; do
        if grep -qF "$ignore" "$REPO_ROOT/.gitignore" 2>/dev/null; then
            check_pass "$ignore excluded"
        else
            check_fail "$ignore not excluded — may leak local state"
        fi
    done
else
    check_fail ".gitignore missing"
fi

# 8. Bootstrap parity (check both .sh and .ps1 exist for each script)
echo ""
echo "⚖️  Bootstrap Parity"
for script in bootstrap sync-task hook-pre-command hook-stop verify-commit commit-msg; do
    has_sh=false; has_ps1=false
    [ -f "$REPO_ROOT/.agent/scripts/${script}.sh" ] && has_sh=true
    [ -f "$REPO_ROOT/.agent/scripts/${script}.ps1" ] && has_ps1=true
    if $has_sh && $has_ps1; then
        check_pass "${script}: both .sh and .ps1"
    elif $has_sh; then
        check_warn "${script}: only .sh (no .ps1)"
    elif $has_ps1; then
        check_warn "${script}: only .ps1 (no .sh)"
    else
        check_fail "${script}: missing both"
    fi
done

# 9. Audit log
echo ""
echo "📋 Audit Log"
AUDIT_LOG="$REPO_ROOT/.agent/memory/audit.log"
if [ -f "$AUDIT_LOG" ]; then
    AUDIT_LINES=$(wc -l < "$AUDIT_LOG" 2>/dev/null || echo "0")
    check_pass "audit.log exists ($AUDIT_LINES entries)"
    # Warn if audit log is not gitignored (*.log covers it, but be explicit)
    if ! git -C "$REPO_ROOT" check-ignore -q "$AUDIT_LOG" 2>/dev/null; then
        check_warn "audit.log may not be gitignored — verify *.log is in .gitignore"
    fi
else
    check_pass "audit.log not yet created (written on first hook event)"
fi

# Summary
echo ""
echo "===================="
if [ $ERRORS -gt 0 ]; then
    echo "🔴 $ERRORS error(s) found — action required"
    exit 2
elif [ $WARNINGS -gt 0 ]; then
    echo "🟡 $WARNINGS warning(s) — toolbox functional but could be improved"
    exit 1
else
    echo "🟢 All checks passed — AI Toolbox healthy"
    exit 0
fi
