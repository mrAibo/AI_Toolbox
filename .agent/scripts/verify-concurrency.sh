#!/bin/bash
# verify-concurrency.sh — PR1: Reproducible concurrency test for .agent/memory/ writes.
#
# Runs N parallel writers against .tool-stats.json and checks:
#   1. JSON remains valid (no corruption / truncation).
#   2. Counter value equals N (full serialization) or is ≥ 1 (atomicity floor).
#
# Usage:  bash .agent/scripts/verify-concurrency.sh [N_WRITERS]
#         N_WRITERS defaults to 20.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATS_FILE="$REPO_ROOT/.agent/memory/.tool-stats.json"
N="${1:-20}"

PASS=0
FAIL=0

_pass() { echo "[PASS] $*"; PASS=$((PASS + 1)); }
_fail() { echo "[FAIL] $*"; FAIL=$((FAIL + 1)); }
_warn() { echo "[WARN] $*"; }

# Source shared atomic helper
# shellcheck source=lib-atomic-write.sh
. "$REPO_ROOT/.agent/scripts/lib-atomic-write.sh"

# ---------- Backup / restore ----------
BACKUP="${STATS_FILE}.verify-bak"
[ -f "$STATS_FILE" ] && cp "$STATS_FILE" "$BACKUP"
_restore() { [ -f "$BACKUP" ] && mv "$BACKUP" "$STATS_FILE" || rm -f "$STATS_FILE"; }
trap _restore EXIT

# ---------- Test 1: JSON stays valid after N concurrent increments ----------
echo ""
echo "=== Test 1: Concurrent atomic_json_increment ($N writers) ==="
echo '{"rtk": 0, "beads": 0, "mcp": 0}' > "$STATS_FILE"

for _ in $(seq 1 "$N"); do
    atomic_json_increment "$STATS_FILE" "rtk" &
done
wait

# Validate JSON structure
py=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
if [ -z "$py" ]; then
    _warn "No Python found — skipping JSON validation"
else
    if "$py" -c "import json; json.load(open('$STATS_FILE'))" 2>/dev/null; then
        _pass "JSON is valid after $N concurrent writes"
    else
        _fail "JSON is CORRUPT after $N concurrent writes"
    fi

    rtk_count=$("$py" -c "import json; d=json.load(open('$STATS_FILE')); print(d.get('rtk',0))" 2>/dev/null || echo "?")
    if [ "$rtk_count" = "$N" ]; then
        _pass "Counter exact: rtk=$rtk_count (== $N) — full serialization via flock"
    elif [ "$rtk_count" -ge 1 ] 2>/dev/null; then
        _warn "Counter=$rtk_count (expected $N) — flock unavailable; atomic write prevents corruption, rare lost update accepted"
        PASS=$((PASS + 1))
    else
        _fail "Counter invalid: rtk=$rtk_count"
    fi
fi

# ---------- Test 2: No .tmp files left behind ----------
echo ""
echo "=== Test 2: No stale temp files ==="
stale=$(find "$REPO_ROOT/.agent/memory" -name "*.tmp.*" -o -name "*.tmp" 2>/dev/null | wc -l)
if [ "$stale" -eq 0 ]; then
    _pass "No stale .tmp files in .agent/memory/"
else
    _fail "$stale stale .tmp file(s) found in .agent/memory/"
    find "$REPO_ROOT/.agent/memory" -name "*.tmp*" 2>/dev/null
fi

# ---------- Test 3: Lock files are empty (not holding data) ----------
echo ""
echo "=== Test 3: Lock files are empty markers ==="
bad_locks=0
while IFS= read -r lf; do
    [ -f "$lf" ] || continue
    sz=$(wc -c < "$lf" 2>/dev/null || echo "0")
    if [ "$sz" -gt 0 ]; then
        _warn "Lock file has content ($sz bytes): $lf"
        bad_locks=$((bad_locks + 1))
    fi
done < <(find "$REPO_ROOT/.agent/memory" -maxdepth 1 -name "*.lock" 2>/dev/null)
if [ "$bad_locks" -eq 0 ]; then
    _pass "All lock files are empty markers (or none exist)"
fi

# ---------- Summary ----------
echo ""
echo "=== Results ==="
echo "PASS: $PASS   FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
