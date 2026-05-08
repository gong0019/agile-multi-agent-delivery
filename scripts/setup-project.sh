#!/usr/bin/env bash
# setup-project.sh - Inject the agile-multi-agent-delivery skill declaration into the project's AI config.
# Usage: ./agile-multi-agent-delivery/scripts/setup-project.sh [config-file]
#   config-file: explicit path (optional — auto-detected if omitted)
#   Run this from your project root.
# Exit codes: 0 = success or already configured, 1 = error

set -euo pipefail

PROJECT_ROOT="${PWD}"

read -r -d '' SNIPPET << 'SNIPPET_EOF' || true
## Agile Delivery Skill

This project includes `agile-multi-agent-delivery/` — a structured multi-agent delivery skill.

Activate it **only** when the user explicitly requests it, for example:
- "用 agile-multi-agent-delivery 来做这个需求"
- "use $agile-multi-agent-delivery"

When activated: read `agile-multi-agent-delivery/SKILL.md` in full, act as the
Orchestrator, never write source code directly, all delivery files under `.agile/`.

Do not activate for normal coding questions, bug fixes, or explanations.
SNIPPET_EOF

# Resolve config file path
if [[ $# -gt 0 ]]; then
  CONFIG_FILE="$1"
else
  if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then
    CONFIG_FILE="${PROJECT_ROOT}/CLAUDE.md"
  elif [[ -d "${PROJECT_ROOT}/.cursor/rules" ]]; then
    CONFIG_FILE="${PROJECT_ROOT}/.cursor/rules/agile-delivery.md"
  elif [[ -f "${PROJECT_ROOT}/.windsurfrules" ]]; then
    CONFIG_FILE="${PROJECT_ROOT}/.windsurfrules"
  else
    CONFIG_FILE="${PROJECT_ROOT}/CLAUDE.md"
  fi
fi

# Already configured — nothing to do
if [[ -f "$CONFIG_FILE" ]] && grep -q "agile-multi-agent-delivery" "$CONFIG_FILE" 2>/dev/null; then
  echo "OK: Skill already declared in ${CONFIG_FILE} — no changes made."
  exit 0
fi

# Create parent directory if needed (e.g. .cursor/rules/)
mkdir -p "$(dirname "$CONFIG_FILE")"

# Append snippet with a blank-line separator when the file already has content
if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
  printf '\n%s\n' "$SNIPPET" >> "$CONFIG_FILE"
else
  printf '%s\n' "$SNIPPET" >> "$CONFIG_FILE"
fi

echo "OK: Skill declaration added to ${CONFIG_FILE}"
echo ""
echo "Detected tool:"
case "$CONFIG_FILE" in
  *CLAUDE.md)        echo "  Claude Code  →  ${CONFIG_FILE}" ;;
  *.cursor/rules/*)  echo "  Cursor       →  ${CONFIG_FILE}" ;;
  *.windsurfrules)   echo "  Windsurf     →  ${CONFIG_FILE}" ;;
  *)                 echo "  Custom       →  ${CONFIG_FILE}" ;;
esac
