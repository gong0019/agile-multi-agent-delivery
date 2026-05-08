#!/usr/bin/env bash
# test-agile-dir.sh - Integration tests for .agile/ directory structure and CURRENT pointer.
# Usage: ./tests/test-agile-dir.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INIT="${REPO_ROOT}/scripts/init-state.sh"
CURRENT="${REPO_ROOT}/scripts/current-state.sh"
VALIDATE="${REPO_ROOT}/scripts/validate-state.sh"
LIST="${REPO_ROOT}/scripts/list-iterations.sh"
CHECK="${REPO_ROOT}/scripts/check-constraints.sh"

PASSED=0
FAILED=0

run_test() {
  local name="$1"
  local expect_pass="$2"  # "pass" or "fail"
  shift 2
  if "$@" > /dev/null 2>&1; then
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

# Use a temp directory as the fake repo root
TMPDIR=$(mktemp -d)
AGILE_DIR="${TMPDIR}/.agile"
trap 'rm -rf "$TMPDIR"' EXIT

echo "=== .agile/ Directory Structure Tests ==="
echo ""

# Run all tests from TMPDIR so PWD-based resolution is correct
pushd "$TMPDIR" > /dev/null

# ---- 1. No .agile/ yet: current-state.sh should fail
echo "-- Before init --"
run_test "current-state fails before init" "fail" \
  bash "$CURRENT" ".agile"

echo ""
echo "-- After first init --"
bash "$INIT" > /dev/null 2>&1
run_test "CURRENT file exists after init" "pass" \
  test -f "${AGILE_DIR}/CURRENT"
run_test "iteration directory created" "pass" \
  bash -c "ls ${AGILE_DIR}/iter-*/state.md > /dev/null 2>&1"
run_test "current-state.sh returns a path" "pass" \
  bash "$CURRENT"
run_test "state.md passes schema validation" "pass" \
  bash "$VALIDATE"
run_test "constraint check passes" "pass" \
  bash "$CHECK"

echo ""
echo "-- Second init on same day (counter increment) --"
bash "$INIT" > /dev/null 2>&1
ITER_COUNT=$(ls -d "${AGILE_DIR}"/iter-*/ 2>/dev/null | wc -l | tr -d ' ')
if [[ "$ITER_COUNT" -ge 2 ]]; then
  echo "  PASS: Two iteration directories exist after second init"
  PASSED=$((PASSED + 1))
else
  echo "  FAIL: Expected 2+ iteration directories, found ${ITER_COUNT}"
  FAILED=$((FAILED + 1))
fi
run_test "CURRENT updated to second iteration" "pass" \
  bash -c "CURRENT_ID=\$(cat ${AGILE_DIR}/CURRENT); test -f ${AGILE_DIR}/\${CURRENT_ID}/state.md"

echo ""
echo "-- list-iterations.sh output --"
bash "$LIST" 2>/dev/null && {
  echo "  PASS: list-iterations.sh runs without error"
  PASSED=$((PASSED + 1))
} || {
  echo "  FAIL: list-iterations.sh exited with error"
  FAILED=$((FAILED + 1))
}

popd > /dev/null

echo ""
echo "Results: ${PASSED} passed, ${FAILED} failed"
[[ $FAILED -gt 0 ]] && exit 1 || exit 0
