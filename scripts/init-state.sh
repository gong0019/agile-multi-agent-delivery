#!/usr/bin/env bash
# init-state.sh - Initialize current-iteration.md from the template.
# Usage: ./scripts/init-state.sh [output-path]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../references/iteration-state-template.md"
OUTPUT="${1:-./current-iteration.md}"
SKILL_FILE="${SCRIPT_DIR}/../SKILL.md"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "FAIL: Template not found: $TEMPLATE"
  exit 1
fi

# Read skill version from SKILL.md frontmatter
SKILL_VERSION=""
if [[ -f "$SKILL_FILE" ]]; then
  SKILL_VERSION=$(awk '/^---/{c++; next} c==1{print} /^---/{c=0}' "$SKILL_FILE" | grep '^version:' | head -1 | sed 's/version: *//' | tr -d '"' | tr -d "'")
fi

if [[ -z "$SKILL_VERSION" ]]; then
  SKILL_VERSION="1.0.0"
fi

TODAY=$(date -u +%Y%m%d)
ISO_NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
READABLE_NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
ITER_VERSION="iter-${TODAY}-01"

if [[ -f "$OUTPUT" ]]; then
  echo "WARN: $OUTPUT already exists. Creating backup at ${OUTPUT}.bak"
  cp "$OUTPUT" "${OUTPUT}.bak"
fi

# Generate from template with substitutions
sed \
  -e "s/skill_version: \"1.0.0\"/skill_version: \"${SKILL_VERSION}\"/" \
  -e "s/iteration_version: \"iter-20260506-01\"/iteration_version: \"${ITER_VERSION}\"/" \
  -e "s/last_updated: \"2026-05-06T00:00:00Z\"/last_updated: \"${ISO_NOW}\"/" \
  "$TEMPLATE" > "$OUTPUT"

echo "OK: State file initialized at $OUTPUT"
echo "  Skill Version:  ${SKILL_VERSION}"
echo "  Iteration:      ${ITER_VERSION}"
echo "  Last Updated:   ${READABLE_NOW}"
