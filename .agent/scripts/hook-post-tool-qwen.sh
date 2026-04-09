#!/bin/bash
# hook-post-tool-qwen.sh - Qwen Code PostToolUse hook for Unix/Linux/macOS
# Triggered after write/edit tool execution.
# Scans written files for secrets, credentials, or sensitive patterns.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

INPUT=$(cat 2>/dev/null)
if [ -z "$INPUT" ]; then
    echo '{"decision":"allow","reason":"No input received"}'
    exit 0
fi

# Extract file_path from tool_input using python3 or jq
FILE_PATH=""
if command -v python3 &>/dev/null; then
    FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', '') if isinstance(ti, dict) else '')
" 2>/dev/null)
elif command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
fi

if [ -z "$FILE_PATH" ]; then
    echo '{"decision":"allow","reason":"No file path detected"}'
    exit 0
fi

# Path validation: only allow files within the repository (resolved symlinks)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVED=$(realpath -m -- "$FILE_PATH" 2>/dev/null || echo "")
RESOLVED_ROOT=$(realpath -m -- "$REPO_ROOT" 2>/dev/null || echo "")
case "$RESOLVED" in
  "$RESOLVED_ROOT"/*) ;;
  *) echo '{"decision":"allow","reason":"File outside repository"}' ; exit 0 ;;
esac

# Security patterns to scan for in written files
SECRET_FOUND=""
if [ -f "$FILE_PATH" ]; then
    # Check for common secret patterns (skip patterns with 8+ char secrets)
    if grep -qiE '(password|passwd|pwd)\s*[=:]\s*["'"'"'][^"'"'"']{8,}' "$FILE_PATH" 2>/dev/null; then
        SECRET_FOUND="${SECRET_FOUND}password,"
    fi
    if grep -qiE '(api[_-]?key|apikey)\s*[=:]\s*["'"'"'][^"'"'"']{8,}' "$FILE_PATH" 2>/dev/null; then
        SECRET_FOUND="${SECRET_FOUND}api_key,"
    fi
    if grep -qiE '(secret|token|auth[_-]?key)\s*[=:]\s*["'"'"'][^"'"'"']{8,}' "$FILE_PATH" 2>/dev/null; then
        SECRET_FOUND="${SECRET_FOUND}secret,"
    fi
    if grep -qE 'BEGIN\s+(RSA|DSA|EC|OPENSSH)\s+PRIVATE\s+KEY' "$FILE_PATH" 2>/dev/null; then
        SECRET_FOUND="${SECRET_FOUND}private_key,"
    fi
    if grep -qiE '(connection[_-]?string|database[_-]?url)\s*[=:]\s*["'"'"'][^"'"'"']{8,}' "$FILE_PATH" 2>/dev/null; then
        SECRET_FOUND="${SECRET_FOUND}connection_string,"
    fi
fi

if [ -n "$SECRET_FOUND" ]; then
    if command -v python3 &>/dev/null; then
        python3 -c "
import json
print(json.dumps({
    'decision': 'allow',
    'reason': 'Potential secrets detected',
    'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext': 'AI Toolbox Security: Potential secrets detected in ${FILE_PATH} (patterns: ${SECRET_FOUND}). Please verify these are not accidental credentials. If they are placeholders or test fixtures, add a comment explaining this.'
    }
}))
"
    else
        echo "{\"decision\":\"allow\",\"reason\":\"Potential secrets detected\",\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"AI Toolbox Security: Potential secrets detected in $FILE_PATH (patterns: $SECRET_FOUND). Please verify.\"}}"
    fi
else
    echo '{"decision":"allow","reason":"Security check passed"}'
fi
exit 0
