#!/bin/bash
# lib-atomic-write.sh — PR1: Concurrency-safe helpers for .agent/memory/ writes.
# Source with: . "$(dirname "${BASH_SOURCE[0]}")/lib-atomic-write.sh"
#
# Strategy:
#   - Always write JSON via temp file + os.replace() to prevent truncated/corrupt files.
#   - Use flock(1) for serialization when available (Linux, Homebrew util-linux on macOS).
#   - On systems without flock, atomic rename still prevents corruption;
#     the rare lost-counter-increment is accepted for non-critical stats.
#   - Lock files (*.lock) are transient empty files; add to .gitignore.

# _aitb_json_increment_unlocked FILE TOOL PYTHON
# Inner implementation — must only be called while holding the lock (or on no-flock systems).
_aitb_json_increment_unlocked() {
    local file="$1"
    local tool="$2"
    local py="$3"
    local tmpfile="${file}.tmp.$$"
    TOOL_NAME="$tool" STATS_FILE="$file" TMP_FILE="$tmpfile" \
    "$py" - <<'PYEOF' 2>/dev/null || true
import json, os
tool = os.environ["TOOL_NAME"]
src  = os.environ["STATS_FILE"]
dst  = os.environ["TMP_FILE"]
try:
    with open(src) as f:
        data = json.load(f)
    data[tool] = data.get(tool, 0) + 1
    with open(dst, "w") as f:
        json.dump(data, f)
    os.replace(dst, src)   # atomic rename — no partial write ever visible to readers
except Exception:
    try:
        os.unlink(dst)
    except Exception:
        pass
PYEOF
}

# atomic_json_increment FILE TOOL
# Thread-safe increment of TOOL counter in a JSON stats file at FILE.
# Initializes the file with {"rtk":0,"beads":0,"mcp":0} if it doesn't exist.
atomic_json_increment() {
    local file="$1"
    local tool="$2"

    [ -f "$file" ] || echo '{"rtk": 0, "beads": 0, "mcp": 0}' > "$file"
    [ -f "$file" ] || return 0

    local py
    py=$(command -v python3 2>/dev/null || command -v python 2>/dev/null)
    [ -z "$py" ] && return 0

    if command -v flock >/dev/null 2>&1; then
        # Acquire exclusive lock; flock exits 0 after acquiring, fd stays open in group
        ( flock -x 9; _aitb_json_increment_unlocked "$file" "$tool" "$py" ) \
            9>"${file}.lock"
    else
        # No flock (e.g. macOS without Homebrew util-linux): atomic write still protects
        # against JSON corruption; rare lost increment accepted for stats counters.
        _aitb_json_increment_unlocked "$file" "$tool" "$py"
    fi
}
