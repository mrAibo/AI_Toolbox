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

HEAVY_COMMAND_REGEX="^(python|python3|mvn|gradle|gradlew|pytest|npm run|npm test|pnpm run|pnpm test|yarn run|yarn test|db2cli|hdbcli|sqlplus|ansible-playbook|javac|java -jar|cargo build|cargo test|cargo run|cargo check|go build|go test|go run|docker build|docker compose build|docker-compose build)"

if [[ $cmd =~ $HEAVY_COMMAND_REGEX ]] && [[ $cmd != "rtk "* ]]; then
  echo "[WARN] AI Toolbox Heavy Command Detected!"
  echo "Please use 'rtk' wrapper for heavy commands to optimize token usage."
  echo "Example: rtk $cmd"
  exit 1
fi

if [[ $cmd =~ ^(cat|less|tail|head)\ .+\.log$ ]] && [[ $cmd != "rtk "* ]]; then
  echo "[WARN] AI Toolbox: Large log file detected!"
  echo "Please use 'rtk read <file-path>' to read large logs efficiently."
  exit 1
fi

# Track tool usage for session statistics
track_tool() {
  local tool="$1"
  local file="$STATS_FILE"
  # Initialize stats file if missing
  if [ ! -f "$file" ]; then
    echo '{"rtk": 0, "beads": 0, "mcp": 0}' > "$file"
  fi
  # Increment counter using portable approach (no sed -i compatibility issues)
  if [ -f "$file" ]; then
    count=$(grep -o "\"$tool\": [0-9]*" "$file" 2>/dev/null | grep -o '[0-9]*' || echo "0")
    count=$((count + 1))
    # Use python3/python for portable JSON update, fallback to sed
    if command -v python3 &>/dev/null; then
      export TOOL_NAME="$tool"
      export STATS_FILE="$file"
      python3 -c "
import json, os
tool = os.environ.get('TOOL_NAME', '')
fpath = os.environ.get('STATS_FILE', '')
if tool and fpath:
    try:
        with open(fpath) as f: data = json.load(f)
        data[tool] = data.get(tool, 0) + 1
        with open(fpath, 'w') as f: json.dump(data, f)
    except Exception: pass
" 2>/dev/null || true
    elif command -v python &>/dev/null; then
      export TOOL_NAME="$tool"
      export STATS_FILE="$file"
      python -c "
import json, os
tool = os.environ.get('TOOL_NAME', '')
fpath = os.environ.get('STATS_FILE', '')
if tool and fpath:
    try:
        with open(fpath) as f: data = json.load(f)
        data[tool] = data.get(tool, 0) + 1
        with open(fpath, 'w') as f: json.dump(data, f)
    except Exception: pass
" 2>/dev/null || true
    else
      # Fallback: use sed with platform detection
      if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "s/\"$tool\": [0-9]*/\"$tool\": $count/" "$file" 2>/dev/null || true
      else
        sed -i '' "s/\"$tool\": [0-9]*/\"$tool\": $count/" "$file" 2>/dev/null || true
      fi
    fi
  fi
}

# Detect which tool is being used
case "$cmd" in
  *rtk*test*|*rtk*build*|*rtk*lint*|rtk\ *) track_tool "rtk" ;;
  *bd\ create*|*bd\ ready*|*bd\ list*|*bd\ close*|bd\ *) track_tool "beads" ;;
  *claude\ mcp*|*context7*|*sequential-thinking*) track_tool "mcp" ;;
esac

exit 0
