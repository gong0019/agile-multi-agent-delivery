#!/usr/bin/env bash
# test-validate-prd.sh - Smoke tests for PRD file validation.
# Usage: ./tests/test-validate-prd.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="${SCRIPT_DIR}/../scripts/validate-prd.sh"
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

echo "=== PRD Validation Tests ==="
echo ""

echo "-- Valid PRD files should pass --"
run_test "valid confirmed PRD" "${FIXTURES}/valid-prd.md" "pass"

echo ""
echo "-- Invalid PRD files should fail --"
run_test "missing required fields" "${FIXTURES}/invalid-prd-missing-fields.md" "fail"

echo ""
echo "-- Non-existent file should error --"
if bash "$VALIDATE" "/tmp/nonexistent-prd-$$" 2>/dev/null; then
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
