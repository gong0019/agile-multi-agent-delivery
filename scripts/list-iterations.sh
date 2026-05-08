#!/usr/bin/env bash
# list-iterations.sh - List all iterations in .agile/ with phase and completion status.
# Usage: ./scripts/list-iterations.sh [agile-dir]
#   agile-dir: path to the .agile/ directory (default: $PWD/.agile)
#   Run this from your project root.

set -euo pipefail

PROJECT_ROOT="${PWD}"
AGILE_DIR="${PROJECT_ROOT}/${1:-.agile}"

if [[ ! -d "$AGILE_DIR" ]]; then
  echo "No .agile/ directory found at ${AGILE_DIR}"
  echo "HINT: Run scripts/init-state.sh from your project root to start a new iteration."
  exit 0
fi

python3 -c "import yaml" 2>/dev/null || {
  echo "INFO: PyYAML not found — installing automatically..."
  pip3 install --quiet pyyaml || {
    echo "FAIL: Could not install PyYAML. Run manually: pip3 install pyyaml"
    exit 2
  }
}

CURRENT=""
[[ -f "${AGILE_DIR}/CURRENT" ]] && CURRENT=$(tr -d '[:space:]' < "${AGILE_DIR}/CURRENT")

python3 - "$AGILE_DIR" "$CURRENT" <<'PYEOF'
import sys
import os

try:
    import yaml
except ImportError:
    print("FAIL: PyYAML required. Run: pip3 install pyyaml")
    sys.exit(1)

agile_dir = sys.argv[1]
current_id = sys.argv[2] if len(sys.argv) > 2 else ""

iterations = sorted([
    d for d in os.listdir(agile_dir)
    if os.path.isdir(os.path.join(agile_dir, d)) and d.startswith("iter-")
])

if not iterations:
    print(f"No iterations found in {agile_dir}")
    sys.exit(0)

fmt = "{:<26} {:<24} {:<12} {}"
print(fmt.format("Iteration ID", "Phase", "Completion", ""))
print("-" * 72)

for iter_id in reversed(iterations):
    state_path = os.path.join(agile_dir, iter_id, "state.md")
    if not os.path.exists(state_path):
        print(fmt.format(iter_id, "(no state.md)", "-", ""))
        continue
    with open(state_path, "r", encoding="utf-8") as f:
        content = f.read()
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        print(fmt.format(iter_id, "(no frontmatter)", "-", ""))
        continue
    end_idx = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end_idx is None:
        print(fmt.format(iter_id, "(malformed)", "-", ""))
        continue
    try:
        data = yaml.safe_load("\n".join(lines[1:end_idx]))
        phase = data.get("phase", "?")
        completion = data.get("overall_completion", "?")
        tag = "← CURRENT" if iter_id == current_id else ""
        print(fmt.format(iter_id, phase, completion, tag))
    except Exception:
        print(fmt.format(iter_id, "(parse error)", "-", ""))

PYEOF
