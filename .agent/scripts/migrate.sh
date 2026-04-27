#!/bin/bash
# migrate.sh — Advance .ai-toolbox/config.json toolbox_version.
#
# Usage:
#   bash .agent/scripts/migrate.sh [--target VERSION] [--dry-run] [--json]
#
# Behavior:
#   1. Reads current toolbox_version from .ai-toolbox/config.json.
#   2. Determines target (CLI flag or TOOLBOX_VERSION env or hard default below).
#   3. For each step from current → target, runs .agent/migrations/<from>-to-<to>.sh.
#   4. Writes audit-log entry per migration step.
#
# Exit codes (per .agent/contracts/error-codes.json):
#   0  = success
#   40 = MIGRATION_ERROR
#   41 = MIGRATION_VERSION_MISMATCH (target lower than current)

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-errors.sh
. "$SCRIPT_DIR/lib-errors.sh"
# shellcheck source=lib-audit.sh
. "$SCRIPT_DIR/lib-audit.sh"

# Default target — bump alongside any new migration script.
DEFAULT_TARGET="1.5"

DRY_RUN=0
TARGET="${TOOLBOX_VERSION:-$DEFAULT_TARGET}"
EXPLICIT_TARGET=""

while [ $# -gt 0 ]; do
    case "$1" in
        --target) EXPLICIT_TARGET="$2"; TARGET="$2"; shift 2 ;;
        --target=*) EXPLICIT_TARGET="${1#*=}"; TARGET="${1#*=}"; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --json) export LIB_ERRORS_JSON=1; shift ;;
        -h|--help)
            sed -n '2,16p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "migrate: unknown option $1" >&2; exit 40 ;;
    esac
done

CONFIG_FILE="${REPO_ROOT}/.ai-toolbox/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    error_emit IO_ERROR "$CONFIG_FILE"
fi

# Determine current version.
CURRENT="$(PYTHONIOENCODING=utf-8 CONFIG_PATH="$CONFIG_FILE" python3 - <<'PY'
import json, os, sys
with open(os.environ['CONFIG_PATH'], encoding='utf-8') as f:
    print(json.load(f).get('toolbox_version') or '1.4')
PY
)"

echo "[migrate] current=$CURRENT  target=$TARGET"

# Same version: no-op.
if [ "$CURRENT" = "$TARGET" ]; then
    echo "[migrate] config already at $TARGET — no migration needed"
    exit 0
fi

# Refuse downgrade.
LOWER_CHECK="$(printf '%s\n%s\n' "$CURRENT" "$TARGET" | sort -V | head -1)"
if [ "$LOWER_CHECK" = "$TARGET" ] && [ "$LOWER_CHECK" != "$CURRENT" ]; then
    error_emit MIGRATION_VERSION_MISMATCH "$CURRENT" "$TARGET"
fi

# Find migration scripts on the path from CURRENT to TARGET.
# Naming: .agent/migrations/<from>-to-<to>.sh
MIGRATIONS_DIR="${REPO_ROOT}/.agent/migrations"
if [ ! -d "$MIGRATIONS_DIR" ]; then
    error_emit MIGRATION_ERROR "$CURRENT" "$TARGET"
fi

# Build a sorted list of available migrations and walk from CURRENT to TARGET.
HOP="$CURRENT"
APPLIED=0
while [ "$HOP" != "$TARGET" ]; do
    MIG_FILE="$(find "$MIGRATIONS_DIR" -maxdepth 1 -type f -name "${HOP}-to-*.sh" 2>/dev/null | sort -V | head -1)"
    if [ -z "$MIG_FILE" ]; then
        error_emit MIGRATION_ERROR "$HOP" "$TARGET"
    fi
    NEXT="$(basename "$MIG_FILE" .sh | sed "s/^${HOP}-to-//")"

    echo "[migrate] applying ${HOP} → ${NEXT}"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[migrate]   DRY-RUN — would run: bash $MIG_FILE \"$REPO_ROOT\""
    else
        if bash "$MIG_FILE" "$REPO_ROOT"; then
            audit_event "migration_applied" "from=${HOP} to=${NEXT}"
            APPLIED=$((APPLIED+1))
        else
            error_emit MIGRATION_ERROR "$HOP" "$NEXT"
        fi
    fi

    HOP="$NEXT"
    # Safety: avoid infinite loops on a malformed migration graph.
    if [ "$APPLIED" -gt 50 ]; then
        error_emit INTERNAL_ERROR
    fi
done

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[migrate] DRY-RUN complete — no changes written"
else
    echo "[migrate] OK — applied $APPLIED migration(s); now at $TARGET"
fi
exit 0
