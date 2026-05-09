---
prd_version: "1"
iteration_ref: "iter-20260506-01"
status: "draft"
authored_by: "product-owner"
challenged_by: ""
last_updated: "2026-05-06T00:00:00Z"
challenge_rounds: 0
---

# Product Requirements Document

> This document is written by the **ProductOwner** agent and reviewed adversarially by the **Challenger** agent. The Orchestrator mediates divergence and presents a single resolution to the user for approval.

## Problem Statement

Describe the problem being solved or the opportunity being captured. One to three paragraphs. Focus on the user pain or business gap, not the solution.

## User Stories

- `US-1` As a `[role]`, I want to `[action]` so that `[outcome]`.
- `US-2` As a `[role]`, I want to `[action]` so that `[outcome]`.

## Existing Feature Inventory

> Required for brownfield changes (modifying an existing module, page, or feature).
> Skip only for fully greenfield work (new module, zero existing code in that area).
> Source: Orchestrator's pre-drafting audit of the affected module(s).
> Every item in this table must appear in Functional Requirements with an explicit disposition tag.

| ID | Feature | Current Behavior | Disposition | Notes |
| --- | --- | --- | --- | --- |
| EF-1 | `[feature name]` | `[what it does today]` | `preserve` | |
| EF-2 | `[feature name]` | `[what it does today]` | `modify → [new behavior]` | |
| EF-3 | `[feature name]` | `[what it does today]` | `remove` | Requires explicit user approval |

Disposition values:
- `preserve` — must survive this iteration unchanged; Builder must confirm in `Behaviors Preserved`
- `modify` — will change; new behavior described in Functional Requirements
- `remove` — will be deleted; must be explicitly approved by user at the confirmation gate

## Functional Requirements

Each requirement maps to one or more acceptance criteria.
For brownfield: preserved behaviors appear as `[PRESERVE]` rows; modified behaviors as `[MODIFY]` rows.

When a requirement is unclear or depends on user decisions, write `[NEEDS CLARIFICATION: <question>]` in the requirement cell. The Orchestrator will collect decisions from the user before presenting the confirmation package — no `[NEEDS CLARIFICATION]` marker may remain unresolved at confirmation.

| ID | Requirement | AC Reference | Priority | Disposition |
| --- | --- | --- | --- | --- |
| FR-1 | `[description of new behavior]` | AC-1 | Must | new |
| FR-2 | `[NEEDS CLARIFICATION: should this also apply to admin users?]` | AC-2 | Must | new |
| FR-3 | `[existing feature preserved as-is]` | RAC-1 | Must | `[PRESERVE]` EF-1 |
| FR-4 | `[existing feature changed]` | AC-3, RAC-2 | Must | `[MODIFY]` EF-2 |

## Acceptance Criteria

> Written in Given/When/Then format. Each criterion must be independently testable.
> The "Then" clause is the test assertion. The "Given" clause is the test setup. The "When" clause is the test action.
> Use `[NEEDS CLARIFICATION: <question>]` for any detail that cannot be specified without a user decision.

### AC-1 — `[feature name]`

**Given** `[precondition / system state]`  
**When** `[user action or system event]`  
**Then** `[observable outcome]`

Edge cases:
- `[edge case 1]`: `[expected behavior]`
- `[edge case 2]`: `[expected behavior]`

### AC-2 — `[feature name]`

**Given** `[precondition]`  
**When** `[action]`  
**Then** `[outcome]`

Edge cases:
- `[edge case]`: `[expected behavior]`

## Regression Acceptance Criteria

> Generated from EF items tagged `preserve` or `modify`. Each must be validated by Testers.
> Omit this section for greenfield projects only.

### RAC-1 — `[existing feature name]` (EF-N)

**Given** `[precondition that establishes the existing feature's context]`  
**When** `[user performs the action that the existing feature handles]`  
**Then** `[the existing behavior is unchanged — describe it precisely]`

## Success Criteria

> Measurable, technology-agnostic outcomes that define what "shipped successfully" means.
> These are business-level indicators, not functional pass/fail. Testers use these for UX Quality review.

| ID | Criterion | Measurement | Target |
| --- | --- | --- | --- |
| SC-1 | `[business outcome]` | `[how to measure]` | `[threshold]` |
| SC-2 | `[user experience outcome]` | `[how to measure]` | `[threshold]` |

Examples: "Settings page load time < 800ms", "Task completion rate > 90% in user testing", "Zero increase in support tickets about avatar upload"

## Non-Functional Requirements

- Performance: `[e.g. p95 latency < 200ms under normal load]`
- Security: `[e.g. no PII in logs]`
- Reliability: `[e.g. no new uncaught exceptions]`
- Accessibility: `[e.g. WCAG 2.1 AA for all new UI]`

## Out of Scope

Explicit list. Each item must be definitive — "we will not do X in this iteration."

- `[item]`
- `[item]`

## Technical Constraints

> Include any Project Constitution rules that are especially relevant to this feature.
> Constitution rules apply globally; listing them here makes them visible in the PRD context.

- `[e.g. must not change the public API contract for /api/v1/users]`
- `[e.g. no new dependencies without Orchestrator approval]`
- `[e.g. all changes must be backward compatible with v0.3.x clients]`
- `[Constitution: e.g. all API responses must use the standard envelope {data, error}]`

## Open Questions

Questions that must be resolved before the Orchestrator can confirm this PRD.

| ID | Question | Owner | Status |
| --- | --- | --- | --- |
| Q-1 | `[question]` | `[product-owner / challenger / user]` | `open / resolved` |

## Challenger Objections and Resolutions

Populated after the Challenger agent returns its review. The Orchestrator compiles this table from both returns.

| Objection ID | Objection | ProductOwner Response | Resolution |
| --- | --- | --- | --- |
| OBJ-1 | `[challenger objection]` | `[product-owner position]` | `accepted / rejected / deferred` |

## Approval Record

- Confirmed by user: `yes / no`
- Confirmed at: `[ISO 8601 timestamp or blank]`
- Final PRD version: `[prd_version at confirmation]`
- Notes: `[any scope adjustments made during confirmation]`
