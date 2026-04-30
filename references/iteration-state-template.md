# Current Iteration State

Use this as the initial structure for the repository-local iteration state file, typically `current-iteration.md` in the repository root.

Replace placeholders immediately. Keep the file concise but current.

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
2. `AC-2 [criterion]`
3. `AC-3 [criterion]`

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
