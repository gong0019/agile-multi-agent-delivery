---
skill_version: "2.0.0"
phase: "INIT"
product_version: "v0.1.0"
iteration_version: "iter-20260506-01"
overall_completion: "0%"
current_slice_completion: "0%"
last_updated: "2026-05-06T00:00:00Z"
prd_path: ".agile/iter-20260506-01/prd.md"
builder_count: 0
tester_count: 0
active_objective: "Replace this with a one paragraph summary of the current goal."
acceptance_criteria:
  - id: "AC-1"
    criterion: "Replace with first acceptance criterion"
    status: "pending"
slice_board:
  - id: "SL-01"
    summary: "Replace with brief outcome description"
    owner: "orchestrator"
    status: "todo"
    files: []
    verification: "Replace with planned verification steps"
decisions: []
risks: []
next_resume_prompt: "Run scripts/current-state.sh to find the active state file, read it, then continue with $agile-multi-agent-delivery. Current phase: INIT. Start from Slice SL-01, respect the Decisions and Risks sections, and finish the Next Steps items before expanding scope."
---

# Current Iteration State

This file is the single source of truth for the current iteration. The YAML frontmatter above is machine-validated by `schema/state-file.json`. The Markdown body below provides human-readable detail.

## Project Snapshot

- Product: `[product-or-repo-name]`
- Branch: `[branch-name]`
- Last Updated: `[YYYY-MM-DD HH:mm TZ]`
- Delivery Skill: `agile-multi-agent-delivery v2.0`
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

## PRD Reference

- PRD Path: `[docs/prd-iter-YYYYMMDD-01.md or empty]`
- PRD Status: `[draft / challenged / confirmed]`

## Confirmed Acceptance Criteria

1. `AC-1 [criterion]`

## Key Repo Constraints

- `[constraint that must be preserved]`

## Active Workstreams

- `WS-1 [summary]`

## Contract Board

| Contract ID | Type | Provider | Consumers | Spec Summary | Status |
| --- | --- | --- | --- | --- | --- |
| C-1 | `[api-rest / shared-type / db-schema / event / behavioral / operational]` | `SL-XX` | `SL-YY` | `[one-line]` | `specified / drift / resolved` |

## Slice Board

| Slice ID | Slice | Owner | Status | Files | Verification |
| --- | --- | --- | --- | --- | --- |
| SL-01 | `[brief outcome]` | `[role]` | `todo` | `[paths]` | `[planned-or-done]` |

Status values: `todo` / `in_progress` / `blocked` / `done` / `deferred`

## Decisions

- `DEC-1 [decision + rationale]`

## Risks And Blockers

- `RISK-1 [risk, blocker, or unknown]`

## Changed Files

- `[path] - [why it changed]`

## Verification Log

- `[command or review] - [result]`

## Phase Log

| Phase | Entered At | Notes |
| --- | --- | --- |
| INIT | `[timestamp]` | Iteration started |

## Next Steps

- `[immediate next action]`

## Delegation Contracts

### Task Contract

- Task ID: `[TASK-ID]`
- Round Version: `[vN]`
- Phase: `[pipeline phase]`
- Agent Role: `[product-owner / challenger / project-manager / builder / tester / integrator]`
- Parallel Group: `[tag for batch-spawned agents]`
- Objective: `[single objective]`
- In Scope: `[allowed work]`
- Out of Scope: `[forbidden work]`
- Files/Paths Allowed: `[paths]`
- Files/Paths Avoid: `[paths]`
- Must Respect: `[contracts, constraints, rules]`
- Expected Deliverable: `[what the subagent must return in Agent Return format]`
- Stop When: `[clear finish line]`
- Escalate If: `[decision or blocker trigger]`

### Agent Return (subagent response format)

- Task ID: `[TASK-ID]`
- Status: `done / partial / blocked`
- Files Inspected: `[paths]`
- Files Changed or Proposed: `[paths]`
- Key Findings or Changes: `[compressed facts, not raw output]`
- Risks: `[RISK-N: description]`
- Validation Performed: `[what was run]`
- Needs Orchestrator Decision: `[yes/no + reason]`

## Next Resume Prompt

`Run scripts/current-state.sh to find the active state file, read it, then continue with $agile-multi-agent-delivery. Current phase: [PHASE]. Start from Slice [ID], respect the Decisions and Risks sections, and finish the Next Steps items before expanding scope.`
