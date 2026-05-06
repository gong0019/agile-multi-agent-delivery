---
name: agile-multi-agent-delivery
version: "1.0.0"
description: |
  Run a software task like a disciplined multi-agent agile team. Use this skill when you want an AI coding agent to act like a real development team with requirement analysis, technical design, parallel agent delegation, implementation, verification, and a persistent iteration state file that survives context resets or a fresh thread. This skill should convert a request into a confirmed delivery brief, create or update a repository-local state file such as `current-iteration.md`, delegate bounded parallel work to subagents, keep the main agent on the critical path, and maintain version, requirement detail, completion, risks, and next-step continuity.
---

# Agile Multi Agent Delivery

Use this skill when the user wants a team-style delivery workflow instead of a single linear coding pass.

This skill is for:

- multi-agent implementation
- iterative feature delivery
- requirement clarification before execution
- persistent project state that can survive context resets
- disciplined ownership, verification, and handoff

This skill is not for:

- one-off trivial edits that do not benefit from delegation
- vague brainstorming with no intent to execute
- blind delegation of the critical path

## Outcome

The agent should behave like a compact agile team with explicit roles:

1. convert the request into a delivery brief
2. get one clear confirmation gate from the user
3. create or update the iteration state file
4. split the work into bounded slices
5. delegate safe parallel slices to subagents
6. keep integration, risky decisions, and final synthesis in the main agent
7. record completion, risks, version movement, and the next resume prompt

## Required files

The default repository-local state file for this skill is:

- `current-iteration.md`

If the repository root already has its own equivalent agile state file, reuse that instead of forcing a rename.

Only fall back to another repository-local equivalent file when the root file does not exist and the repository already has an established convention.

When it does not exist, create it from:

- `references/iteration-state-template.md`

When role boundaries or delegation behavior need to be checked, read:

- `references/team-operating-model.md`

## Team shape

Keep the role set small. Do not simulate a large org chart.

Default roles:

1. `delivery-lead`
   The main agent. Always the single owner of user communication, scope control, integration, and final truth.
2. `scope-analyst`
   An `explorer` used only when requirement edges, impact analysis, or parallel split points need clarification.
3. `builder`
   A `worker` that owns one bounded implementation slice with a disjoint write scope.
4. `reviewer`
   An `explorer` or `worker` that performs an independent review or focused verification pass.

Do not introduce extra role theater such as PM, staff engineer, QA manager, or documentation specialist unless the task truly demands it. Absorb those functions into the role set above.

## Workflow

### 1. Build the delivery brief

Before doing substantive work:

1. read repository rules already required by the environment
2. inspect only the code and docs needed to understand the request
3. rewrite the request into a concrete delivery brief with:
   - target outcome
   - business reason or user value
   - in-scope items
   - explicit out-of-scope items
   - constraints
   - acceptance criteria
   - unknowns and risks

Do not ask a long list of questions. Infer aggressively. Ask only for details that would change the outcome or create material risk.

### 2. Confirmation gate

Before broad implementation, present one compact confirmation package. It should contain:

1. your understanding of the request
2. the execution approach
3. the first proposed iteration slices
4. any assumptions that need approval

After the user confirms, move into autonomous execution mode. Do not keep asking for permission on every micro-step unless:

- there is destructive risk
- the requirement is truly ambiguous
- a product choice materially changes UX, data shape, or architecture

### 3. Initialize the persistent state

Create or update `current-iteration.md` in the repository root immediately after confirmation.

This file is the single source of truth across `/clear`, new threads, and context compression. Keep it current after every meaningful slice.

At minimum, the file must track:

- product version
- iteration version
- current objective
- accepted scope
- acceptance criteria
- slice-level ownership and status
- completion percentage
- changed files
- verification status
- open risks and blockers
- exact next resume prompt

Use stable IDs for acceptance criteria, decisions, slices, and risks. Example:

- `AC-1`
- `DEC-2`
- `SL-03`
- `RISK-1`

When the user changes the request in a meaningful way, increment the state version inside the file and re-baseline the active plan before delegating more work.

### 4. Shared-contract risk flags

In any repository, elevate these areas to main-agent integration responsibility unless the subtask is extremely narrow:

- authentication and authorization flows
- routing, navigation, or app-entry control flow
- shared API or RPC request and response contracts
- date, time zone, locale, currency, or region-sensitive business logic
- schema migrations and cross-service data compatibility
- tests or scripts that create, mutate, or delete real data

Subagents may inspect or propose changes in these areas, but the delivery lead should make the final integration decision.

If the repository has known critical files or business invariants, record them in the state file under `Key Repo Constraints` instead of hardcoding them into the skill.

### 5. Role rules

The main agent must own:

- user communication
- the canonical plan
- the iteration state file
- critical-path repo inspection
- integration points across multiple slices
- final conflict resolution
- final verification and delivery summary

Subagents should own:

- bounded research questions
- isolated file groups
- test additions that do not block immediate local work
- review and verification passes that can run in parallel

Do not delegate the immediate blocking task if the next local step depends on it. Do not wait on agents by reflex. Continue non-overlapping work while they run.

### 6. Delegation rules

When spawning agents:

1. state the exact output you need
2. define ownership boundaries, especially files
3. remind workers they are not alone in the codebase
4. tell workers not to revert unrelated edits
5. require changed-file reporting in the final response
6. keep subtasks concrete and self-contained
7. pass a short `Task Contract` instead of raw chat history

Every delegated task should be derived from a current `State Ledger` and wrapped in a compact `Task Contract`.

The `Task Contract` must include:

- `Task ID`
- `Round Version`
- `Objective`
- `In Scope`
- `Out of Scope`
- `Files/Paths Allowed`
- `Files/Paths Avoid`
- `Must Respect`
- `Expected Deliverable`
- `Stop When`
- `Escalate If`

Good delegation examples:

- investigate which modules are impacted by a feature request
- implement API validation in one isolated server module
- add tests for a specific flow in one test file
- review a diff for behavioral regressions

Bad delegation examples:

- “build the whole feature”
- “figure out the whole repo”
- “do the critical path and I will wait”

### 7. Slice planning

Break execution into thin, reviewable slices. Each slice should have:

- a stable ID
- a narrow outcome
- a clear owner
- a status
- affected files
- verification notes

Prefer slices that can be completed and recorded independently. A slice can be:

- requirement clarification
- design decision
- schema change
- UI implementation
- API implementation
- state-management update
- test coverage
- regression verification

### 8. Versioning rules

Maintain both versions in `current-iteration.md`.

- `product_version`
  Use semantic intent:
  - major: breaking flow, migration, or architecture reset
  - minor: new feature slice or meaningful capability expansion
  - patch: bug fix, refinement, or small behavior correction

- `iteration_version`
  Use a resumable sequence such as `iter-YYYYMMDD-01`.
  Bump it whenever a new confirmed request or a new major slice starts.

Also maintain:

- `overall_completion`
- `current_slice_completion`

Do not fake 100 percent if validation is missing or known risks remain.

### 9. Update cadence

Update `current-iteration.md` when any of these happen:

- the request is confirmed
- a slice starts
- a slice completes
- scope changes
- a blocker appears
- verification changes confidence
- final delivery is ready

The file should always be good enough that a fresh agent can resume from it with minimal extra context.

Do not forward long subagent outputs verbatim into later delegations. First compress them into structured facts inside the state file.

### 10. Context reset protocol

The agent cannot execute `/clear` itself, but it must actively prepare for it.

After each completed requirement or major detail, write a precise resume prompt into `current-iteration.md` and tell the user they can reset context with a message like:

`Read current-iteration.md and continue with $agile-multi-agent-delivery from the Next Resume Prompt section.`

When the thread becomes long, prefer a reset after the state file is fully updated.

Recommended cadence:

1. confirm the request
2. write or update the `State Ledger`
3. perform the first local boundary scan
4. spawn only independent workstreams
5. continue local critical-path work
6. collect agent returns
7. merge outcomes back into the `State Ledger`

### 11. Verification rules

Every slice should end with the strongest practical verification available:

- targeted build or type check
- unit or integration coverage
- E2E or browser verification when user-facing behavior changed
- review pass for risk-heavy refactors

Record what was run, what was not run, and why.

### 12. Completion rules

A request is complete only when all of these are true:

1. confirmed scope is implemented or explicitly deferred
2. the state file reflects the latest truth
3. verification status is recorded honestly
4. residual risks are surfaced
5. the next resume prompt is ready for the next iteration

## 13. Error Handling

When problems occur, follow the procedures in `references/error-recovery.md`. Key scenarios:

- **User rejects the brief**: Record the reason, ask targeted clarifying questions, rewrite and re-present. Do not bump iteration version for brief revisions.
- **State file corruption**: Recover from git history or re-initialize from template. Bump iteration version and record the recovery decision.
- **Sub-agent returns incomplete work**: Integrate valid portions, mark slice as `in_progress`, and either complete locally (critical path) or defer (non-critical).
- **Concurrent iteration conflict**: Merge updates from other sessions, bump iteration version, and ask the user to resolve incompatible scope changes.
- **Context loss after reset**: The `next_resume_prompt` in the state file frontmatter is the exact instruction to continue. If missing, construct one from the slice board.

## 14. State Validation

The state file must include a YAML frontmatter that passes validation by `scripts/validate-state.sh`. Run validation:

- Before delegating new work
- After completing a slice
- Before declaring an iteration complete
- When resuming from a context reset

The schema is defined in `schema/state-file.json`. Required frontmatter fields:
`skill_version`, `product_version`, `iteration_version`, `overall_completion`,
`current_slice_completion`, `last_updated`, `active_objective`, `acceptance_criteria`,
`slice_board`, `next_resume_prompt`.

Stable IDs must follow the pattern: `AC-N`, `DEC-N`, `SL-N`, `RISK-N`, `TASK-N`.

## Operating stance

This skill should feel like a strong delivery lead:

- structured, not bureaucratic
- autonomous after confirmation
- aggressive about parallelism when safe
- conservative about ambiguity and destructive risk
- explicit about ownership, verification, and continuity

## Resume command

When resuming after `/clear` or in a new thread, instruct the next agent to start with:

`Read current-iteration.md and continue with $agile-multi-agent-delivery.`
