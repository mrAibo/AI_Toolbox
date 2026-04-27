#!/bin/bash
# test-hook-contract.sh — verify hook implementations match .agent/contracts/hook-protocol.json
#
# Usage:
#   bash .agent/scripts/test-hook-contract.sh [client] [--json]
#
# What it checks (per client × per event):
#   1. The contract entry validates against hook-protocol.schema.json.
#   2. The implementation script exists.
#   3. Running the script with synthetic stdin produces a stdout shape matching
#      stdout_format and an exit code that appears in exit_codes{}.
#
# Exit codes: 0 = all green, 20 = CONTRACT_VIOLATION, 60 = IO_ERROR.

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-errors.sh
. "$SCRIPT_DIR/lib-errors.sh"

CONTRACT="${REPO_ROOT}/.agent/contracts/hook-protocol.json"
SCHEMA="${REPO_ROOT}/.agent/schema/hook-protocol.schema.json"
SCHEMA_DIR="${REPO_ROOT}/.agent/schema"

[ -f "$CONTRACT" ] || error_emit IO_ERROR "$CONTRACT"
[ -f "$SCHEMA"   ] || error_emit IO_ERROR "$SCHEMA"

# ---- Parse arguments -------------------------------------------------------
TARGET_CLIENT="all"
JSON_OUTPUT=0
for arg in "$@"; do
    case "$arg" in
        --json) JSON_OUTPUT=1; export LIB_ERRORS_JSON=1 ;;
        -h|--help) sed -n '2,14p' "$0" | sed 's/^# \?//'; exit 0 ;;
        --*) echo "test-hook-contract: unknown option $arg" >&2; exit 2 ;;
        *) TARGET_CLIENT="$arg" ;;
    esac
done

# JSON output accumulator (one record per check, joined at end).
JSON_RESULTS_FILE="$(mktemp)"
trap 'rm -f "$JSON_RESULTS_FILE"' EXIT
: >"$JSON_RESULTS_FILE"

_record_result() {
    local client="$1" event="$2" status="$3" detail="$4"
    R_CLIENT="$client" R_EVENT="$event" R_STATUS="$status" R_DETAIL="$detail" \
    python3 - >>"$JSON_RESULTS_FILE" <<'PY'
import json, os, sys
sys.stdout.write(json.dumps({
    "client": os.environ['R_CLIENT'],
    "event":  os.environ['R_EVENT'],
    "status": os.environ['R_STATUS'],
    "detail": os.environ['R_DETAIL'],
}) + '\n')
PY
}

# In JSON mode, suppress text output by routing it to /dev/null after the JSON dump.
_log() { [ "$JSON_OUTPUT" -eq 0 ] && printf '%s\n' "$*"; }
_logn() { [ "$JSON_OUTPUT" -eq 0 ] && printf '%s' "$*"; }

# ---- Step 1: schema-validate the contract itself --------------------------
SCHEMA_OK=1
if python3 -c "import jsonschema" 2>/dev/null; then
    CONTRACT_PATH="$CONTRACT" SCHEMA_PATH="$SCHEMA" SCHEMA_DIR_PATH="$SCHEMA_DIR" python3 - <<'PY' >&2
import json, os, sys
from pathlib import Path
from jsonschema import Draft202012Validator

schema = json.loads(Path(os.environ['SCHEMA_PATH']).read_text(encoding='utf-8'))
data   = json.loads(Path(os.environ['CONTRACT_PATH']).read_text(encoding='utf-8'))
sd = Path(os.environ['SCHEMA_DIR_PATH']).resolve()

# Build a sibling-resolving validator. Prefer the modern referencing API,
# fall back to RefResolver on old jsonschema (< 4.18) which lacks registry=.
def _build_validator():
    try:
        from referencing import Registry, Resource
        from referencing.jsonschema import DRAFT202012
        resources = []
        for s in sd.glob('*.schema.json'):
            body = json.loads(s.read_text(encoding='utf-8'))
            resources.append((s.name, Resource(contents=body, specification=DRAFT202012)))
            resources.append((s.as_uri(), Resource(contents=body, specification=DRAFT202012)))
        registry = Registry().with_resources(resources)
        return Draft202012Validator(schema, registry=registry)
    except (ImportError, TypeError):
        try:
            from jsonschema import RefResolver  # type: ignore
            base_uri = sd.as_uri() + '/'
            resolver = RefResolver(base_uri=base_uri, referrer=schema)
            return Draft202012Validator(schema, resolver=resolver)
        except Exception:
            return Draft202012Validator(schema)

v = _build_validator()
errs = sorted(v.iter_errors(data), key=lambda e: list(e.absolute_path))
if errs:
    for e in errs:
        path = '/'.join(str(p) for p in e.absolute_path) or '<root>'
        print(f"  contract violation at {path}: {e.message}", file=sys.stderr)
    sys.exit(1)
PY
        if [ $? -ne 0 ]; then
        SCHEMA_OK=0
    else
        _log "[contract-test] schema OK"
    fi
else
    _log "[contract-test] WARN — jsonschema not installed; skipping schema check"
fi
[ "$SCHEMA_OK" -eq 0 ] && exit 20

# ---- Step 2: per-client per-event simulation ------------------------------
SUMMARY_FILE="$(mktemp)"
trap 'rm -f "$SUMMARY_FILE"' EXIT

# Resolve which clients to test.
CONTRACT_PATH="$CONTRACT" python3 - <<'PY' | tr -d '\r' >"$SUMMARY_FILE"
import json, os, sys
data = json.loads(open(os.environ['CONTRACT_PATH'], encoding='utf-8').read())
for name in sorted(data.get('clients', {}).keys()):
    sys.stdout.write(name + '\n')
PY

OVERALL_FAIL=0
PASS=0
FAIL=0

while IFS= read -r CLIENT; do
    [ -z "$CLIENT" ] && continue
    if [ "$TARGET_CLIENT" != "all" ] && [ "$TARGET_CLIENT" != "$CLIENT" ]; then
        continue
    fi
    _log ""
    _log "── $CLIENT"

    # Write events to a temp file (avoids fragile here-string parsing on Git Bash).
    #   "<event>\t<impl>\t<stdin_shape>\t<exit_codes_csv>\t<stdout_format>"
    EVENT_FILE="$(mktemp)"
    CLIENT="$CLIENT" CONTRACT_PATH="$CONTRACT" python3 - <<'PY' | tr -d '\r' >"$EVENT_FILE"
import json, os, sys
data = json.loads(open(os.environ['CONTRACT_PATH'], encoding='utf-8').read())
client = data['clients'].get(os.environ['CLIENT'], {})
for ev_name, ev in client.get('events', {}).items():
    impl = ev.get('implementation', '')
    stdin_fmt = ev.get('stdin_format', 'none')
    stdout_fmt = ev.get('stdout_format', 'plain text')
    codes = ','.join(sorted(ev.get('exit_codes', {}).keys()))
    sys.stdout.write('\t'.join([ev_name, impl, stdin_fmt, codes, stdout_fmt]) + '\n')
PY

    while IFS=$'\t' read -r EVENT IMPL STDIN_FMT CODES_CSV STDOUT_FMT; do
        [ -z "$EVENT" ] && continue
        IMPL_PATH="${REPO_ROOT}/${IMPL}"
        _logn "$(printf '  %-15s impl=%s ... ' "$EVENT" "$IMPL")"

        if [ -z "$IMPL" ] || [ ! -f "$IMPL_PATH" ]; then
            _log "FAIL (impl missing)"
            _record_result "$CLIENT" "$EVENT" "fail" "impl missing: $IMPL"
            FAIL=$((FAIL+1))
            OVERALL_FAIL=1
            continue
        fi

        # Build synthetic stdin based on declared shape.
        case "$STDIN_FMT" in
            none|"") STDIN="" ;;
            *tool_input.command*|*tool_input*command*)
                STDIN='{"hook_event_name":"'"$EVENT"'","tool_name":"Bash","tool_input":{"command":"echo hello"}}'
                ;;
            *tool_response*)
                STDIN='{"hook_event_name":"'"$EVENT"'","tool_name":"Bash","tool_input":{"command":"echo hi"},"tool_response":{"content":"hi"}}'
                ;;
            *session_id*)
                STDIN='{"hook_event_name":"'"$EVENT"'","session_id":"contract-test"}'
                ;;
            *)
                STDIN='{"hook_event_name":"'"$EVENT"'"}'
                ;;
        esac

        # Run with a short timeout in a sandbox dir so any side-effects go to /tmp.
        SANDBOX="$(mktemp -d)"
        OUT_FILE="${SANDBOX}/out"
        if [ -n "$STDIN" ]; then
            ( cd "$SANDBOX" && printf '%s' "$STDIN" | timeout 8 bash "$IMPL_PATH" >"$OUT_FILE" 2>/dev/null )
        else
            ( cd "$SANDBOX" && timeout 8 bash "$IMPL_PATH" >"$OUT_FILE" 2>/dev/null )
        fi
        EXIT=$?

        # Check exit code is in declared set.
        OK_EXIT=0
        IFS=',' read -ra DECLARED <<<"$CODES_CSV"
        for c in "${DECLARED[@]}"; do
            if [ "$EXIT" = "$c" ]; then OK_EXIT=1; break; fi
        done

        # Check stdout shape against declared format.
        # Pass the captured stdout via stdin to python3 to avoid Windows-path
        # translation issues in Git Bash.
        OK_STDOUT=1
        STDOUT_BYTES="$(wc -c <"$OUT_FILE" 2>/dev/null || echo 0)"
        case "$STDOUT_FMT" in
            JSON*|*JSON)
                if [ "$STDOUT_BYTES" -gt 0 ] && ! python3 -c "import json,sys; json.load(sys.stdin)" <"$OUT_FILE" 2>/dev/null; then
                    OK_STDOUT=0
                fi
                ;;
            ignored)
                : # accept anything
                ;;
            *) : ;;
        esac

        rm -rf "$SANDBOX"

        if [ $OK_EXIT -eq 1 ] && [ $OK_STDOUT -eq 1 ]; then
            _log "OK (exit=$EXIT)"
            _record_result "$CLIENT" "$EVENT" "pass" "exit=$EXIT"
            PASS=$((PASS+1))
        else
            REASON=""
            [ $OK_EXIT  -eq 0 ] && REASON="exit=$EXIT not in {${CODES_CSV}}"
            [ $OK_STDOUT -eq 0 ] && REASON="${REASON:+$REASON; }stdout not valid JSON for declared format '${STDOUT_FMT}'"
            _log "FAIL ($REASON)"
            _record_result "$CLIENT" "$EVENT" "fail" "$REASON"
            FAIL=$((FAIL+1))
            OVERALL_FAIL=1
        fi
    done <"$EVENT_FILE"
    rm -f "$EVENT_FILE"

done <"$SUMMARY_FILE"

if [ "$JSON_OUTPUT" -eq 1 ]; then
    if [ "$OVERALL_FAIL" -eq 0 ]; then STATUS="ok"; else STATUS="error"; fi
    REPORT_STATUS="$STATUS" REPORT_PASS="$PASS" REPORT_FAIL="$FAIL" \
    REPORT_CLIENT="$TARGET_CLIENT" REPORT_FILE="$JSON_RESULTS_FILE" python3 - <<'PY'
import json, os, sys
out = {
    "version": "1.0",
    "status": os.environ['REPORT_STATUS'],
    "client": os.environ['REPORT_CLIENT'],
    "summary": {
        "pass": int(os.environ['REPORT_PASS']),
        "fail": int(os.environ['REPORT_FAIL']),
    },
    "checks": [],
}
with open(os.environ['REPORT_FILE'], encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line:
            out['checks'].append(json.loads(line))
json.dump(out, sys.stdout, indent=2)
sys.stdout.write('\n')
PY
else
    echo ""
    echo "──────────────────────────────"
    echo "  PASS=$PASS  FAIL=$FAIL"
fi

if [ "$OVERALL_FAIL" -ne 0 ]; then
    [ "$JSON_OUTPUT" -eq 0 ] && echo "Run with --json for structured error output."
    exit 20
fi
exit 0
