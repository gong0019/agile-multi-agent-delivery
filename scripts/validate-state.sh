#!/usr/bin/env bash
# validate-state.sh - Validate a state file's YAML frontmatter against the schema.
# Usage: ./scripts/validate-state.sh [path-to-state-file]
#   No argument: validates the active iteration's state.md (via current-state.sh)
# Exit codes: 0 = valid, 1 = invalid, 2 = usage/dependency error

set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA_DIR="${SKILL_ROOT}/schema"
STATE_SCHEMA="${SCHEMA_DIR}/state-file.json"
CURRENT_STATE_SH="${SKILL_ROOT}/scripts/current-state.sh"

# Resolve state file path
if [[ $# -eq 0 ]]; then
  STATE_FILE=$(bash "$CURRENT_STATE_SH" 2>/dev/null) || {
    echo "FAIL: No active iteration found. Run scripts/init-state.sh or pass a file path."
    exit 2
  }
else
  STATE_FILE="$1"
fi

if [[ ! -f "$STATE_FILE" ]]; then
  echo "FAIL: State file not found: $STATE_FILE"
  exit 2
fi

if [[ ! -f "$STATE_SCHEMA" ]]; then
  echo "FAIL: Schema not found: $STATE_SCHEMA"
  exit 2
fi

python3 -c "import yaml" 2>/dev/null || {
  echo "INFO: PyYAML not found — installing automatically..."
  pip3 install --quiet pyyaml || {
    echo "FAIL: Could not install PyYAML. Run manually: pip3 install pyyaml"
    exit 2
  }
}

python3 - "$STATE_FILE" "$STATE_SCHEMA" <<'PYEOF'
import json
import re
import sys
from datetime import datetime

import yaml

state_file_path = sys.argv[1]
schema_path = sys.argv[2]

with open(schema_path, "r", encoding="utf-8") as f:
    schema = json.load(f)

with open(state_file_path, "r", encoding="utf-8") as f:
    content = f.read()

lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    print(f"FAIL: No YAML frontmatter found in {state_file_path}")
    print("HINT: The file must start with --- on the first line.")
    sys.exit(1)

end_idx = None
for i in range(1, len(lines)):
    if lines[i].strip() == "---":
        end_idx = i
        break

if end_idx is None:
    print(f"FAIL: Frontmatter closing delimiter not found in {state_file_path}")
    sys.exit(1)

frontmatter_str = "\n".join(lines[1:end_idx]).strip()
if not frontmatter_str:
    print(f"FAIL: Empty YAML frontmatter in {state_file_path}")
    sys.exit(1)

try:
    data = yaml.safe_load(frontmatter_str)
except Exception as e:
    print(f"FAIL: Could not parse frontmatter YAML: {e}")
    sys.exit(1)

if not isinstance(data, dict):
    print("FAIL: YAML frontmatter root must be an object/map")
    sys.exit(1)

errors = []


def type_ok(expected, value):
    if isinstance(value, bool) and expected in ("integer", "number"):
        return False
    mapping = {
        "object": dict,
        "array": list,
        "string": str,
        "integer": int,
        "number": (int, float),
        "boolean": bool,
    }
    t = mapping.get(expected)
    return isinstance(value, t) if t else True


def check_datetime(value, path):
    if not isinstance(value, str):
        errors.append(f"FAIL: Field '{path}' must be a string in date-time format")
        return
    try:
        if value.endswith("Z"):
            datetime.fromisoformat(value.replace("Z", "+00:00"))
            return
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            errors.append(f"FAIL: Field '{path}' must include timezone (e.g. Z or +00:00)")
    except Exception:
        errors.append(f"FAIL: Field '{path}' value '{value}' is not a valid date-time")


def validate(node, node_schema, path):
    schema_type = node_schema.get("type")
    if schema_type and not type_ok(schema_type, node):
        errors.append(f"FAIL: Field '{path}' must be type '{schema_type}'")
        return

    if "enum" in node_schema and node not in node_schema["enum"]:
        errors.append(f"FAIL: Field '{path}' value '{node}' not in allowed values: {node_schema['enum']}")

    if isinstance(node, str):
        if "minLength" in node_schema and len(node) < node_schema["minLength"]:
            errors.append(f"FAIL: Field '{path}' is empty or too short")
        if "pattern" in node_schema and not re.match(node_schema["pattern"], node):
            errors.append(f"FAIL: Field '{path}' value '{node}' does not match pattern {node_schema['pattern']}")
        if node_schema.get("format") == "date-time":
            check_datetime(node, path)

    if isinstance(node, list):
        if "minItems" in node_schema and len(node) < node_schema["minItems"]:
            errors.append(f"FAIL: Field '{path}' must have at least {node_schema['minItems']} items, has {len(node)}")
        item_schema = node_schema.get("items")
        if item_schema:
            for i, item in enumerate(node):
                validate(item, item_schema, f"{path}[{i}]")

    if isinstance(node, dict):
        required = node_schema.get("required", [])
        missing = [f for f in required if f not in node]
        if missing:
            errors.append(f"FAIL: Field '{path}' missing required keys: {', '.join(missing)}")
        props = node_schema.get("properties", {})
        for key, value in node.items():
            if key in props:
                next_path = f"{path}.{key}" if path else key
                validate(value, props[key], next_path)


validate(data, schema, "")

# Consistency check: overall_completion must match slice board within 10%
if "slice_board" in data and isinstance(data["slice_board"], list):
    done_count = sum(1 for s in data["slice_board"] if isinstance(s, dict) and s.get("status") == "done")
    total = len(data["slice_board"])
    if total > 0:
        expected_raw = data.get("overall_completion", "0%")
        if isinstance(expected_raw, str) and expected_raw.endswith("%"):
            expected_pct = int(expected_raw.rstrip("%"))
        else:
            expected_pct = 0
        done_pct = round(done_count / total * 100)
        if abs(expected_pct - done_pct) > 10:
            errors.append(
                f"FAIL: overall_completion ({expected_pct}%) is inconsistent with slice board "
                f"({done_count}/{total} slices done = {done_pct}%). "
                f"Update overall_completion or fix slice statuses."
            )

if errors:
    for err in errors:
        print(err)
    sys.exit(1)

print(f"PASS: State file is valid ({len(data)} top-level fields validated)")
sys.exit(0)
PYEOF
