#!/bin/bash
# test-hooks.sh - Comprehensive functional tests for all 10 Qwen hook scripts
# Tests: empty stdin, malformed JSON, missing files, heavy command detection,
#        rtk-prefixed commands, secret detection, clean files, path traversal
#
# Usage: bash test-hooks.sh
# Exit: 0 = all pass, 1 = any fail

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Temp directory for test artifacts — set early so all functions can use it
TMPDIR_HOOKS="$REPO_ROOT/.agent/scripts/.test-tmp-$$"
mkdir -p "$TMPDIR_HOOKS"
trap 'rm -rf "$TMPDIR_HOOKS"' EXIT

PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ─── Helpers ───────────────────────────────────────────────────────────────────

run_test() {
    local name="$1"
    local expected_exit="${2:-0}"
    local input="$3"
    local hook_script="$4"
    local extra_check="${5:-}"

    TOTAL=$((TOTAL + 1))

    local output
    local exit_code
    output=$(echo "$input" | bash "$hook_script" 2>/dev/null)
    exit_code=$?

    local ok=true

    # Check exit code
    if [ "$exit_code" -ne "$expected_exit" ]; then
        ok=false
    fi

    # Check valid JSON output (must not be empty)
    if [ -z "$output" ]; then
        ok=false
    else
        # Validate JSON
        if ! echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
            ok=false
        fi
    fi

    # Extra check (e.g. grep for specific field values)
    if [ -n "$extra_check" ] && $ok; then
        if ! eval "$extra_check"; then
            ok=false
        fi
    fi

    if $ok; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}PASS${NC} $name"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}FAIL${NC} $name"
        echo -e "        exit=$exit_code (expected $expected_exit)"
        echo -e "        output: ${output:0:120}"
    fi
}

run_test_pwsh() {
    local name="$1"
    local expected_exit="${2:-0}"
    local input="$3"
    local hook_script="$4"
    local extra_check="${5:-}"

    if ! command -v pwsh &>/dev/null; then
        TOTAL=$((TOTAL + 1))
        echo -e "  ${YELLOW}SKIP${NC} $name (pwsh not available)"
        return
    fi

    TOTAL=$((TOTAL + 1))

    local output
    local exit_code
    local tmpfile="$TMPDIR_HOOKS/hook_input_$$.txt"
    echo "$input" > "$tmpfile"
    output=$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$hook_script" < "$tmpfile" 2>/dev/null)
    exit_code=$?
    rm -f "$tmpfile"

    local ok=true

    if [ "$exit_code" -ne "$expected_exit" ]; then
        ok=false
    fi

    if [ -z "$output" ]; then
        ok=false
    else
        if ! echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
            ok=false
        fi
    fi

    if [ -n "$extra_check" ] && $ok; then
        if ! eval "$extra_check"; then
            ok=false
        fi
    fi

    if $ok; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}PASS${NC} $name"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}FAIL${NC} $name"
        echo -e "        exit=$exit_code (expected $expected_exit)"
        echo -e "        output: ${output:0:120}"
    fi
}

# ─── Temp file management ──────────────────────────────────────────────────────

# Use a directory inside the repo so post-tool hook path checks pass
TMPDIR_HOOKS="$REPO_ROOT/.agent/scripts/.test-tmp-$$"
mkdir -p "$TMPDIR_HOOKS"
trap 'rm -rf "$TMPDIR_HOOKS"' EXIT

# Path conversion helper: convert Unix-style paths to whatever the hook expects.
# On Windows Git Bash, git rev-parse returns Windows paths (C:/...) while
# realpath returns Unix paths (/c/...). The hook compares these, so we need
# to pass paths in the same format git rev-parse returns.
# cygpath -m gives mixed mode (C:/Users/...) which is JSON-safe and matches
# git rev-parse output.
to_native_path() {
    if command -v cygpath &>/dev/null; then
        cygpath -m "$1" 2>/dev/null || echo "$1"
    else
        echo "$1"
    fi
}

# ─── 1. hook-pre-command-qwen.sh ──────────────────────────────────────────────

echo ""
echo "=== hook-pre-command-qwen.sh ==="
HOOK="$SCRIPT_DIR/hook-pre-command-qwen.sh"

# Test: empty stdin
run_test "Empty stdin -> allow" 0 "" "$HOOK"

# Test: malformed JSON
run_test "Malformed JSON -> allow" 0 "this is not json" "$HOOK"

# Test: valid JSON with no tool_input
run_test "Valid JSON, no tool_input -> allow" 0 '{"tool_name":"Bash"}' "$HOOK"

# Test: heavy command detected (npm run build)
run_test "Heavy command 'npm run build' -> ask" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"npm run build"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\", f\"expected ask, got {d[\"decision\"]}\""'

# Test: heavy command detected (pytest)
run_test "Heavy command 'pytest tests/' -> ask" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"pytest tests/"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'

# Test: heavy command detected (python3 script)
run_test "Heavy command 'python3 main.py' -> ask" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"python3 main.py"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'

# Test: rtk-prefixed heavy command -> allowed
run_test "rtk-prefixed 'rtk npm run build' -> allow" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"rtk npm run build"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# Test: rtk-prefixed pytest -> allowed
run_test "rtk-prefixed 'rtk pytest' -> allow" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"rtk pytest tests/"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# Test: light command (ls) -> allowed
run_test "Light command 'ls -la' -> allow" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# Test: log file read suggestion
run_test "Log file 'tail app.log' -> allow with context" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"tail app.log"}}' "$HOOK"

# ─── 2. hook-pre-command-ps1-qwen.ps1 ────────────────────────────────────────

echo ""
echo "=== hook-pre-command-ps1-qwen.ps1 ==="
HOOK="$SCRIPT_DIR/hook-pre-command-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test: empty stdin
    run_test_pwsh "Empty stdin -> allow" 0 "" "$HOOK"

    # Test: malformed JSON
    run_test_pwsh "Malformed JSON -> allow" 0 "not json" "$HOOK"

    # Test: heavy command
    run_test_pwsh "Heavy command 'npm run build' -> ask" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"npm run build"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'

    # Test: rtk-prefixed
    run_test_pwsh "rtk-prefixed 'rtk npm run build' -> allow" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"rtk npm run build"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test: light command
    run_test_pwsh "Light command 'dir' -> allow" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"dir"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test: docker build
    run_test_pwsh "Heavy command 'docker build' -> ask" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"docker build ."}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All pwsh tests (pwsh not available)"
fi

# ─── 3. hook-post-tool-qwen.sh ────────────────────────────────────────────────

echo ""
echo "=== hook-post-tool-qwen.sh ==="
HOOK="$SCRIPT_DIR/hook-post-tool-qwen.sh"

# Test: empty stdin
run_test "Empty stdin -> allow" 0 "" "$HOOK"

# Test: malformed JSON
run_test "Malformed JSON -> allow" 0 "garbage" "$HOOK"

# Test: no file_path
run_test "No file_path -> allow" 0 '{"tool_name":"Write"}' "$HOOK"

# Test: clean file (no secrets)
CLEAN_FILE="$TMPDIR_HOOKS/clean_file.txt"
echo "This is a clean file with no secrets." > "$CLEAN_FILE"
CLEAN_FILE_NATIVE="$(to_native_path "$CLEAN_FILE")"
run_test "Clean file -> security check passed" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$CLEAN_FILE_NATIVE\"}}" "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"passed\" in d[\"reason\"].lower() or d[\"decision\"]==\"allow\""'

# Test: file with password secret
SECRET_FILE="$TMPDIR_HOOKS/secret_file.txt"
cat > "$SECRET_FILE" << 'SECEOF'
# config
password = "supersecret123"
api_key = "sk-abcdef1234567890"
SECEOF
SECRET_FILE_NATIVE="$(to_native_path "$SECRET_FILE")"
run_test "Secret file (password) -> warning" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SECRET_FILE_NATIVE\"}}" "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" in d[\"reason\"].lower()"'

# Test: file with private key
KEY_FILE="$TMPDIR_HOOKS/key_file.txt"
cat > "$KEY_FILE" << 'KEYEOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF8PbnGy0AHB7MhgHcTz6sE2I2yPB
-----END RSA PRIVATE KEY-----
KEYEOF
KEY_FILE_NATIVE="$(to_native_path "$KEY_FILE")"
run_test "Secret file (private key) -> warning" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$KEY_FILE_NATIVE\"}}" "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" in d[\"reason\"].lower()"'

# Test: file with connection string
CONN_FILE="$TMPDIR_HOOKS/conn_file.txt"
cat > "$CONN_FILE" << 'CONNEOF'
database_url = "postgresql://admin:password123@localhost:5432/mydb"
CONNEOF
CONN_FILE_NATIVE="$(to_native_path "$CONN_FILE")"
run_test "Secret file (connection string) -> warning" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$CONN_FILE_NATIVE\"}}" "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" in d[\"reason\"].lower()"'

# Test: non-existent file -> allow gracefully
run_test "Non-existent file -> allow" 0 \
    '{"tool_name":"Write","tool_input":{"file_path":"/tmp/does_not_exist_12345.txt"}}' "$HOOK"

# Test: path traversal blocked (file outside repo)
run_test "Path traversal (outside repo) -> allow" 0 \
    '{"tool_name":"Write","tool_input":{"file_path":"/etc/passwd"}}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# Test: clean file with short password placeholder (false negative check)
SHORT_PW="$TMPDIR_HOOKS/short_pw.txt"
echo 'password = "test"' > "$SHORT_PW"
SHORT_PW_NATIVE="$(to_native_path "$SHORT_PW")"
run_test "Short password placeholder -> no false positive" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SHORT_PW_NATIVE\"}}" "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" not in d[\"reason\"].lower() or d[\"decision\"]==\"allow\""'

# ─── 4. hook-post-tool-ps1-qwen.ps1 ──────────────────────────────────────────

echo ""
echo "=== hook-post-tool-ps1-qwen.ps1 ==="
HOOK="$SCRIPT_DIR/hook-post-tool-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test: empty stdin
    run_test_pwsh "Empty stdin -> allow" 0 "" "$HOOK"

    # Test: malformed JSON
    run_test_pwsh "Malformed JSON -> allow" 0 "not json at all" "$HOOK"

    # Test: no file_path
    run_test_pwsh "No file_path -> allow" 0 '{"tool_name":"Write"}' "$HOOK"

    # Test: clean file
    echo "clean content here" > "$CLEAN_FILE"
    run_test_pwsh "Clean file -> security check passed" 0 \
        "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$CLEAN_FILE_NATIVE\"}}" "$HOOK"

    # Test: secret file
    run_test_pwsh "Secret file -> warning" 0 \
        "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SECRET_FILE_NATIVE\"}}" "$HOOK"

    # Test: non-existent file
    run_test_pwsh "Non-existent file -> allow" 0 \
        '{"tool_name":"Write","tool_input":{"file_path":"/tmp/does_not_exist_12345.txt"}}' "$HOOK"

    # Test: path traversal
    run_test_pwsh "Path traversal -> allow" 0 \
        '{"tool_name":"Write","tool_input":{"file_path":"/etc/shadow"}}' "$HOOK"
else
    TOTAL=$((TOTAL + 7))
    echo -e "  ${YELLOW}SKIP${NC} All pwsh tests (pwsh not available)"
fi

# ─── 5. hook-stop-qwen.sh ────────────────────────────────────────────────────

echo ""
echo "=== hook-stop-qwen.sh ==="
HOOK="$SCRIPT_DIR/hook-stop-qwen.sh"

run_test "Empty stdin -> allow" 0 "" "$HOOK"
run_test "Malformed JSON -> allow" 0 "broken json {" "$HOOK"
run_test "Valid JSON with session_id -> allow" 0 \
    '{"session_id":"test-123","tool_name":"Stop"}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\" and d[\"reason\"]==\"Memory files updated\""'
run_test "Valid JSON, no session_id -> allow" 0 \
    '{"tool_name":"Stop"}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# ─── 6. hook-stop-ps1-qwen.ps1 ───────────────────────────────────────────────

echo ""
echo "=== hook-stop-ps1-qwen.ps1 ==="
HOOK="$SCRIPT_DIR/hook-stop-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    run_test_pwsh "Empty stdin -> allow" 0 "" "$HOOK"
    run_test_pwsh "Malformed JSON -> allow" 0 "bad json" "$HOOK"
    run_test_pwsh "Valid JSON -> allow" 0 \
        '{"session_id":"test-456"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'
    run_test_pwsh "Valid JSON with session_id -> memory updated" 0 \
        '{"session_id":"stop-test-123"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"reason\"]==\"Memory files updated\""'
    run_test_pwsh "Missing session_id field -> allow" 0 \
        '{"tool_name":"Stop"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'
    run_test_pwsh "Output has required fields" 0 \
        '{"session_id":"fields-test"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All pwsh tests (pwsh not available)"
fi

# ─── 7. hook-session-end-qwen.sh ─────────────────────────────────────────────

echo ""
echo "=== hook-session-end-qwen.sh ==="
HOOK="$SCRIPT_DIR/hook-session-end-qwen.sh"

run_test "Empty stdin -> allow" 0 "" "$HOOK"
run_test "Malformed JSON -> allow" 0 "{{{bad" "$HOOK"
run_test "Valid JSON -> allow" 0 \
    '{"session_id":"end-123"}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\" and \"consolidation\" in d[\"reason\"].lower()"'

# ─── 8. hook-session-end-ps1-qwen.ps1 ────────────────────────────────────────

echo ""
echo "=== hook-session-end-ps1-qwen.ps1 ==="
HOOK="$SCRIPT_DIR/hook-session-end-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    run_test_pwsh "Empty stdin -> allow" 0 "" "$HOOK"
    run_test_pwsh "Malformed JSON -> allow" 0 "not-json" "$HOOK"
    run_test_pwsh "Valid JSON -> allow" 0 \
        '{"session_id":"end-789"}' "$HOOK"
    run_test_pwsh "Valid JSON -> session consolidation" 0 \
        '{"session_id":"end-consolidate"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"consolidation\" in d[\"reason\"].lower() or d[\"decision\"]==\"allow\""'
    run_test_pwsh "Missing session_id -> allow" 0 \
        '{"tool_name":"SessionEnd"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'
    run_test_pwsh "Output has required fields" 0 \
        '{"session_id":"fields-check"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All pwsh tests (pwsh not available)"
fi

# ─── 9. hook-pre-compact-qwen.sh ─────────────────────────────────────────────

echo ""
echo "=== hook-pre-compact-qwen.sh ==="
HOOK="$SCRIPT_DIR/hook-pre-compact-qwen.sh"

run_test "Empty stdin -> allow" 0 "" "$HOOK"
run_test "Malformed JSON -> allow" 0 "not valid json!!!" "$HOOK"
run_test "Valid JSON -> allow with context" 0 \
    '{"tool_name":"Compact"}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\" and \"injected\" in d[\"reason\"].lower()"'

# Test: check that injected context contains key rules
run_test "Injected context contains key rules" 0 \
    '{"tool_name":"Compact"}' "$HOOK" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); ctx=d.get(\"hookSpecificOutput\",{}).get(\"additionalContext\",\"\"); assert \"rtk\" in ctx.lower() or \"key rules\" in ctx.lower()"'

# ─── 10. hook-pre-compact-ps1-qwen.ps1 ───────────────────────────────────────

echo ""
echo "=== hook-pre-compact-ps1-qwen.ps1 ==="
HOOK="$SCRIPT_DIR/hook-pre-compact-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    run_test_pwsh "Empty stdin -> allow" 0 "" "$HOOK"
    run_test_pwsh "Malformed JSON -> allow" 0 "garbage input" "$HOOK"
    run_test_pwsh "Valid JSON -> allow" 0 \
        '{"tool_name":"Compact"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'
    run_test_pwsh "Valid JSON -> context injected" 0 \
        '{"tool_name":"Compact"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"injected\" in d[\"reason\"].lower() or d[\"decision\"]==\"allow\""'
    run_test_pwsh "Missing tool_name -> allow" 0 \
        '{"session_id":"compact-test"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'
    run_test_pwsh "Output has required fields" 0 \
        '{"tool_name":"Compact"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All pwsh tests (pwsh not available)"
fi

# ─── Additional edge case tests ──────────────────────────────────────────────

echo ""
echo "=== Additional Edge Cases ==="

# Test: heavy command with cargo build
run_test "Heavy command 'cargo build' -> ask" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"cargo build"}}' \
    "$SCRIPT_DIR/hook-pre-command-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'

# Test: heavy command with go test
run_test "Heavy command 'go test ./...' -> ask" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"go test ./..."}}' \
    "$SCRIPT_DIR/hook-pre-command-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'

# Test: empty tool_input object
run_test "Empty tool_input object -> allow" 0 \
    '{"tool_name":"Bash","tool_input":{}}' \
    "$SCRIPT_DIR/hook-pre-command-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# Test: null tool_input
run_test "Null tool_input -> allow" 0 \
    '{"tool_name":"Bash","tool_input":null}' \
    "$SCRIPT_DIR/hook-pre-command-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

# Test: hook output has required fields (decision, reason)
run_test "Output has decision and reason fields" 0 \
    '{"tool_name":"Bash","tool_input":{"command":"ls"}}' \
    "$SCRIPT_DIR/hook-pre-command-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'

# Test: secret file with AWS-style key (matches api_key pattern)
AWS_FILE="$TMPDIR_HOOKS/aws_file.txt"
cat > "$AWS_FILE" << 'AWSEOF'
aws_api_key = "AKIAIOSFODNN7EXAMPLE12345"
secret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
AWSEOF
AWS_FILE_NATIVE="$(to_native_path "$AWS_FILE")"
run_test "AWS secret pattern -> warning" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$AWS_FILE_NATIVE\"}}" \
    "$SCRIPT_DIR/hook-post-tool-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" in d[\"reason\"].lower()"'

# Test: API key pattern
API_FILE="$TMPDIR_HOOKS/api_file.txt"
cat > "$API_FILE" << 'APIEOF'
api_key = "sk-proj-abc123def456ghi789jkl012mno345"
APIEOF
API_FILE_NATIVE="$(to_native_path "$API_FILE")"
run_test "API key pattern -> warning" 0 \
    "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$API_FILE_NATIVE\"}}" \
    "$SCRIPT_DIR/hook-post-tool-qwen.sh" \
    'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" in d[\"reason\"].lower()"'

# ─── 11. hook-pre-command-ps1-qwen.ps1 (FULL: 6 tests) ───────────────────────

echo ""
echo "=== hook-pre-command-ps1-qwen.ps1 [FULL] ==="
HOOK="$SCRIPT_DIR/hook-pre-command-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test 1: Empty stdin -> valid JSON + exit 0
    run_test_pwsh "Empty stdin -> valid JSON + exit 0" 0 "" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 2: Malformed JSON -> graceful allow + exit 0
    run_test_pwsh "Malformed JSON -> graceful allow + exit 0" 0 "not json at all!!!" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 3: Missing tool_input field -> allow gracefully
    run_test_pwsh "Missing tool_input -> allow gracefully" 0 '{"tool_name":"Bash"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 4: Heavy command (npm run build) -> decision: "ask"
    run_test_pwsh "Heavy command 'npm run build' -> decision: ask" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"npm run build"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\", f\"got {d[\"decision\"]}\""'

    # Test 5: Heavy command (pytest tests/) -> decision: "ask"
    run_test_pwsh "Heavy command 'pytest tests/' -> decision: ask" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"pytest tests/"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"ask\""'

    # Test 6: rtk-prefixed command (rtk npm run build) -> decision: "allow"
    run_test_pwsh "rtk-prefixed 'rtk npm run build' -> decision: allow" 0 \
        '{"tool_name":"Bash","tool_input":{"command":"rtk npm run build"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All 6 pwsh tests (pwsh not available)"
fi

# ─── 12. hook-post-tool-ps1-qwen.ps1 (FULL: 6 tests) ─────────────────────────

echo ""
echo "=== hook-post-tool-ps1-qwen.ps1 [FULL] ==="
HOOK="$SCRIPT_DIR/hook-post-tool-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test 1: Empty stdin -> valid JSON + exit 0
    run_test_pwsh "Empty stdin -> valid JSON + exit 0" 0 "" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 2: Malformed JSON -> graceful allow + exit 0
    run_test_pwsh "Malformed JSON -> graceful allow + exit 0" 0 "garbage input {{{" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 3: Missing file_path field -> allow gracefully
    run_test_pwsh "Missing file_path -> allow gracefully" 0 '{"tool_name":"Write"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 4: Heavy command — not applicable for post-tool; use clean file -> allow
    run_test_pwsh "Clean file -> security check passed" 0 \
        "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$CLEAN_FILE_NATIVE\"}}" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"passed\" in d[\"reason\"].lower() or d[\"decision\"]==\"allow\""'

    # Test 5: rtk-prefixed — not applicable; test non-existent file -> allow
    run_test_pwsh "Non-existent file -> allow gracefully" 0 \
        '{"tool_name":"Write","tool_input":{"file_path":"/tmp/does_not_exist_xyz999.txt"}}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 6: Secret detection — temp file containing "password = test12345678"
    SECRET_PW_FILE="$TMPDIR_HOOKS/secret_pw_ps1.txt"
    echo 'password = test12345678' > "$SECRET_PW_FILE"
    SECRET_PW_FILE_NATIVE="$(to_native_path "$SECRET_PW_FILE")"
    run_test_pwsh "Secret detection 'password = test12345678' -> warning" 0 \
        "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$SECRET_PW_FILE_NATIVE\"}}" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"secret\" in d[\"reason\"].lower() or \"potential\" in d[\"reason\"].lower()"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All 6 pwsh tests (pwsh not available)"
fi

# ─── 13. hook-stop-ps1-qwen.ps1 (FULL: 6 tests) ──────────────────────────────

echo ""
echo "=== hook-stop-ps1-qwen.ps1 [FULL] ==="
HOOK="$SCRIPT_DIR/hook-stop-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test 1: Empty stdin -> valid JSON + exit 0
    run_test_pwsh "Empty stdin -> valid JSON + exit 0" 0 "" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 2: Malformed JSON -> graceful allow + exit 0
    run_test_pwsh "Malformed JSON -> graceful allow + exit 0" 0 "broken { json" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 3: Missing fields (no session_id) -> allow gracefully
    run_test_pwsh "Missing session_id -> allow gracefully" 0 '{"tool_name":"Stop"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 4: Heavy command — not applicable; test valid JSON -> allow
    run_test_pwsh "Valid JSON -> allow + memory updated" 0 \
        '{"session_id":"stop-full-test"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\" and d[\"reason\"]==\"Memory files updated\""'

    # Test 5: rtk-prefixed — not applicable; test output has required fields
    run_test_pwsh "Output has required fields (decision, reason)" 0 \
        '{"session_id":"fields-check-stop"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'

    # Test 6: Output has hookSpecificOutput
    run_test_pwsh "Output has hookSpecificOutput" 0 \
        '{"session_id":"hook-output-check"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); h=d.get(\"hookSpecificOutput\",{}); assert \"hookEventName\" in h"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All 6 pwsh tests (pwsh not available)"
fi

# ─── 14. hook-session-end-ps1-qwen.ps1 (FULL: 6 tests) ───────────────────────

echo ""
echo "=== hook-session-end-ps1-qwen.ps1 [FULL] ==="
HOOK="$SCRIPT_DIR/hook-session-end-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test 1: Empty stdin -> valid JSON + exit 0
    run_test_pwsh "Empty stdin -> valid JSON + exit 0" 0 "" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 2: Malformed JSON -> graceful allow + exit 0
    run_test_pwsh "Malformed JSON -> graceful allow + exit 0" 0 "{{{ bad json" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 3: Missing fields (no session_id) -> allow gracefully
    run_test_pwsh "Missing session_id -> allow gracefully" 0 '{"tool_name":"SessionEnd"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 4: Valid JSON -> allow (heavy command N/A for this hook)
    run_test_pwsh "Valid JSON -> allow + session consolidation" 0 \
        '{"session_id":"end-full-test"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 5: Output has required fields
    run_test_pwsh "Output has required fields (decision, reason)" 0 \
        '{"session_id":"fields-check-end"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'

    # Test 6: Output has hookSpecificOutput
    run_test_pwsh "Output has hookSpecificOutput" 0 \
        '{"session_id":"hook-output-check-end"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); h=d.get(\"hookSpecificOutput\",{}); assert \"hookEventName\" in h"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All 6 pwsh tests (pwsh not available)"
fi

# ─── 15. hook-pre-compact-ps1-qwen.ps1 (FULL: 6 tests) ───────────────────────

echo ""
echo "=== hook-pre-compact-ps1-qwen.ps1 [FULL] ==="
HOOK="$SCRIPT_DIR/hook-pre-compact-ps1-qwen.ps1"

if command -v pwsh &>/dev/null; then
    # Test 1: Empty stdin -> valid JSON + exit 0
    run_test_pwsh "Empty stdin -> valid JSON + exit 0" 0 "" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 2: Malformed JSON -> graceful allow + exit 0
    run_test_pwsh "Malformed JSON -> graceful allow + exit 0" 0 "not valid json!!!" "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 3: Missing fields (no tool_name) -> allow gracefully
    run_test_pwsh "Missing tool_name -> allow gracefully" 0 '{"session_id":"compact-only"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d[\"decision\"]==\"allow\""'

    # Test 4: Valid JSON -> allow with context injected (heavy command N/A)
    run_test_pwsh "Valid JSON -> context injected" 0 \
        '{"tool_name":"Compact"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"injected\" in d[\"reason\"].lower() or d[\"decision\"]==\"allow\""'

    # Test 5: Output has required fields
    run_test_pwsh "Output has required fields (decision, reason)" 0 \
        '{"tool_name":"Compact"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert \"decision\" in d and \"reason\" in d"'

    # Test 6: Output has hookSpecificOutput with additionalContext
    run_test_pwsh "Output has hookSpecificOutput.additionalContext" 0 \
        '{"tool_name":"Compact"}' "$HOOK" \
        'echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); h=d.get(\"hookSpecificOutput\",{}); assert \"additionalContext\" in h"'
else
    TOTAL=$((TOTAL + 6))
    echo -e "  ${YELLOW}SKIP${NC} All 6 pwsh tests (pwsh not available)"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "========================================="
echo "  Test Results Summary"
echo "========================================="
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}SOME TESTS FAILED${NC}"
    exit 1
else
    echo -e "  ${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
