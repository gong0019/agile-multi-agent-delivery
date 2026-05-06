#!/usr/bin/env bash
# check-constraints.sh - Verify key harness invariants on the state file.
# Usage: ./scripts/check-constraints.sh [path-to-state-file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_STATE_FILE="./current-iteration.md"
STATE_FILE="${1:-$DEFAULT_STATE_FILE}"
ERRORS=0

echo "=== Harness Constraint Check ==="
echo ""

# 1. State file exists
if [[ ! -f "$STATE_FILE" ]]; then
  echo "FAIL: State file not found: $STATE_FILE"
  exit 1
fi
echo "PASS: State file exists"

# 2. State file passes schema validation
if bash "${SCRIPT_DIR}/validate-state.sh" "$STATE_FILE" > /dev/null 2>&1; then
  echo "PASS: State file schema valid"
else
  echo "FAIL: State file schema validation failed"
  ERRORS=$((ERRORS + 1))
fi

# 3. Next resume prompt is not empty
if grep -q 'next_resume_prompt:.*[a-zA-Z0-9]' "$STATE_FILE" 2>/dev/null; then
  echo "PASS: Next resume prompt is set"
else
  echo "FAIL: Next resume prompt is empty or missing"
  ERRORS=$((ERRORS + 1))
fi

# 4. No more than 3 slices in_progress at once (concurrency guard)
IN_PROGRESS_COUNT=$(grep -c 'status:.*in_progress' "$STATE_FILE" 2>/dev/null || true)
if [[ "$IN_PROGRESS_COUNT" -le 3 ]]; then
  echo "PASS: In-progress slice count is ${IN_PROGRESS_COUNT} (max 3)"
else
  echo "WARN: ${IN_PROGRESS_COUNT} slices in progress (recommended max: 3)"
fi

# 5. At least one acceptance criterion defined
if grep -q 'AC-' "$STATE_FILE" 2>/dev/null; then
  echo "PASS: Acceptance criteria are defined"
else
  echo "FAIL: No acceptance criteria found"
  ERRORS=$((ERRORS + 1))
fi

# 6. Skill version is recorded
if grep -q 'skill_version:' "$STATE_FILE" 2>/dev/null; then
  SKILL_VER=$(grep 'skill_version:' "$STATE_FILE" | head -1 | sed 's/.*skill_version: *//' | tr -d '"' | tr -d "'")
  echo "PASS: Skill version recorded: ${SKILL_VER}"
else
  echo "FAIL: Skill version not recorded in state file"
  ERRORS=$((ERRORS + 1))
fi

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "RESULT: ${ERRORS} constraint violation(s) found"
  exit 1
else
  echo "RESULT: All constraints satisfied"
  exit 0
fi
