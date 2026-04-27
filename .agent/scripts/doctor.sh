#!/bin/bash
# doctor.sh — AI Toolbox Health Check
# Validates all components are present and functional.
#
# Usage:
#   bash .agent/scripts/doctor.sh [--json] [--explain] [--text]
#
# Output modes:
#   --text    (default) Human-readable, color-coded.
#   --json    Machine-readable per .agent/schema/doctor-output.schema.json.
#   --explain Append a "Fix:" line to every warn/error in text mode. No effect in --json
#             (the `fix` field is always populated when known).
#
# Exit codes: 0 = all green, 1 = warnings only, 2 = errors found

set -u

ERRORS=0
WARNINGS=0
PASSED=0

MODE="text"
EXPLAIN=0
for arg in "$@"; do
    case "$arg" in
        --json) MODE="json" ;;
        --text) MODE="text" ;;
        --explain) EXPLAIN=1 ;;
        -h|--help)
            sed -n '2,16p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "doctor: unknown option $arg" >&2; exit 2 ;;
    esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TOOLBOX_VERSION=""
if [ -f "$REPO_ROOT/.ai-toolbox/config.json" ]; then
    TOOLBOX_VERSION="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('toolbox_version',''))" <"$REPO_ROOT/.ai-toolbox/config.json" 2>/dev/null || true)"
fi

# JSON accumulator (one record per line, joined at end).
JSON_TMP="$(mktemp)"
trap 'rm -f "$JSON_TMP"' EXIT
: >"$JSON_TMP"

# Internal helpers ----------------------------------------------------------
_emit_text_pass()  { echo "  🟢 $1"; }
_emit_text_warn()  { echo "  🟡 $1"; [ "$EXPLAIN" -eq 1 ] && [ -n "$2" ] && echo "     ↳ $2"; }
_emit_text_fail()  { echo "  🔴 $1"; [ "$EXPLAIN" -eq 1 ] && [ -n "$2" ] && echo "     ↳ $2"; }

_emit_section() {
    if [ "$MODE" = "text" ]; then
        printf '\n%s\n' "$1"
    fi
}

# _record CATEGORY NAME STATUS DETAIL FIX [error_code]
_record() {
    local category="$1" name="$2" status="$3" detail="$4" fix="${5:-}" error_code="${6:-}"
    case "$status" in
        ok)      PASSED=$((PASSED+1));   [ "$MODE" = "text" ] && _emit_text_pass "$detail" ;;
        warning) WARNINGS=$((WARNINGS+1)); [ "$MODE" = "text" ] && _emit_text_warn "$detail" "$fix" ;;
        error)   ERRORS=$((ERRORS+1));   [ "$MODE" = "text" ] && _emit_text_fail "$detail" "$fix" ;;
    esac

    # Append a JSON line.
    REC_CATEGORY="$category" REC_NAME="$name" REC_STATUS="$status" \
    REC_DETAIL="$detail" REC_FIX="$fix" REC_CODE="$error_code" \
    python3 - >>"$JSON_TMP" <<'PY'
import json, os, sys
rec = {
    "name":     os.environ['REC_NAME'],
    "category": os.environ['REC_CATEGORY'],
    "status":   os.environ['REC_STATUS'],
    "detail":   os.environ['REC_DETAIL'],
}
fix = os.environ.get('REC_FIX', '')
if fix:
    rec['fix'] = fix
ec = os.environ.get('REC_CODE', '')
if ec:
    rec['error_code'] = ec
sys.stdout.write(json.dumps(rec) + '\n')
PY
}

# Convenience wrappers used by check sections.
ok()   { _record "$1" "$2" ok      "$3" ""        ""; }
warn() { _record "$1" "$2" warning "$3" "${4:-}"  "${5:-}"; }
fail() { _record "$1" "$2" error   "$3" "${4:-}"  "${5:-}"; }

# Header (text mode only) ---------------------------------------------------
if [ "$MODE" = "text" ]; then
    echo "🩺 AI Toolbox Doctor"
    echo "===================="
fi

# 1. Core structure
_emit_section "📁 Core Structure"
for dir in .agent/memory .agent/rules .agent/scripts .agent/workflows .agent/templates; do
    name="structure.$(printf '%s' "$dir" | tr '[:upper:]/' '[:lower:].' | sed 's/^\.*//')"
    if [ -d "$REPO_ROOT/$dir" ]; then
        ok "structure" "$name" "$dir exists"
    else
        fail "structure" "$name" "$dir missing" "Run: ai-toolbox setup" "CONFIG_ERROR"
    fi
done

# 2. Router files
_emit_section "🔌 Router Files"
for f in CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md .cursorrules .clinerules .windsurfrules SKILL.md; do
    [ -f "$REPO_ROOT/$f" ] || continue
    name="router.$(printf '%s' "$f" | tr '[:upper:]/' '[:lower:].' | sed 's/^\.*//')"
    if grep -q "\-\- Tier:" "$REPO_ROOT/$f" 2>/dev/null; then
        if grep -q "cache-prefix:" "$REPO_ROOT/$f" 2>/dev/null; then
            ok "router" "$name" "$f exists with tier badge and cache-prefix"
        else
            warn "router" "$name" "$f exists with tier badge but missing cache-prefix comment" \
                 "Run: bash .agent/scripts/bootstrap.sh"
        fi
    else
        warn "router" "$name" "$f exists but missing tier badge" \
             "Run: bash .agent/scripts/bootstrap.sh"
    fi
done

# 3. Hook scripts
_emit_section "🪝 Hook Scripts"
for script in bootstrap sync-task hook-pre-command hook-stop verify-commit commit-msg; do
    for ext in sh ps1; do
        name="hook.${script}.${ext}"
        if [ -f "$REPO_ROOT/.agent/scripts/${script}.${ext}" ]; then
            ok "hook" "$name" "${script}.${ext} exists"
        else
            warn "hook" "$name" "${script}.${ext} missing" \
                 "Run: bash .agent/scripts/bootstrap.sh"
        fi
    done
done

# 4. Qwen hooks (only when qwen is installed)
if command -v qwen &>/dev/null && { [ -f "$REPO_ROOT/.qwen/settings.json" ] || [ -f "$HOME/.qwen/settings.json" ]; }; then
    _emit_section "🪝 Qwen Code Hooks"
    SETTINGS="${REPO_ROOT}/.qwen/settings.json"
    [ -f "$SETTINGS" ] || SETTINGS="$HOME/.qwen/settings.json"
    for hook in SessionStart PreToolUse PostToolUse Stop SessionEnd PreCompact; do
        name="qwen.hook.$(printf '%s' "$hook" | tr '[:upper:]' '[:lower:]')"
        if grep -q "$hook" "$SETTINGS" 2>/dev/null; then
            ok "qwen" "$name" "$hook configured"
        else
            warn "qwen" "$name" "$hook not configured" \
                 "Run: bash .agent/scripts/bootstrap.sh"
        fi
    done
fi

# 5. Tooling
_emit_section "🛠️ Tooling"
if command -v rtk &>/dev/null; then
    ok "tooling" "rtk" "rtk installed ($(rtk --version 2>/dev/null || echo 'installed'))"
else
    warn "tooling" "rtk" "rtk not installed — heavy commands will use more tokens" \
         "Run: cargo install --git https://github.com/rtk-ai/rtk --rev v0.35.0"
fi

if command -v bd &>/dev/null || command -v bd.exe &>/dev/null; then
    ok "tooling" "beads" "Beads installed ($(bd version 2>/dev/null || bd.exe version 2>/dev/null || echo 'installed'))"
else
    warn "tooling" "beads" "Beads not installed — task tracking will use manual mode" \
         "Run: go install github.com/steveyegge/beads/cmd/bd@v0.63.3"
fi

if command -v shellcheck &>/dev/null; then
    ok "tooling" "shellcheck" "shellcheck installed"
else
    warn "tooling" "shellcheck" "shellcheck not installed — shell script linting unavailable" \
         "Install: apt install shellcheck (Linux) | brew install shellcheck (macOS)"
fi

if command -v flock &>/dev/null; then
    ok "tooling" "flock" "flock available — concurrent hook writes are fully serialized"
else
    warn "tooling" "flock" "flock not available — concurrent hook writes use atomic rename only" \
         "Install: apt install util-linux (Linux). Not available on Windows; atomic rename fallback applies."
fi

# 6. Memory files
_emit_section "🧠 Memory Files"
for f in memory-index.md architecture-decisions.md integration-contracts.md session-handover.md runbook.md; do
    name="memory.$(printf '%s' "$f" | tr '[:upper:]/' '[:lower:].' | sed 's/^\.*//')"
    if [ -f "$REPO_ROOT/.agent/memory/$f" ]; then
        ok "memory" "$name" "$f exists"
    else
        warn "memory" "$name" "$f missing" \
             "Run: bash .agent/scripts/bootstrap.sh"
    fi
done

if [ -d "$REPO_ROOT/.agent/memory/adrs" ]; then
    ADR_COUNT=$(find "$REPO_ROOT/.agent/memory/adrs" -name "*.md" 2>/dev/null | wc -l)
    ok "memory" "memory.adrs" "adrs/ directory exists ($ADR_COUNT ADRs)"
else
    warn "memory" "memory.adrs" "adrs/ directory missing" \
         "Run: mkdir -p .agent/memory/adrs"
fi

# 7. Schema directory (added in v1.5)
_emit_section "📐 Schema & Contracts"
if [ -d "$REPO_ROOT/.agent/schema" ]; then
    SCHEMA_COUNT=$(find "$REPO_ROOT/.agent/schema" -name "*.schema.json" 2>/dev/null | wc -l)
    ok "schema" "schema.dir" ".agent/schema/ exists ($SCHEMA_COUNT schemas)"
else
    warn "schema" "schema.dir" ".agent/schema/ missing" \
         "Run: ai-toolbox migrate" "MIGRATION_VERSION_MISMATCH"
fi
for f in hook-protocol.json error-codes.json; do
    name="contract.$(printf '%s' "$f" | tr '[:upper:]/' '[:lower:].' | sed 's/^\.*//')"
    if [ -f "$REPO_ROOT/.agent/contracts/$f" ]; then
        ok "schema" "$name" "$f exists"
    else
        warn "schema" "$name" "$f missing" \
             "Run: ai-toolbox migrate"
    fi
done

# 8. Toolbox version (config.json)
_emit_section "🏷️  Toolbox Version"
if [ -n "$TOOLBOX_VERSION" ]; then
    ok "version" "config.toolbox_version" "config.json toolbox_version=$TOOLBOX_VERSION"
elif [ -f "$REPO_ROOT/.ai-toolbox/config.json" ]; then
    warn "version" "config.toolbox_version" "config.json present but missing toolbox_version field" \
         "Run: ai-toolbox migrate" "CONFIG_MISSING_FIELD"
else
    warn "version" "config.file" ".ai-toolbox/config.json absent" \
         "Run: bash .agent/scripts/bootstrap.sh"
fi

# 9. .gitignore
_emit_section "🚫 .gitignore"
if [ -f "$REPO_ROOT/.gitignore" ]; then
    for ignore in ".beads/" ".agent/memory/session-handover.md" ".agent/memory/current-task.md"; do
        name="gitignore.$(printf '%s' "$ignore" | tr '[:upper:]/' '[:lower:].' | sed 's/^\.*//' | sed 's/\.\.*$//')"
        if grep -qF "$ignore" "$REPO_ROOT/.gitignore" 2>/dev/null; then
            ok "gitignore" "$name" "$ignore excluded"
        else
            fail "gitignore" "$name" "$ignore not excluded — may leak local state" \
                 "Add to .gitignore: $ignore"
        fi
    done
else
    fail "gitignore" "gitignore.file" ".gitignore missing" \
         "Run: bash .agent/scripts/bootstrap.sh"
fi

# 10. Bootstrap parity
_emit_section "⚖️  Bootstrap Parity"
for script in bootstrap sync-task hook-pre-command hook-stop verify-commit commit-msg; do
    has_sh=false; has_ps1=false
    [ -f "$REPO_ROOT/.agent/scripts/${script}.sh" ] && has_sh=true
    [ -f "$REPO_ROOT/.agent/scripts/${script}.ps1" ] && has_ps1=true
    name="parity.${script}"
    if $has_sh && $has_ps1; then
        ok "parity" "$name" "${script}: both .sh and .ps1"
    elif $has_sh; then
        warn "parity" "$name" "${script}: only .sh (no .ps1)" \
             "Add a .ps1 sibling and re-run bootstrap-parity-check.sh"
    elif $has_ps1; then
        warn "parity" "$name" "${script}: only .ps1 (no .sh)" \
             "Add a .sh sibling and re-run bootstrap-parity-check.sh"
    else
        fail "parity" "$name" "${script}: missing both" \
             "Run: bash .agent/scripts/bootstrap.sh"
    fi
done

# 11. Audit log
_emit_section "📋 Audit Log"
AUDIT_LOG="$REPO_ROOT/.agent/memory/audit.log"
if [ -f "$AUDIT_LOG" ]; then
    AUDIT_LINES=$(wc -l < "$AUDIT_LOG" 2>/dev/null || echo "0")
    ok "audit" "audit.log" "audit.log exists ($AUDIT_LINES entries)"
    if ! git -C "$REPO_ROOT" check-ignore -q "$AUDIT_LOG" 2>/dev/null; then
        warn "audit" "audit.gitignore" "audit.log may not be gitignored — verify *.log is in .gitignore" \
             "Add *.log to .gitignore"
    fi
else
    ok "audit" "audit.log" "audit.log not yet created (written on first hook event)"
fi

# Final output --------------------------------------------------------------
if [ "$MODE" = "json" ]; then
    if [ "$ERRORS" -gt 0 ]; then STATUS="error"
    elif [ "$WARNINGS" -gt 0 ]; then STATUS="warning"
    else STATUS="ok"
    fi
    DOCTOR_STATUS="$STATUS" DOCTOR_OK="$PASSED" DOCTOR_WARN="$WARNINGS" \
    DOCTOR_ERR="$ERRORS" DOCTOR_VER="$TOOLBOX_VERSION" DOCTOR_LINES="$JSON_TMP" \
    python3 - <<'PY'
import json, os, sys
out = {
    "version": "1.0",
    "status":  os.environ['DOCTOR_STATUS'],
    "summary": {
        "ok":      int(os.environ['DOCTOR_OK']),
        "warning": int(os.environ['DOCTOR_WARN']),
        "error":   int(os.environ['DOCTOR_ERR']),
    },
    "checks": [],
}
ver = os.environ.get('DOCTOR_VER', '')
if ver:
    out['toolbox_version'] = ver
with open(os.environ['DOCTOR_LINES'], encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line:
            out['checks'].append(json.loads(line))
json.dump(out, sys.stdout, indent=2)
sys.stdout.write('\n')
PY
else
    echo ""
    echo "===================="
    if [ $ERRORS -gt 0 ]; then
        echo "🔴 $ERRORS error(s) found — action required"
    elif [ $WARNINGS -gt 0 ]; then
        echo "🟡 $WARNINGS warning(s) — toolbox functional but could be improved"
    else
        echo "🟢 All checks passed — AI Toolbox healthy"
    fi
fi

if [ $ERRORS -gt 0 ]; then exit 2; fi
if [ $WARNINGS -gt 0 ]; then exit 1; fi
exit 0
