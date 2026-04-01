#!/bin/bash
cmd="${BASH_COMMAND:-$1}"

if echo "$cmd" | grep -E "^(python|python3|mvn|gradlew|pytest|npm run|pnpm|yarn|db2cli|hdbcli|sqlplus|ansible-playbook|java|cargo|go|docker|docker-compose)" | grep -vq "^rtk "; then
  echo "ERROR: heavy commands should be prefixed with rtk"
  exit 1
fi

if echo "$cmd" | grep -E "^(cat|less|tail|head).*\.log$" | grep -vq "^rtk "; then
  echo "ERROR: use rtk read <file> for large log files"
  exit 1
fi

exit 0
