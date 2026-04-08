#!/bin/bash
# validate-client-capabilities.sh — validates .agent/config/client-capabilities.json against a schema
# If the file doesn't exist, this check is skipped.

echo "[json-schema] Validating client-capabilities.json..."

CONFIG_FILE=".agent/config/client-capabilities.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[json-schema] SKIP — $CONFIG_FILE not found (optional)"
    exit 0
fi

# Basic JSON validation
if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "FAIL: $CONFIG_FILE is not valid JSON"
    exit 1
fi

# Schema validation — write Python to temp file to avoid quoting issues
VALIDATOR=$(mktemp /tmp/validate_schema.XXXXXX.py)
trap 'rm -f "$VALIDATOR"' EXIT

cat > "$VALIDATOR" << 'PYEOF'
import json
import sys

CONFIG_FILE = ".agent/config/client-capabilities.json"

SCHEMA = {
    "type": "object",
    "required": ["clients"],
    "properties": {
        "tiers": {
            "type": "object",
            "additionalProperties": {
                "type": "object",
                "required": ["description", "clients"],
                "properties": {
                    "description": {"type": "string"},
                    "clients": {"type": "array", "items": {"type": "string"}}
                }
            }
        },
        "clients": {
            "type": "object",
            "additionalProperties": {
                "type": "object",
                "required": ["tier"],
                "properties": {
                    "tier": {"type": "string", "enum": ["basic", "standard", "full"]},
                    "router_file": {"type": "string"},
                    "config_file": {"type": "string"},
                    "hooks": {"type": "boolean"},
                    "multi_agent": {"type": "boolean"},
                    "file_rules": {"type": "boolean"},
                    "plan_mode": {"type": "boolean"},
                    "slash_commands": {"type": "boolean"}
                }
            }
        }
    }
}

TYPE_MAP = {
    "object": dict,
    "array": list,
    "string": str,
    "boolean": bool
}

def validate(data, schema, path="root"):
    errors = []
    expected = TYPE_MAP.get(schema.get("type"))
    if expected and not isinstance(data, expected):
        return ["%s: expected %s, got %s" % (path, schema["type"], type(data).__name__)]

    if schema.get("type") == "object":
        for req in schema.get("required", []):
            if req not in data:
                errors.append("%s: missing required field '%s'" % (path, req))
        for key, vs in schema.get("properties", {}).items():
            if key in data:
                errors.extend(validate(data[key], vs, path + "." + key))
        for key in schema.get("properties", {}):
            if key in data and "enum" in schema["properties"][key]:
                if data[key] not in schema["properties"][key]["enum"]:
                    errors.append("%s.%s: value not in allowed enum" % (path, key))
        if "additionalProperties" in schema:
            known = set(schema.get("properties", {}).keys())
            for key in data:
                if key not in known:
                    errors.extend(validate(data[key], schema["additionalProperties"], path + "." + key))
    elif schema.get("type") == "array" and "items" in schema:
        for i, item in enumerate(data):
            errors.extend(validate(item, schema["items"], "%s[%d]" % (path, i)))
    return errors

with open(CONFIG_FILE) as f:
    data = json.load(f)

errors = validate(data, SCHEMA)
if errors:
    for e in errors:
        print("  SCHEMA ERROR: " + e)
    sys.exit(1)
print("  Schema validation passed")
PYEOF

if ! python3 "$VALIDATOR"; then
    echo "FAIL: client-capabilities.json does not match schema"
    exit 1
fi

echo "[json-schema] OK — client-capabilities.json is valid"
