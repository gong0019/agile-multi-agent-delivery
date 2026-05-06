---
skill_version: "1.0.0"
product_version: "v0.1.0"
iteration_version: "iter-20260506-01"
overall_completion: "0%"
current_slice_completion: "0%"
last_updated: "2026-05-06T00:00:00Z"
active_objective: "Replace this with a one paragraph summary of the current goal."
acceptance_criteria:
  - id: "AC-1"
    criterion: "Replace with first acceptance criterion"
    status: "pending"
slice_board:
  - id: "SL-01"
    summary: "Replace with brief outcome description"
    owner: "delivery-lead"
    status: "todo"
    files: []
    verification: "Replace with planned verification steps"
decisions: []
risks: []
next_resume_prompt: "Read current-iteration.md and continue with $agile-multi-agent-delivery. Start from Slice SL-01, respect the Decisions and Risks sections, and finish the Next Steps items before expanding scope."
---

# Current Iteration State

This file is the single source of truth for the current iteration. The YAML frontmatter above is machine-validated. The Markdown body below provides human-readable detail.

## Project Snapshot

- Product: `[product-or-repo-name]`
- Branch: `[branch-name]`
- Last Updated: `[YYYY-MM-DD HH:mm TZ]`
- Delivery Skill: `agile-multi-agent-delivery`
- Repository Rules Loaded: `yes/no`
- State Ledger Version: `v1`

## Version Ledger

- Product Version: `v0.1.0`
- Iteration Version: `iter-YYYYMMDD-01`
- Overall Completion: `0%`
- Current Slice Completion: `0%`
- Last Completed Slice: `[none]`

## Active Objective

- Request Summary: `[one paragraph]`
- Business Value: `[why this matters]`
- In Scope: `[flat list or short paragraph]`
- Out of Scope: `[flat list or short paragraph]`
- Constraints: `[tech, product, safety, time, infra]`

## Confirmed Acceptance Criteria

1. `AC-1 [criterion]`

## Key Repo Constraints

- `[constraint that must be preserved]`

## Active Workstreams

- `WS-1 [summary]`

## Slice Board

| Slice ID | Slice | Owner | Status | Files | Verification |
| --- | --- | --- | --- | --- | --- |
| SL-01 | `[brief outcome]` | `[main/agent-role]` | `todo` | `[paths]` | `[planned-or-done]` |

Status values:

- `todo`
- `in_progress`
- `blocked`
- `done`
- `deferred`

## Decisions

- `DEC-1 [decision + rationale]`

## Risks And Blockers

- `RISK-1 [risk, blocker, or unknown]`

## Changed Files

- `[path] - [why it changed]`

## Verification Log

- `[command or review] - [result]`

## Next Steps

- `[immediate next action]`

## Delegation Contracts

### Task Contract

- Task ID: `[TASK-ID]`
- Round Version: `[vN]`
- Objective: `[single objective]`
- In Scope: `[allowed work]`
- Out of Scope: `[forbidden work]`
- Files/Paths Allowed: `[paths]`
- Files/Paths Avoid: `[paths]`
- Must Respect: `[contracts, constraints, rules]`
- Expected Deliverable: `[what the subagent must return]`
- Stop When: `[clear finish line]`
- Escalate If: `[decision or blocker trigger]`

## Next Resume Prompt

`Read current-iteration.md and continue with $agile-multi-agent-delivery. Start from Slice [ID], respect the Decisions and Risks sections, and finish the Next Steps items before expanding scope.`
