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

# Schema validation using Python
if ! python3 << 'PYTHON_SCRIPT'; then
    echo "FAIL: client-capabilities.json does not match schema"
    exit 1
fi

import json
import sys

CONFIG_FILE = ".agent/config/client-capabilities.json"

SCHEMA = {
    "type": "object",
    "required": ["clients"],
    "properties": {
        "clients": {
            "type": "object",
            "additionalProperties": {
                "type": "object",
                "required": ["tier", "features"],
                "properties": {
                    "tier": {
                        "type": "string",
                        "enum": ["basic", "standard", "full"]
                    },
                    "features": {
                        "type": "array",
                        "items": {"type": "string"}
                    },
                    "hooks": {
                        "type": "boolean"
                    },
                    "multi_agent": {
                        "type": "boolean"
                    },
                    "plan_mode": {
                        "type": "boolean"
                    }
                }
            }
        }
    }
}

def validate_type(value, expected_type):
    if expected_type == "object":
        return isinstance(value, dict)
    elif expected_type == "array":
        return isinstance(value, list)
    elif expected_type == "string":
        return isinstance(value, str)
    elif expected_type == "boolean":
        return isinstance(value, bool)
    return True

def validate_json(data, schema, path=""):
    errors = []

    if "type" in schema:
        if not validate_type(data, schema["type"]):
            errors.append(f"{path or 'root'}: expected type '{schema['type']}', got '{type(data).__name__}'")
            return errors

    if schema.get("type") == "object":
        for req in schema.get("required", []):
            if req not in data:
                errors.append(f"{path or 'root'}: missing required field '{req}'")

        for key, value_schema in schema.get("properties", {}).items():
            if key in data:
                errors.extend(validate_json(data[key], value_schema, f"{path}.{key}" if path else key))

        for key in schema.get("properties", {}):
            if key in data and "enum" in schema["properties"][key]:
                if data[key] not in schema["properties"][key]["enum"]:
                    errors.append(f"{path}.{key}: value '{data[key]}' not in {schema['properties'][key]['enum']}")

        if "additionalProperties" in schema:
            known_keys = set(schema.get("properties", {}).keys())
            for key in data:
                if key not in known_keys:
                    errors.extend(validate_json(data[key], schema["additionalProperties"], f"{path}.{key}" if path else key))

    elif schema.get("type") == "array" and "items" in schema:
        for i, item in enumerate(data):
            errors.extend(validate_json(item, schema["items"], f"{path}[{i}]"))

    return errors

with open(CONFIG_FILE) as f:
    data = json.load(f)

errors = validate_json(data, SCHEMA)

if errors:
    for err in errors:
        print(f"  SCHEMA ERROR: {err}")
    sys.exit(1)

print("  Schema validation passed")
PYTHON_SCRIPT

echo "[json-schema] OK — client-capabilities.json is valid"
