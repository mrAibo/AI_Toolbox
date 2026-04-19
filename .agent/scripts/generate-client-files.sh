#!/usr/bin/env bash
# generate-client-files.sh — Unix wrapper around the Python3 generator.
# Usage: bash .agent/scripts/generate-client-files.sh --check | --sync
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/generate_client_files.py" "$@"
