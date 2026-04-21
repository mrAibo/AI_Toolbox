#!/bin/bash
# validate-adr.sh — validates ADR files in .agent/memory/adrs/.
# Checks required fields, status values, and ISO-8601 date format.
# Accepts both plain ("- Status:") and bold ("- **Status:**") field formats.
#
# Exit codes: 0 = valid (or no ADRs found), 1 = validation failure

set -u

ADR_DIR=".agent/memory/adrs"
VALID_STATUSES="proposed accepted rejected replaced deprecated"
FAIL=0
TOTAL=0

echo "[validate-adr] Validating ADRs in ${ADR_DIR}..."

if [ ! -d "$ADR_DIR" ]; then
    echo "[validate-adr] SKIP — ${ADR_DIR} not found"
    exit 0
fi

for adr_file in "$ADR_DIR"/*.md; do
    [ -f "$adr_file" ] || continue
    TOTAL=$((TOTAL + 1))
    bname=$(basename "$adr_file")

    # Required fields — accept "- Status:" and "- **Status:**" formats
    for field in Status Date Context Decision Consequences; do
        if ! grep -qiE "^[[:space:]]*-[[:space:]]+\*?\*?${field}\*?\*?:" "$adr_file"; then
            echo "  FAIL ${bname}: missing required field '${field}'"
            FAIL=$((FAIL + 1))
        fi
    done

    # Validate Status value is one of the known statuses
    status_line=$(grep -iE "^[[:space:]]*-[[:space:]]+\*?\*?Status\*?\*?:" "$adr_file" | head -1)
    if [ -n "$status_line" ]; then
        status_val=$(echo "$status_line" | sed -E 's/.*Status\*?\*?:[[:space:]]*//' | tr -d '*' | tr '[:upper:]' '[:lower:]' | xargs)
        valid=0
        for s in $VALID_STATUSES; do
            [ "$status_val" = "$s" ] && valid=1 && break
        done
        if [ "$valid" -eq 0 ]; then
            echo "  FAIL ${bname}: Status '${status_val}' not valid (must be one of: ${VALID_STATUSES})"
            FAIL=$((FAIL + 1))
        fi
    fi

    # Validate Date is ISO-8601 (YYYY-MM-DD)
    date_line=$(grep -iE "^[[:space:]]*-[[:space:]]+\*?\*?Date\*?\*?:" "$adr_file" | head -1)
    if [ -n "$date_line" ]; then
        date_val=$(echo "$date_line" | sed -E 's/.*Date\*?\*?:[[:space:]]*//' | tr -d '*' | xargs)
        if ! echo "$date_val" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
            echo "  FAIL ${bname}: Date '${date_val}' is not ISO-8601 format (YYYY-MM-DD)"
            FAIL=$((FAIL + 1))
        fi
    fi
done

if [ "$TOTAL" -eq 0 ]; then
    echo "[validate-adr] SKIP — no ADR files found in ${ADR_DIR}"
    exit 0
fi

echo "[validate-adr] Results: ${TOTAL} ADR(s) checked, ${FAIL} failure(s)"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

echo "[validate-adr] OK — all ADRs valid"
exit 0
