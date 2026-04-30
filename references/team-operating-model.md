# Team Operating Model

Use this reference when the task clearly benefits from multiple subagents and explicit handoffs.

## Core principle

The main agent is the delivery lead, not a passive coordinator.

The main agent should:

- own the repo truth
- keep the critical path moving locally
- delegate only bounded sidecar work
- integrate results
- update the canonical state file

## Recommended roles

### 1. Delivery Lead

This is the main agent and the only role that is always active.

Deliverables:

- round brief
- task contracts
- state ledger updates
- integration decisions
- final user-facing delivery summary

Responsibilities:

- own user communication
- own scope and acceptance
- keep critical-path work local
- decide what is safe to delegate
- merge delegated results into the canonical state

### 2. Scope Analyst

Use an `explorer` when the requirement is incomplete, user-facing, or carries edge-case risk.

Deliverables:

- clarified acceptance criteria
- hidden assumptions
- out-of-scope list
- edge cases and failure states

### 3. Technical Architect

Use an `explorer` when codebase shape, data flow, or architecture impact is unclear.

Deliverables:

- impacted modules
- approach options and tradeoffs
- migration or compatibility risk
- proposed verification plan

This role is optional. Use it only when architectural discovery is distinct from scope analysis.

### 4. Builder

Use `worker` agents only for isolated write scopes.

Good ownership examples:

- one API module
- one state-management module
- one UI feature area
- one test file or test directory

Worker instructions should always include:

- exact ownership
- no reverting others' edits
- adapt to concurrent changes if needed
- report changed files and notable risks

### 5. Reviewer

Use an `explorer` or `worker` for:

- test-gap analysis
- regression review
- focused verification

This role is especially useful while implementation continues locally.

## Delegation matrix

Delegate these freely when the outputs are bounded:

- codebase questions
- requirement edge-case analysis
- independent code slices with disjoint files
- test creation in isolated files
- regression review of a finished diff

Keep these local unless there is a strong reason otherwise:

- first-pass repo understanding
- integrating multiple changed slices
- editing conflict-prone entry points
- final user-facing summary
- state-file maintenance
- urgent blocking tasks

## State compression

Do not pass long chat transcripts or raw subagent essays forward.

Compress every round into a short `State Ledger`, then derive each delegated `Task Contract` from it.

Recommended `State Ledger` fields:

```md
## State Ledger vN
- Goal:
- Non-goals:
- Acceptance Criteria:
- Confirmed Constraints:
- Key Repo Constraints:
- Decisions Made:
- Open Questions:
- Active Workstreams:
- Files/Modules of Record:
- Validation Status:
- Risks:
```

Recommended `Task Contract` fields:

```md
## Task Contract
- Task ID:
- Round Version:
- Objective:
- In Scope:
- Out of Scope:
- Files/Paths Allowed:
- Files/Paths Avoid:
- Must Respect:
- Expected Deliverable:
- Stop When:
- Escalate If:
```

Recommended subagent return shape:

```md
## Agent Return
- Task ID:
- Status: done / partial / blocked
- Files Inspected:
- Files Changed or Proposed:
- Key Findings or Changes:
- Risks:
- Validation Performed:
- Needs Main-Agent Decision:
```

## Wait policy

Do not call `wait_agent` immediately after spawning.

Spawn agents only after deciding what the main agent can do next without them. Wait only when:

- the next critical-path action is blocked on the result
- integration cannot proceed without the answer
- you are ready to review and merge a finished delegated slice

## Slice design rules

A good slice is:

- independently understandable
- easy to verify
- unlikely to conflict with another slice
- small enough to finish in one iteration update

Prefer these slice boundaries:

- route layer vs page component
- API parser vs business logic
- data model change vs UI adaptation
- feature implementation vs regression coverage

Avoid these slice boundaries:

- splitting one tiny file across multiple workers
- assigning one worker both architecture discovery and final integration
- delegating work that depends on unresolved product choices

## Context durability

To survive `/clear` or a fresh thread:

1. update the repository-local iteration state file, typically `current-iteration.md` in the repository root
2. include exact remaining work
3. include the next resume prompt
4. include changed files and verification status
5. include open risks and decisions

The next agent should be able to continue by reading that file first, without relying on hidden chat history.
