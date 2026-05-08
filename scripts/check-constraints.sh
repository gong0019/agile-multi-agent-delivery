#!/usr/bin/env bash
# check-constraints.sh - Verify key harness invariants on the state file.
# Usage: ./scripts/check-constraints.sh [path-to-state-file]
#   No argument: checks the active iteration's state.md (via current-state.sh)

set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURRENT_STATE_SH="${SKILL_ROOT}/scripts/current-state.sh"
VALIDATE_SH="${SKILL_ROOT}/scripts/validate-state.sh"

python3 -c "import yaml" 2>/dev/null || {
  echo "INFO: PyYAML not found — installing automatically..."
  pip3 install --quiet pyyaml || {
    echo "FAIL: Could not install PyYAML. Run manually: pip3 install pyyaml"
    exit 2
  }
}

# Resolve state file path
if [[ $# -eq 0 ]]; then
  STATE_FILE=$(bash "$CURRENT_STATE_SH" 2>/dev/null) || {
    echo "FAIL: No active iteration found. Run scripts/init-state.sh or pass a file path."
    exit 1
  }
else
  STATE_FILE="$1"
fi

ERRORS=0

echo "=== Harness Constraint Check ==="
echo "    File: ${STATE_FILE}"
echo ""

# 1. State file exists
if [[ ! -f "$STATE_FILE" ]]; then
  echo "FAIL: State file not found: $STATE_FILE"
  exit 1
fi
echo "PASS: State file exists"

# 2. State file passes schema validation
if bash "$VALIDATE_SH" "$STATE_FILE" > /dev/null 2>&1; then
  echo "PASS: State file schema valid"
else
  echo "FAIL: State file schema validation failed (run validate-state.sh for details)"
  ERRORS=$((ERRORS + 1))
fi

# 3. Next resume prompt is not empty (YAML-aware)
RESUME_PROMPT=$(python3 - "$STATE_FILE" <<'PYEOF' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    print("")
    sys.exit(0)
with open(sys.argv[1], "r") as f:
    content = f.read()
lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    print("")
    sys.exit(0)
end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end_idx is None:
    print("")
    sys.exit(0)
try:
    data = yaml.safe_load("\n".join(lines[1:end_idx]))
    val = data.get("next_resume_prompt", "") if isinstance(data, dict) else ""
    print(str(val).strip() if val else "")
except Exception:
    print("")
PYEOF
)
if [[ -n "$RESUME_PROMPT" ]]; then
  echo "PASS: Next resume prompt is set"
else
  echo "FAIL: Next resume prompt is empty or missing"
  ERRORS=$((ERRORS + 1))
fi

# 4. No more than 3 slices in_progress at once (YAML-aware, not grep)
IN_PROGRESS_COUNT=$(python3 - "$STATE_FILE" <<'PYEOF' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    print(0)
    sys.exit(0)
with open(sys.argv[1], "r") as f:
    content = f.read()
lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    print(0)
    sys.exit(0)
end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end_idx is None:
    print(0)
    sys.exit(0)
try:
    data = yaml.safe_load("\n".join(lines[1:end_idx]))
    if isinstance(data, dict) and "slice_board" in data:
        count = sum(
            1 for s in data["slice_board"]
            if isinstance(s, dict) and s.get("status") == "in_progress"
        )
        print(count)
    else:
        print(0)
except Exception:
    print(0)
PYEOF
)
if [[ "$IN_PROGRESS_COUNT" -le 3 ]]; then
  echo "PASS: In-progress slice count is ${IN_PROGRESS_COUNT} (max 3)"
else
  echo "WARN: ${IN_PROGRESS_COUNT} slices in progress (recommended max: 3)"
fi

# 5. At least one acceptance criterion defined (YAML-aware)
AC_COUNT=$(python3 - "$STATE_FILE" <<'PYEOF' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    print(0)
    sys.exit(0)
with open(sys.argv[1], "r") as f:
    content = f.read()
lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    print(0)
    sys.exit(0)
end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end_idx is None:
    print(0)
    sys.exit(0)
try:
    data = yaml.safe_load("\n".join(lines[1:end_idx]))
    if isinstance(data, dict) and isinstance(data.get("acceptance_criteria"), list):
        print(len(data["acceptance_criteria"]))
    else:
        print(0)
except Exception:
    print(0)
PYEOF
)
if [[ "$AC_COUNT" -gt 0 ]]; then
  echo "PASS: Acceptance criteria are defined (${AC_COUNT} found)"
else
  echo "FAIL: No acceptance criteria found"
  ERRORS=$((ERRORS + 1))
fi

# 6. Skill version is recorded
SKILL_VER=$(python3 - "$STATE_FILE" <<'PYEOF' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    print("")
    sys.exit(0)
with open(sys.argv[1], "r") as f:
    content = f.read()
lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    print("")
    sys.exit(0)
end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end_idx is None:
    print("")
    sys.exit(0)
try:
    data = yaml.safe_load("\n".join(lines[1:end_idx]))
    print(str(data.get("skill_version", "")).strip() if isinstance(data, dict) else "")
except Exception:
    print("")
PYEOF
)
if [[ -n "$SKILL_VER" ]]; then
  echo "PASS: Skill version recorded: ${SKILL_VER}"
else
  echo "FAIL: Skill version not recorded in state file"
  ERRORS=$((ERRORS + 1))
fi

# 7. In BUILDING phase: no two slices share the same file (ownership conflict detection)
CONFLICT_OUTPUT=$(python3 - "$STATE_FILE" <<'PYEOF' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
with open(sys.argv[1], "r") as f:
    content = f.read()
lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    sys.exit(0)
end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end_idx is None:
    sys.exit(0)
try:
    data = yaml.safe_load("\n".join(lines[1:end_idx]))
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)
if data.get("phase") != "BUILDING":
    sys.exit(0)
slices = data.get("slice_board", [])
seen = {}
conflicts = []
for s in slices:
    if not isinstance(s, dict):
        continue
    sid = s.get("id", "?")
    for f in s.get("files", []):
        if f in seen:
            conflicts.append(f"  File '{f}' claimed by both {seen[f]} and {sid}")
        else:
            seen[f] = sid
if conflicts:
    print("FAIL: File ownership conflicts detected in BUILDING phase:")
    for c in conflicts:
        print(c)
    sys.exit(1)
else:
    print(f"PASS: No file ownership conflicts ({len(seen)} files across {len(slices)} slices)")
PYEOF
)
CONFLICT_EXIT=$?
if [[ -n "$CONFLICT_OUTPUT" ]]; then
  echo "$CONFLICT_OUTPUT"
fi
if [[ $CONFLICT_EXIT -ne 0 ]]; then
  ERRORS=$((ERRORS + 1))
fi

# 8. CURRENT pointer in .agile/ is consistent with this state file's iteration_version
ITER_DIR=$(dirname "$STATE_FILE")
AGILE_DIR=$(dirname "$ITER_DIR")
CURRENT_FILE="${AGILE_DIR}/CURRENT"
if [[ -f "$CURRENT_FILE" ]]; then
  CURRENT_ID=$(tr -d '[:space:]' < "$CURRENT_FILE")
  STATE_ITER=$(python3 - "$STATE_FILE" <<'PYEOF' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    print("")
    sys.exit(0)
with open(sys.argv[1], "r") as f:
    content = f.read()
lines = content.splitlines()
if not lines or lines[0].strip() != "---":
    print("")
    sys.exit(0)
end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
if end_idx is None:
    print("")
    sys.exit(0)
try:
    data = yaml.safe_load("\n".join(lines[1:end_idx]))
    print(str(data.get("iteration_version", "")).strip() if isinstance(data, dict) else "")
except Exception:
    print("")
PYEOF
)
  if [[ -n "$STATE_ITER" && -n "$CURRENT_ID" ]]; then
    if [[ "$STATE_ITER" == "$CURRENT_ID" ]]; then
      echo "PASS: CURRENT pointer matches iteration_version (${CURRENT_ID})"
    else
      echo "WARN: CURRENT points to '${CURRENT_ID}' but this file is '${STATE_ITER}'"
    fi
  fi
fi

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "RESULT: ${ERRORS} constraint violation(s) found"
  exit 1
else
  echo "RESULT: All constraints satisfied"
  exit 0
fi
