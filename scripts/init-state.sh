#!/usr/bin/env bash
# init-state.sh - Initialize a new iteration directory under .agile/
# Usage: ./scripts/init-state.sh [agile-dir]
#   agile-dir: path to the .agile/ directory (default: $PWD/.agile)
#   Run this from your project root. The skill files are found via SCRIPT_DIR.

set -euo pipefail

# SKILL_ROOT: where the skill files (template, schema, references) live
SKILL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="${SKILL_ROOT}/references/iteration-state-template.md"
SKILL_FILE="${SKILL_ROOT}/SKILL.md"

# PROJECT_ROOT: the project directory (where .agile/ will be created)
PROJECT_ROOT="${PWD}"
AGILE_DIR="${PROJECT_ROOT}/${1:-.agile}"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "FAIL: Template not found: $TEMPLATE"
  echo "HINT: Make sure you are referencing the correct skill path."
  exit 1
fi

# Create .agile/ if it does not exist
mkdir -p "$AGILE_DIR"

# Extract skill version from SKILL.md frontmatter (pure bash, no awk/sed fragility)
SKILL_VERSION=""
if [[ -f "$SKILL_FILE" ]]; then
  in_frontmatter=false
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" == "false" ]]; then in_frontmatter=true; else break; fi
      continue
    fi
    if [[ "$in_frontmatter" == "true" && "$line" =~ ^version:[[:space:]]*\"?([0-9]+\.[0-9]+\.[0-9]+) ]]; then
      SKILL_VERSION="${BASH_REMATCH[1]}"
      break
    fi
  done < "$SKILL_FILE"
fi
[[ -z "$SKILL_VERSION" ]] && SKILL_VERSION="2.0.0"

TODAY=$(date -u +%Y%m%d)
ISO_NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
READABLE_NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

# Find a unique iteration ID for today (auto-increment on collision)
COUNTER=1
ITER_ID="iter-${TODAY}-$(printf '%02d' $COUNTER)"
while [[ -d "${AGILE_DIR}/${ITER_ID}" ]]; do
  COUNTER=$((COUNTER + 1))
  ITER_ID="iter-${TODAY}-$(printf '%02d' $COUNTER)"
done

ITER_DIR="${AGILE_DIR}/${ITER_ID}"
mkdir -p "$ITER_DIR"

STATE_FILE="${ITER_DIR}/state.md"
PRD_PATH=".agile/${ITER_ID}/prd.md"

# Generate state.md from template
sed \
  -e "s/skill_version: \"2.0.0\"/skill_version: \"${SKILL_VERSION}\"/" \
  -e "s/iteration_version: \"iter-20260506-01\"/iteration_version: \"${ITER_ID}\"/" \
  -e "s|last_updated: \"2026-05-06T00:00:00Z\"|last_updated: \"${ISO_NOW}\"|" \
  -e "s|prd_path: \".agile/iter-20260506-01/prd.md\"|prd_path: \"${PRD_PATH}\"|" \
  "$TEMPLATE" > "$STATE_FILE"

# Update CURRENT pointer atomically
CURRENT_FILE="${AGILE_DIR}/CURRENT"
printf '%s' "$ITER_ID" > "${CURRENT_FILE}.tmp"
mv "${CURRENT_FILE}.tmp" "$CURRENT_FILE"

echo "OK: New iteration initialized"
echo "  Project root:  ${PROJECT_ROOT}"
echo "  Directory:     ${ITER_DIR}"
echo "  State file:    ${STATE_FILE}"
echo "  PRD (future):  ${AGILE_DIR}/${ITER_ID}/prd.md"
echo "  Skill version: ${SKILL_VERSION}"
echo "  Started at:    ${READABLE_NOW}"
echo ""
echo "Tip: commit .agile/ to git to preserve iteration history."
