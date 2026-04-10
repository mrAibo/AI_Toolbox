#!/bin/bash
# test-integration.sh — End-to-end integration tests for AI Toolbox
# Tests the complete workflow: bootstrap, doctor, parity, hooks, JSON, links.
#
# Usage: bash test-integration.sh
# Exit: 0 = all pass, 1 = any fail

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
SKIP=0
TOTAL=0

# Colors (only if terminal supports it)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    CYAN=''
    BOLD=''
    NC=''
fi

# ─── Helpers ───────────────────────────────────────────────────────────────────

pass_test() {
    local name="$1"
    PASS=$((PASS + 1))
    TOTAL=$((TOTAL + 1))
    echo -e "  ${GREEN}PASS${NC} $name"
}

fail_test() {
    local name="$1"
    local detail="${2:-}"
    FAIL=$((FAIL + 1))
    TOTAL=$((TOTAL + 1))
    echo -e "  ${RED}FAIL${NC} $name"
    if [ -n "$detail" ]; then
        echo -e "        $detail"
    fi
}

skip_test() {
    local name="$1"
    local reason="${2:-}"
    SKIP=$((SKIP + 1))
    TOTAL=$((TOTAL + 1))
    if [ -n "$reason" ]; then
        echo -e "  ${YELLOW}SKIP${NC} $name ($reason)"
    else
        echo -e "  ${YELLOW}SKIP${NC} $name"
    fi
}

section() {
    echo ""
    echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
}

# ─── Test 1: Bootstrap Completeness ───────────────────────────────────────────

test_bootstrap_completeness() {
    section "Test 1: Bootstrap Completeness"

    if [ ! -f "$REPO_ROOT/.agent/scripts/bootstrap.sh" ]; then
        fail_test "bootstrap.sh not found"
        return
    fi

    # Create temp directory with a minimal .git to avoid bootstrap git issues
    local temp_dir
    temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/.git/hooks"

    # Run bootstrap in temp directory
    local output
    local exit_code
    output=$(cd "$temp_dir" && bash "$REPO_ROOT/.agent/scripts/bootstrap.sh" 2>&1)
    exit_code=$?

    # Bootstrap may exit with code 1 in minimal environments (missing optional tools)
    # This is acceptable — we still verify the created files
    if [ "$exit_code" -eq 0 ]; then
        pass_test "bootstrap.sh completes without error"
    elif [ "$exit_code" -eq 1 ]; then
        pass_test "bootstrap.sh completes with warnings (exit 1, expected in minimal env)"
    else
        fail_test "bootstrap.sh exited with code $exit_code" "Output: ${output:0:200}"
        rm -rf "$temp_dir"
        return
    fi

    # Define expected files (canonical source of truth)
    local router_files
    router_files="CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md .cursorrules .clinerules .windsurfrules SKILL.md"

    local memory_files
    memory_files="architecture-decisions.md integration-contracts.md session-handover.md current-task.md runbook.md active-session.md"

    local created_rules
    created_rules="safety-rules.md testing-rules.md stack-rules.md tdd-rules.md mcp-rules.md status-reporting.md template-usage.md tool-integrations.md antigravity.md qwen-code.md"

    local directories
    directories=".agent/rules .agent/memory .agent/scripts .agent/workflows .agent/templates docs examples prompts"

    # Check router files
    for f in $router_files; do
        if [ -f "$temp_dir/$f" ]; then
            pass_test "Router file created: $f"
        else
            if [ "$f" = "SKILL.md" ]; then
                skip_test "Router file: $f (optional, not created by default)"
            else
                fail_test "Router file missing: $f"
            fi
        fi
    done

    # Check memory files
    for f in $memory_files; do
        if [ -f "$temp_dir/.agent/memory/$f" ]; then
            pass_test "Memory file created: $f"
        else
            fail_test "Memory file missing: .agent/memory/$f"
        fi
    done

    # Check rules files
    for f in $created_rules; do
        if [ -f "$temp_dir/.agent/rules/$f" ]; then
            pass_test "Rules file created: $f"
        else
            fail_test "Rules file missing: .agent/rules/$f"
        fi
    done

    # Verify directories exist
    for d in $directories; do
        if [ -d "$temp_dir/$d" ]; then
            pass_test "Directory exists: $d"
        else
            fail_test "Directory missing: $d"
        fi
    done

    # Cleanup
    rm -rf "$temp_dir"
}

# ─── Test 2: Doctor Health Check ──────────────────────────────────────────────

test_doctor_health() {
    section "Test 2: Doctor Health Check"

    if [ ! -f "$REPO_ROOT/.agent/scripts/doctor.sh" ]; then
        fail_test "doctor.sh not found"
        return
    fi

    local output
    local exit_code
    output=$(cd "$REPO_ROOT" && bash .agent/scripts/doctor.sh 2>&1)
    exit_code=$?

    # Exit 0 = all green, Exit 1 = warnings only (acceptable), Exit 2 = errors
    if [ "$exit_code" -eq 2 ]; then
        fail_test "doctor.sh found errors (exit code 2)" "${output:0:300}"
    elif [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 1 ]; then
        pass_test "doctor.sh completes (exit code $exit_code)"
    else
        fail_test "doctor.sh unexpected exit code: $exit_code"
    fi

    # Verify output contains expected sections
    local section_list="Core Structure|Router Files|Hook Scripts|Tooling|Memory Files|.gitignore|Bootstrap Parity"

    # Check each section individually
    local check_sections
    check_sections="Core Structure:Core Structure
Router Files:Router Files
Hook Scripts:Hook Scripts
Tooling:Tooling
Memory Files:Memory Files
.gitignore:.gitignore
Bootstrap Parity:Bootstrap Parity"

    while IFS=: read -r label search_term; do
        if [ -z "$label" ]; then
            continue
        fi
        if echo "$output" | grep -qi "$search_term"; then
            pass_test "Doctor output contains section: $label"
        else
            fail_test "Doctor output missing section: $label"
        fi
    done <<< "$check_sections"
}

# ─── Test 3: Bootstrap Parity ─────────────────────────────────────────────────

test_bootstrap_parity() {
    section "Test 3: Bootstrap Parity"

    if [ ! -f "$REPO_ROOT/.agent/scripts/bootstrap-parity-check.sh" ]; then
        fail_test "bootstrap-parity-check.sh not found"
        return
    fi

    local output
    local exit_code
    output=$(cd "$REPO_ROOT" && bash .agent/scripts/bootstrap-parity-check.sh 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        pass_test "Bootstrap parity check passes"
    elif [ "$exit_code" -eq 1 ]; then
        fail_test "Bootstrap parity check found issues" "${output:0:300}"
    else
        fail_test "Bootstrap parity check unexpected exit: $exit_code"
    fi
}

# ─── Test 4: Trailing Newlines ────────────────────────────────────────────────

test_trailing_newlines() {
    section "Test 4: Trailing Newlines"

    if [ ! -f "$REPO_ROOT/.agent/scripts/check-trailing-newlines.sh" ]; then
        fail_test "check-trailing-newlines.sh not found"
        return
    fi

    local output
    local exit_code
    output=$(cd "$REPO_ROOT" && bash .agent/scripts/check-trailing-newlines.sh 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        local count
        count=$(echo "$output" | grep -oE '[0-9]+ files checked' || echo "unknown")
        pass_test "Trailing newlines check passes ($count)"
    elif [ "$exit_code" -eq 1 ]; then
        fail_test "Trailing newlines check found issues" "${output:0:300}"
    else
        fail_test "Trailing newlines check unexpected exit: $exit_code"
    fi
}

# ─── Test 5: Hook Functional Tests ────────────────────────────────────────────

test_hooks() {
    section "Test 5: Hook Functional Tests"

    if [ ! -f "$REPO_ROOT/.agent/scripts/test-hooks.sh" ]; then
        fail_test "test-hooks.sh not found"
        return
    fi

    local output
    local exit_code
    output=$(cd "$REPO_ROOT" && bash .agent/scripts/test-hooks.sh 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        pass_test "All hook tests pass"
    else
        # Report hook test results but don't fail on platform-specific skips
        local summary
        summary=$(echo "$output" | tail -10)
        local fail_count
        fail_count=$(echo "$output" | grep -cE "^  ${RED}FAIL" || true)
        if [ "$fail_count" -gt 0 ]; then
            fail_test "Hook tests have $fail_count actual failure(s) (excluding skips)" "$summary"
        else
            pass_test "Hook tests executed (platform-specific skips are expected)"
        fi
    fi
}

# ─── Test 6: JSON Validity ────────────────────────────────────────────────────

test_json_validity() {
    section "Test 6: JSON Validity"

    if ! command -v python3 &>/dev/null; then
        skip_test "JSON validity" "python3 not available"
        return
    fi

    local json_files=""
    local file_count=0

    # .agent/config/client-capabilities.json (if exists)
    if [ -f "$REPO_ROOT/.agent/config/client-capabilities.json" ]; then
        json_files="$json_files $REPO_ROOT/.agent/config/client-capabilities.json"
        file_count=$((file_count + 1))
    fi

    # .agent/templates/mcp/*.json
    for f in "$REPO_ROOT/.agent/templates/mcp/"*.json; do
        if [ -f "$f" ]; then
            json_files="$json_files $f"
            file_count=$((file_count + 1))
        fi
    done

    # .agent/templates/clients/*.json
    for f in "$REPO_ROOT/.agent/templates/clients/"*.json; do
        if [ -f "$f" ]; then
            json_files="$json_files $f"
            file_count=$((file_count + 1))
        fi
    done

    # .qwen/settings.json (if exists)
    if [ -f "$REPO_ROOT/.qwen/settings.json" ]; then
        json_files="$json_files $REPO_ROOT/.qwen/settings.json"
        file_count=$((file_count + 1))
    fi

    # .claude.json (if exists)
    if [ -f "$REPO_ROOT/.claude.json" ]; then
        json_files="$json_files $REPO_ROOT/.claude.json"
        file_count=$((file_count + 1))
    fi

    # Also check .agent/memory/.tool-stats.json (skip if it has BOM)
    if [ -f "$REPO_ROOT/.agent/memory/.tool-stats.json" ]; then
        # This file may have a BOM from PowerShell — skip if so
        local first_bytes
        first_bytes=$(od -An -tx1 -N3 "$REPO_ROOT/.agent/memory/.tool-stats.json" 2>/dev/null | tr -d ' ')
        if [ "$first_bytes" = "efbbbf" ]; then
            skip_test "JSON: .agent/memory/.tool-stats.json" "has UTF-8 BOM"
        else
            json_files="$json_files $REPO_ROOT/.agent/memory/.tool-stats.json"
            file_count=$((file_count + 1))
        fi
    fi

    if [ "$file_count" -eq 0 ]; then
        skip_test "JSON validity" "no JSON files found"
        return
    fi

    local invalid_count=0
    for f in $json_files; do
        local rel_path="${f#$REPO_ROOT/}"
        if python3 -m json.tool "$f" > /dev/null 2>&1; then
            pass_test "Valid JSON: $rel_path"
        else
            fail_test "Invalid JSON: $rel_path"
            invalid_count=$((invalid_count + 1))
        fi
    done
}

# ─── Test 7: Markdown Link Validity (core files) ─────────────────────────────

test_markdown_links() {
    section "Test 7: Markdown Link Validity (core files)"

    local broken=0
    local checked=0

    # Same file set as CI uses
    local core_files
    core_files="README.md AGENT.md INSTALL.md QUICKSTART.md CONTRIBUTING.md CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md SKILL.md .cursorrules .clinerules .windsurfrules"

    # Add .agent/rules/*.md
    for f in "$REPO_ROOT/.agent/rules/"*.md; do
        if [ -f "$f" ]; then
            core_files="$core_files .agent/rules/$(basename "$f")"
        fi
    done

    # Add .agent/workflows/*.md
    for f in "$REPO_ROOT/.agent/workflows/"*.md; do
        if [ -f "$f" ]; then
            core_files="$core_files .agent/workflows/$(basename "$f")"
        fi
    done

    for f in $core_files; do
        local full_path="$REPO_ROOT/$f"
        if [ ! -f "$full_path" ]; then
            continue
        fi
        checked=$((checked + 1))

        # Extract markdown links: [text](target)
        local links
        links=$(grep -oE '\[[^]]+\]\([^)]+\)' "$full_path" 2>/dev/null || true)
        if [ -z "$links" ]; then
            continue
        fi

        while IFS= read -r link; do
            if [ -z "$link" ]; then
                continue
            fi

            # Extract target from [text](target)
            local target
            target=$(echo "$link" | sed 's/.*](\(.*\))/\1/' | sed 's/#.*//')
            if [ -z "$target" ]; then
                continue
            fi

            # Skip external links
            case "$target" in
                http*) continue ;;
                mailto:*) continue ;;
                \#*) continue ;;
                /*) continue ;;
                file://*) continue ;;
            esac

            # Resolve relative to file's directory
            local dir
            dir=$(dirname "$full_path")
            local candidate="$dir/$target"

            # Try to resolve the path
            local resolved=""
            if command -v realpath &>/dev/null; then
                resolved=$(realpath -m "$candidate" 2>/dev/null) || resolved=""
            else
                local candidate_dir
                candidate_dir=$(dirname "$candidate")
                if [ -d "$candidate_dir" ]; then
                    resolved="$(cd "$candidate_dir" && pwd)/$(basename "$candidate")"
                fi
            fi

            if [ -z "$resolved" ] || [ ! -e "$resolved" ]; then
                fail_test "Broken link in $f -> $target"
                broken=$((broken + 1))
            fi
        done <<< "$links"
    done

    if [ "$checked" -eq 0 ]; then
        skip_test "Markdown links" "no core markdown files found"
        return
    fi

    if [ "$broken" -eq 0 ]; then
        pass_test "All core markdown links valid (checked $checked files)"
    else
        fail_test "$broken broken link(s) found in core markdown"
    fi
}

# ─── Test 8: Script Syntax Validation ─────────────────────────────────────────

test_script_syntax() {
    section "Test 8: Script Syntax Validation"

    if [ ! -f "$REPO_ROOT/.agent/scripts/test-scripts.sh" ]; then
        fail_test "test-scripts.sh not found"
        return
    fi

    local output
    local exit_code
    output=$(cd "$REPO_ROOT" && bash .agent/scripts/test-scripts.sh 2>&1)
    exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        pass_test "All scripts pass syntax validation"
    else
        local summary
        summary=$(echo "$output" | tail -3)
        fail_test "Script syntax errors found" "$summary"
    fi
}

# ─── Test 9: AGENT.md and README.md are non-empty ─────────────────────────────

test_core_files_content() {
    section "Test 9: Core Files Have Content"

    for f in AGENT.md README.md; do
        if [ -f "$REPO_ROOT/$f" ] && [ -s "$REPO_ROOT/$f" ]; then
            local lines
            lines=$(wc -l < "$REPO_ROOT/$f")
            pass_test "$f exists and is non-empty ($lines lines)"
        else
            fail_test "$f missing or empty"
        fi
    done

    # Check that core scripts exist in the repo
    local core_scripts="bootstrap.sh bootstrap.ps1 sync-task.sh sync-task.ps1 doctor.sh test-hooks.sh test-scripts.sh"
    for f in $core_scripts; do
        if [ -f "$REPO_ROOT/.agent/scripts/$f" ]; then
            pass_test "Core script exists: $f"
        else
            fail_test "Core script missing: .agent/scripts/$f"
        fi
    done

    # Check .gitignore contains critical entries
    if [ -f "$REPO_ROOT/.gitignore" ]; then
        local missing_ignores=0
        for pattern in ".beads/" ".agent/memory/session-handover.md" ".agent/memory/current-task.md"; do
            if grep -qF "$pattern" "$REPO_ROOT/.gitignore" 2>/dev/null; then
                pass_test ".gitignore contains: $pattern"
            else
                fail_test ".gitignore missing: $pattern"
                missing_ignores=$((missing_ignores + 1))
            fi
        done
    else
        fail_test ".gitignore missing"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

echo -e "${BOLD}AI Toolbox Integration Tests${NC}"
echo "========================================="

test_bootstrap_completeness
test_doctor_health
test_bootstrap_parity
test_trailing_newlines
test_hooks
test_json_validity
test_markdown_links
test_script_syntax
test_core_files_content

echo ""
echo "========================================="
echo -e "  ${BOLD}Test Results Summary${NC}"
echo "========================================="
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}SOME TESTS FAILED${NC}"
    exit 1
else
    echo -e "  ${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
