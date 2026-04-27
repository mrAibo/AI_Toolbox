#!/bin/bash
# lib-errors.sh — structured error emission per .agent/contracts/error-codes.json
#
# Usage (from another shell script):
#   . "$(dirname "${BASH_SOURCE[0]}")/lib-errors.sh"
#   error_emit CONFIG_MISSING_FIELD "context.max_files" ".ai-toolbox/config.json"
#
# When the script is invoked with --json (LIB_ERRORS_JSON=1), errors are
# emitted as JSON on stdout. Otherwise human-readable text on stderr.
# Either way, the script exits with the registered exit code.
#
# Optional:
#   LIB_ERRORS_REGISTRY=path/to/error-codes.json  (defaults below)
#   LIB_ERRORS_JSON=1                              (force JSON mode)

set -u

LIB_ERRORS_REGISTRY="${LIB_ERRORS_REGISTRY:-}"
if [ -z "$LIB_ERRORS_REGISTRY" ]; then
    _le_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    LIB_ERRORS_REGISTRY="${_le_root}/.agent/contracts/error-codes.json"
fi

# error_lookup CODE -> echoes "exit_code\tdescription\tfix_template" or empty on miss.
error_lookup() {
    local code="$1"
    if [ ! -f "$LIB_ERRORS_REGISTRY" ]; then
        return 1
    fi
    LIB_ERRORS_CODE_LOOKUP="$code" LIB_ERRORS_REGISTRY="$LIB_ERRORS_REGISTRY" python3 - <<'PY'
import json, os, sys
code = os.environ['LIB_ERRORS_CODE_LOOKUP']
try:
    with open(os.environ['LIB_ERRORS_REGISTRY'], encoding='utf-8') as f:
        registry = json.load(f)
except Exception:
    sys.exit(1)
entry = registry.get('codes', {}).get(code)
if not entry:
    sys.exit(1)
print('\t'.join([
    str(entry.get('exit_code', 90)),
    entry.get('description', ''),
    entry.get('fix_template', '') or '',
]))
PY
}

# error_emit CODE [arg1 arg2 ...]
# Looks up CODE, substitutes $1..$9 in fix_template, prints, exits with registered code.
error_emit() {
    local code="$1"; shift
    local entry
    entry="$(error_lookup "$code" || true)"
    if [ -z "$entry" ]; then
        # Unknown code falls back to INTERNAL_ERROR semantics.
        printf 'error: unknown code %s (fix the caller)\n' "$code" >&2
        exit 90
    fi

    local exit_code description fix_template fix_filled
    exit_code="$(printf '%s' "$entry" | cut -f1)"
    description="$(printf '%s' "$entry" | cut -f2)"
    fix_template="$(printf '%s' "$entry" | cut -f3)"
    fix_filled="$fix_template"

    local i=1
    while [ $# -gt 0 ]; do
        # shellcheck disable=SC2001
        fix_filled="$(printf '%s' "$fix_filled" | sed "s|\\\$$i|$1|g")"
        shift
        i=$((i+1))
    done

    if [ "${LIB_ERRORS_JSON:-0}" = "1" ]; then
        LIB_ERRORS_PAYLOAD_CODE="$code" \
        LIB_ERRORS_PAYLOAD_MSG="$description" \
        LIB_ERRORS_PAYLOAD_FIX="$fix_filled" \
        python3 - <<'PY'
import json, os, sys
payload = {
    "error": os.environ['LIB_ERRORS_PAYLOAD_CODE'],
    "message": os.environ['LIB_ERRORS_PAYLOAD_MSG'],
}
fix = os.environ.get('LIB_ERRORS_PAYLOAD_FIX', '')
if fix:
    payload['fix'] = fix
json.dump(payload, sys.stdout)
sys.stdout.write('\n')
PY
    else
        printf '❌ %s\n%s\n' "$code" "$description" >&2
        if [ -n "$fix_filled" ]; then
            printf '\nFix:\n  %s\n' "$fix_filled" >&2
        fi
    fi

    exit "$exit_code"
}
