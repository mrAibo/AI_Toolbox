#!/bin/bash
# test-mcp-schema.sh - Validates MCP configuration files against expected schemas
# Checks root keys, server definitions, pinned versions, and filesystem paths.
# Also validates opencode-config.json and .codex-hooks.json if present.
#
# Usage: bash test-mcp-schema.sh
# Exit: 0 = all pass, 1 = any fail

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
SKIP=0
TOTAL=0

# Colors
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' RED='' YELLOW='' CYAN='' BOLD='' NC=''
fi

pass_test() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${GREEN}PASS${NC} $1"; }
fail_test() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${RED}FAIL${NC} $1${2:+ - $2}"; }
skip_test() { SKIP=$((SKIP + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${YELLOW}SKIP${NC} $1${2:+ ($2)}"; }

section() { echo ""; echo -e "${BOLD}${CYAN}=== $1 ===${NC}"; }

# Helper: run a schema validation test via Python helper
# Usage: run_schema_test "test name" "file.json" "test_name[:args]"
run_schema_test() {
    local name="$1"
    local file="$2"
    local test_spec="$3"

    if [ ! -f "$file" ]; then
        skip_test "$name (file not found)"
        return
    fi

    local result
    result=$(python3 "$SCRIPT_DIR/mcp_schema_validator.py" "$test_spec" "$file" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ] && [ "$result" = "OK" ]; then
        pass_test "$name"
    else
        fail_test "$name" "$result"
    fi
}

# ─── MCP template files tests ────────────────────────────────────────────────

test_mcp_templates() {
    section "MCP Template Files (.agent/templates/mcp/*.json)"

    local mcp_dir="$REPO_ROOT/.agent/templates/mcp"
    if [ ! -d "$mcp_dir" ]; then
        fail_test "MCP templates directory not found"; return
    fi

    for json_file in "$mcp_dir"/*.json; do
        [ -f "$json_file" ] || continue
        local bname
        bname=$(basename "$json_file")

        # Determine root key and test prefix
        local root_key=""
        case "$bname" in
            mcp-opencode.json)  root_key="mcp" ;;
            mcp-configs.json)   root_key="servers" ;;
            *)                  root_key="mcpServers" ;;
        esac

        # Test: has correct root key
        run_schema_test "$bname: has root key '$root_key'" "$json_file" "root_key:$root_key"

        # Test: at least 2 servers defined
        run_schema_test "$bname: has >= 2 servers" "$json_file" "server_count:2"

        # Test: each server has at least one of: command, httpUrl, url
        run_schema_test "$bname: each server has command/httpUrl/url" "$json_file" "has_endpoints"

        # Test: if server has 'command', it has 'args' array
        run_schema_test "$bname: servers with command have args array" "$json_file" "has_args"

        # Test: filesystem server does NOT have '.' as only path arg
        run_schema_test "$bname: filesystem server not restricted to '.' only" "$json_file" "fs_not_dot"

        # Test: no unpinned @latest versions in args
        run_schema_test "$bname: no unpinned @latest versions" "$json_file" "no_latest"
    done
}

# ─── opencode-config.json tests ──────────────────────────────────────────────

test_opencode_config() {
    section "opencode-config.json (if present)"

    local config_file=""
    # Check multiple possible locations
    for alt in "opencode-config.json" "opencode.json" ".agent/config/opencode-config.json"; do
        if [ -f "$REPO_ROOT/$alt" ]; then
            config_file="$REPO_ROOT/$alt"
            break
        fi
    done

    if [ -z "$config_file" ]; then
        skip_test "opencode-config.json: file not present (optional)"
        return
    fi

    local bname
    bname=$(basename "$config_file")

    # Test: has 'mcp' section with >= 2 servers
    run_schema_test "$bname: has mcp section with >= 2 servers" "$config_file" "opencode_mcp:2"

    # Test: has 'commands' section with at least boot, sync, handover
    run_schema_test "$bname: has commands section with boot/sync/handover" "$config_file" "opencode_commands"

    # Test: has 'agents' section with at least one agent
    run_schema_test "$bname: has agents section with >= 1 agent" "$config_file" "opencode_agents"

    # Test: has 'permission' section with at least one permission
    run_schema_test "$bname: has permission section" "$config_file" "opencode_permission"
}

# ─── .codex-hooks.json tests ─────────────────────────────────────────────────

test_codex_hooks() {
    section ".codex-hooks.json (if present)"

    local hooks_file="$REPO_ROOT/.codex-hooks.json"
    if [ ! -f "$hooks_file" ]; then
        skip_test ".codex-hooks.json: file not present (optional)"
        return
    fi

    # Test: has 'hooks' section
    run_schema_test ".codex-hooks.json: has hooks section" "$hooks_file" "codex_hooks"

    # Test: has at least SessionStart or PreToolUse hook
    run_schema_test ".codex-hooks.json: has SessionStart or PreToolUse hook" "$hooks_file" "codex_hooks_required"

    # Test: each hook has type: 'command' and a command string
    run_schema_test ".codex-hooks.json: each hook has type and command" "$hooks_file" "codex_hooks_types"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

echo -e "${BOLD}AI Toolbox MCP Schema Validation Tests${NC}"
echo "================================================"

test_mcp_templates
test_opencode_config
test_codex_hooks

echo ""
echo "================================================"
echo -e "  ${BOLD}Test Results Summary${NC}"
echo "================================================"
echo -e "  Total:   $TOTAL"
echo -e "  ${GREEN}Passed:  $PASS${NC}"
echo -e "  ${RED}Failed:  $FAIL${NC}"
echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
echo "================================================"

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}SOME TESTS FAILED${NC}"
    exit 1
else
    echo -e "  ${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
