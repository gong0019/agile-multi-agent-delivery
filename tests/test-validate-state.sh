#!/usr/bin/env bash
# test-validate-state.sh - Smoke tests for state file validation.
# Usage: ./tests/test-validate-state.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="${SCRIPT_DIR}/../scripts/validate-state.sh"
FIXTURES="${SCRIPT_DIR}/fixtures"

PASSED=0
FAILED=0

run_test() {
  local name="$1"
  local file="$2"
  local expect_pass="$3"  # "pass" or "fail"

  if bash "$VALIDATE" "$file" > /dev/null 2>&1; then
    actual="pass"
  else
    actual="fail"
  fi

  if [[ "$actual" == "$expect_pass" ]]; then
    echo "  PASS: $name"
    PASSED=$((PASSED + 1))
  else
    echo "  FAIL: $name (expected ${expect_pass}, got ${actual})"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== State Validation Tests ==="
echo ""

echo "-- Valid state files should pass --"
run_test "valid state with frontmatter" "${FIXTURES}/valid-state.md" "pass"

echo ""
echo "-- Invalid state files should fail --"
run_test "no frontmatter" "${FIXTURES}/invalid-state.md" "fail"
run_test "bad patterns and empty arrays" "${FIXTURES}/invalid-state-with-frontmatter.md" "fail"
run_test "invalid datetime format" "${FIXTURES}/invalid-state-bad-datetime.md" "fail"
run_test "wrong field types" "${FIXTURES}/invalid-state-wrong-types.md" "fail"

echo ""
echo "-- Non-existent file should error --"
if bash "$VALIDATE" "/tmp/nonexistent-state-$$" 2>/dev/null; then
  echo "  FAIL: non-existent file should have errored"
  FAILED=$((FAILED + 1))
else
  echo "  PASS: non-existent file correctly rejected"
  PASSED=$((PASSED + 1))
fi

echo ""
echo "Results: ${PASSED} passed, ${FAILED} failed"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
