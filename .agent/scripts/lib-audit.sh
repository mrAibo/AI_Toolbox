#!/bin/bash
# Append-only audit log helper — source into hook scripts.
# Usage: source lib-audit.sh; audit_event "event_name" "key=val pairs"
# Log:   .agent/memory/audit.log  (gitignored via *.log — local only)
#
# Events are one line each:  TIMESTAMP | EVENT | CONTEXT
# Never put secrets or full command arguments in CONTEXT — use short labels only.

audit_event() {
  local event="${1:-unknown}"
  local ctx="${2:-}"
  local repo
  repo="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  local log="$repo/.agent/memory/audit.log"
  printf '%s | %s | %s\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    "$event" \
    "$ctx" >> "$log" 2>/dev/null || true
}
