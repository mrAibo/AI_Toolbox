#!/bin/bash
# test-audit.sh — verifies the PR8 audit log mechanism
# Tests lib-audit.sh, and that instrumented hooks write to audit.log.
# Exit 0 = all pass, 1 = any fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# ─── Helpers ─────────────────────────────────────────────────────────────────

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# Isolated temp repo so tests do not touch real .agent/memory/audit.log
setup_tmp_repo() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  mkdir -p "$tmpdir/.agent/memory" "$tmpdir/.agent/scripts"
  cd "$tmpdir" || exit 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  # Symlink scripts so sourcing paths resolve correctly
  ln -s "$SCRIPT_DIR/lib-audit.sh" "$tmpdir/.agent/scripts/lib-audit.sh"
  echo "$tmpdir"
}

cleanup() { rm -rf "$1"; }

# ─── Test 1: audit_event writes an append-only line ──────────────────────────

echo "=== lib-audit.sh: basic write ==="
TMP=$(setup_tmp_repo)
(
  cd "$TMP" || exit 1
  # shellcheck source=lib-audit.sh
  . "$TMP/.agent/scripts/lib-audit.sh"
  audit_event "test_event" "k=v"
  audit_event "test_event" "k=v2"
)
LOG="$TMP/.agent/memory/audit.log"
if [ -f "$LOG" ]; then
  ok "audit.log created"
else
  fail "audit.log not created"
fi

LINE_COUNT=$(wc -l < "$LOG" 2>/dev/null || echo 0)
if [ "$LINE_COUNT" -eq 2 ]; then
  ok "two lines written (append-only)"
else
  fail "expected 2 lines, got $LINE_COUNT"
fi

if grep -q "test_event" "$LOG" 2>/dev/null; then
  ok "event name present in log"
else
  fail "event name missing from log"
fi

if grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$LOG" 2>/dev/null; then
  ok "ISO-8601 timestamp present"
else
  fail "ISO-8601 timestamp missing"
fi
cleanup "$TMP"

# ─── Test 2: hook-pre-command writes audit on heavy command block ─────────────

echo ""
echo "=== hook-pre-command.sh: heavy command audit ==="
TMP=$(setup_tmp_repo)
# Provide lib-atomic-write.sh stub so the hook can source it
echo 'atomic_json_increment() { :; }' > "$TMP/.agent/scripts/lib-atomic-write.sh"
cp "$SCRIPT_DIR/hook-pre-command.sh" "$TMP/.agent/scripts/hook-pre-command.sh"

(
  cd "$TMP" || exit 1
  bash "$TMP/.agent/scripts/hook-pre-command.sh" "python script.py" >/dev/null 2>&1
) || true  # expected exit 1

LOG="$TMP/.agent/memory/audit.log"
if [ -f "$LOG" ] && grep -q "heavy_cmd_blocked" "$LOG" 2>/dev/null; then
  ok "heavy_cmd_blocked written to audit.log"
else
  fail "heavy_cmd_blocked NOT written to audit.log"
fi

if grep -q "tool=python" "$LOG" 2>/dev/null; then
  ok "blocked tool name recorded"
else
  fail "blocked tool name missing from audit entry"
fi
cleanup "$TMP"

# ─── Test 3: hook-pre-command does NOT audit rtk-prefixed commands ────────────

echo ""
echo "=== hook-pre-command.sh: rtk prefix not audited ==="
TMP=$(setup_tmp_repo)
echo 'atomic_json_increment() { :; }' > "$TMP/.agent/scripts/lib-atomic-write.sh"
cp "$SCRIPT_DIR/hook-pre-command.sh" "$TMP/.agent/scripts/hook-pre-command.sh"

(
  cd "$TMP" || exit 1
  bash "$TMP/.agent/scripts/hook-pre-command.sh" "rtk cargo test" >/dev/null 2>&1
) || true

LOG="$TMP/.agent/memory/audit.log"
if [ ! -f "$LOG" ] || ! grep -q "heavy_cmd_blocked" "$LOG" 2>/dev/null; then
  ok "rtk-prefixed command does not produce audit entry"
else
  fail "rtk-prefixed command incorrectly produced audit entry"
fi
cleanup "$TMP"

# ─── Test 4: verify-commit writes audit on SKIP_SECRET_SCAN bypass ────────────

echo ""
echo "=== verify-commit.sh: secret scan bypass audit ==="
TMP=$(setup_tmp_repo)
cp "$SCRIPT_DIR/verify-commit.sh" "$TMP/.agent/scripts/verify-commit.sh"

(
  cd "$TMP" || exit 1
  SKIP_SECRET_SCAN=true bash "$TMP/.agent/scripts/verify-commit.sh" >/dev/null 2>&1
) || true

LOG="$TMP/.agent/memory/audit.log"
if [ -f "$LOG" ] && grep -q "secret_scan_bypassed" "$LOG" 2>/dev/null; then
  ok "secret_scan_bypassed written to audit.log"
else
  fail "secret_scan_bypassed NOT written to audit.log"
fi
cleanup "$TMP"

# ─── Test 5: no audit entry when secret scan runs normally ────────────────────

echo ""
echo "=== verify-commit.sh: no bypass audit when scan runs normally ==="
TMP=$(setup_tmp_repo)
cp "$SCRIPT_DIR/verify-commit.sh" "$TMP/.agent/scripts/verify-commit.sh"

(
  cd "$TMP" || exit 1
  unset SKIP_SECRET_SCAN
  bash "$TMP/.agent/scripts/verify-commit.sh" >/dev/null 2>&1
) || true

LOG="$TMP/.agent/memory/audit.log"
if [ ! -f "$LOG" ] || ! grep -q "secret_scan_bypassed" "$LOG" 2>/dev/null; then
  ok "no bypass audit entry when scan runs normally"
else
  fail "unexpected secret_scan_bypassed entry when scan was not bypassed"
fi
cleanup "$TMP"

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "=============================="
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -gt 0 ]; then
  exit 1
fi
exit 0
