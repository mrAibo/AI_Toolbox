#!/bin/bash
# AI Toolbox Pre-command hook
# Usage: .agent/scripts/hook-pre-command.sh "command to run"
#
# This hook should be called by the AI Agent BEFORE executing a command.
# It checks if the command is "heavy" and recommends the 'rtk' wrapper,
# and tracks tool usage for session statistics.

cmd="$1"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATS_FILE="$REPO_ROOT/.agent/memory/.tool-stats.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-audit.sh
. "$SCRIPT_DIR/lib-audit.sh"

HEAVY_COMMAND_REGEX="^(python|python3|mvn|gradle|gradlew|pytest|npm run|npm test|pnpm run|pnpm test|yarn run|yarn test|db2cli|hdbcli|sqlplus|ansible-playbook|javac|java -jar|cargo build|cargo test|cargo run|cargo check|go build|go test|go run|docker build|docker compose build|docker-compose build)"

# Normalize: strip leading whitespace and env/VAR=val prefixes to prevent trivial bypasses.
# Handles: "  python", "env python", "VAR=1 python".
_cmd_norm="$(printf '%s' "$cmd" | sed 's/^[[:space:]]*//' | sed 's/^env[[:space:]]*//' | sed 's/^\([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]*\)*//')"

if [[ $_cmd_norm =~ $HEAVY_COMMAND_REGEX ]] && [[ $_cmd_norm != "rtk "* ]]; then
  echo "[WARN] AI Toolbox Heavy Command Detected!"
  echo "Please use 'rtk' wrapper for heavy commands to optimize token usage."
  echo "Example: rtk $cmd"
  audit_event "heavy_cmd_blocked" "tool=${_cmd_norm%% *}"
  exit 1
fi

if [[ $_cmd_norm =~ ^(cat|less|tail|head)\ .+\.log$ ]] && [[ $_cmd_norm != "rtk "* ]]; then
  echo "[WARN] AI Toolbox: Large log file detected!"
  echo "Please use 'rtk read <file-path>' to read large logs efficiently."
  exit 1
fi

# Warn (advisory, non-blocking) when cat-ing large source files
if [[ $_cmd_norm =~ ^cat\ .+\.(ts|tsx|py|rs|go|js|jsx|java|cs|cpp|c)$ ]]; then
  _src_file="${_cmd_norm#cat }"
  if [ -f "$_src_file" ] && [ "$(wc -l < "$_src_file" 2>/dev/null)" -gt 200 ]; then
    echo "[WARN] AI Toolbox: Large source file (>200 lines) — consider 'git diff' or symbol context instead of full read."
    echo "  See .agent/rules/diff-editing.md — Input Context Budget"
  fi
fi

# Track tool usage for session statistics
# PR1: Uses lib-atomic-write.sh for concurrency-safe JSON updates.
# shellcheck source=lib-atomic-write.sh
. "$SCRIPT_DIR/lib-atomic-write.sh"

track_tool() {
  local tool="$1"
  atomic_json_increment "$STATS_FILE" "$tool"
}

# Detect which tool is being used
case "$cmd" in
  *rtk*test*|*rtk*build*|*rtk*lint*|rtk\ *) track_tool "rtk" ;;
  *bd\ create*|*bd\ ready*|*bd\ list*|*bd\ close*|bd\ *) track_tool "beads" ;;
  *claude\ mcp*|*context7*|*sequential-thinking*) track_tool "mcp" ;;
esac

exit 0
