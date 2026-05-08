#!/usr/bin/env bash
# current-state.sh - Print the absolute path to the active state file.
# Usage: ./scripts/current-state.sh [agile-dir]
#   agile-dir: path to the .agile/ directory (default: $PWD/.agile)
#   The script is called from the project root, not the skill root.
# Exit codes: 0 = found and printed, 1 = not found, 2 = structural error

set -euo pipefail

# PROJECT_ROOT is where the script is invoked from (the project directory)
PROJECT_ROOT="${PWD}"
AGILE_DIR="${PROJECT_ROOT}/${1:-.agile}"
CURRENT_FILE="${AGILE_DIR}/CURRENT"

if [[ ! -d "$AGILE_DIR" ]]; then
  echo "FAIL: .agile/ not found at ${AGILE_DIR}" >&2
  echo "HINT: Run scripts/init-state.sh from your project root to start a new iteration." >&2
  exit 1
fi

if [[ ! -f "$CURRENT_FILE" ]]; then
  echo "FAIL: No active iteration (.agile/CURRENT is missing)" >&2
  echo "HINT: Run scripts/init-state.sh from your project root." >&2
  exit 1
fi

ITER_ID=$(tr -d '[:space:]' < "$CURRENT_FILE")

if [[ -z "$ITER_ID" ]]; then
  echo "FAIL: .agile/CURRENT is empty" >&2
  echo "HINT: Run scripts/init-state.sh from your project root." >&2
  exit 2
fi

STATE_FILE="${AGILE_DIR}/${ITER_ID}/state.md"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "FAIL: Active iteration '${ITER_ID}' has no state.md" >&2
  echo "HINT: Expected: ${STATE_FILE}" >&2
  exit 2
fi

echo "$STATE_FILE"
