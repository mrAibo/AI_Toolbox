#!/bin/bash
# AI Toolbox Pre-command hook
# Usage: .agent/scripts/hook-pre-command.sh "command to run"
# 
# This hook should be called by the AI Agent BEFORE executing a command.
# It checks if the command is "heavy" and recommends the 'rtk' wrapper.

cmd="$1"

HEAVY_COMMAND_REGEX="^(python|python3|mvn|gradlew|pytest|npm run|pnpm|yarn|db2cli|hdbcli|sqlplus|ansible-playbook|java |cargo|go |docker|docker-compose)"

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

exit 0
