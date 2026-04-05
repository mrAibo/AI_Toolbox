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

HEAVY_COMMAND_REGEX="^(python|python3|mvn|gradle|gradlew|pytest|npm run|pnpm|yarn|db2cli|hdbcli|sqlplus|ansible-playbook|java |cargo|go |docker|docker-compose)"

if echo "$cmd" | grep -qE "$HEAVY_COMMAND_REGEX" && ! echo "$cmd" | grep -q "^rtk "; then
  echo "🚨 AI Toolbox Heavy Command Detected!"
  echo "Please use 'rtk' wrapper for heavy commands to optimize token usage."
  echo "Example: rtk $cmd"
  exit 1
fi

if echo "$cmd" | grep -qE "^(cat|less|tail|head) .+\.log" && ! echo "$cmd" | grep -q "^rtk "; then
  echo "🚨 AI Toolbox: Large log file detected!"
  echo "Please use 'rtk read <file-path>' to read large logs efficiently."
  exit 1
fi

# Track tool usage for session statistics
track_tool() {
  local tool="$1"
  local file="$STATS_FILE"
  if [ -f "$file" ]; then
    # Simple increment — in production use jq
    count=$(grep -o "\"$tool\": [0-9]*" "$file" 2>/dev/null | grep -o '[0-9]*' || echo "0")
    count=$((count + 1))
    sed -i "s/\"$tool\": [0-9]*/\"$tool\": $count/" "$file" 2>/dev/null || true
  fi
}

# Detect which tool is being used
case "$cmd" in
  *rtk*test*|*rtk*build*|*rtk*lint*) track_tool "rtk" ;;
  *bd\ create*|*bd\ ready*|*bd\ list*|*bd\ close*) track_tool "beads" ;;
  *claude\ mcp*|*context7*|*sequential-thinking*) track_tool "mcp" ;;
esac

exit 0
