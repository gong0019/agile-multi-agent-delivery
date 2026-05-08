# Team Operating Model

This reference defines how the seven roles operate within the pipeline orchestration model. Read it when you need to check role boundaries, delegation rules, or wait policy.

## Core Principle

The Orchestrator is the delivery lead, not a passive coordinator. It owns the state file, drives phase transitions, and is the only agent that communicates with the user.

The Orchestrator must never write code, read large source files, or accumulate raw subagent output in its context. Every subagent must return a structured Agent Return of no more than 200 lines.

---

## Phase-Aware Role Activation

| Phase | Active Roles |
| --- | --- |
| INIT | Orchestrator |
| REQUIREMENTS_DRAFTING | ProductOwner, Challenger (parallel) |
| REQUIREMENTS_REVIEW | Orchestrator (mediates), then ProductOwner (revises) |
| REQUIREMENTS_CONFIRMED | Orchestrator (user gate) |
| PM_DECOMPOSITION | ProjectManager |
| BUILDING | Builder × N (parallel) |
| INTEGRATION_CHECK | Orchestrator (struct check), optionally Integrator |
| TESTING | Tester × M (parallel) |
| COMPLETE | Orchestrator (delivery summary) |

---

## Role Definitions

### Orchestrator (main agent, always active)

Deliverables: delivery brief, phase transitions, state file updates, user-facing summary.

Responsibilities:
- Own all user communication
- Own the active state file (`.agile/{iteration_id}/state.md`)
- Drive phase transitions based on agent returns
- Validate PM decomposition before spawning Builders
- Run integration check after all Builders complete
- Synthesize Tester returns into final delivery summary

Constraints:
- Never writes source code
- Never reads files larger than needed to assess an agent return
- Never accumulates raw agent output — compress into structured facts before writing to state file

### ProductOwner (explorer, REQUIREMENTS phases)

Deliverables: `docs/prd-{iter}.md` in PRD template format.

Responsibilities:
- Read the user request and minimal repo context
- Write a complete PRD with user stories, functional requirements, and acceptance criteria
- Revise the PRD once after receiving the Challenger objection table from the Orchestrator

Constraints:
- Never writes source code
- Does not interact directly with the Challenger — all communication goes through the Orchestrator

### Challenger (explorer, REQUIREMENTS_DRAFTING, runs in parallel with ProductOwner)

Deliverables: challenge report (objections list, edge cases, gaps, contradictions).

Responsibilities:
- Receive the PRD from the Orchestrator (or read it from `prd_path`)
- Identify: missing edge cases, ambiguous acceptance criteria, hidden assumptions, scope creep risks
- Return a structured objection list to the Orchestrator

Constraints:
- Never writes source code
- Does not modify the PRD directly
- Does not re-run after one challenge round unless the Orchestrator explicitly re-activates it

### ProjectManager (explorer, PM_DECOMPOSITION)

Deliverables: ownership map + Builder Task Contracts + Tester count + Contract Specs for all Cross-Slice Interfaces.

Responsibilities:
- Read the confirmed PRD and repository file tree
- Apply the granularity rules from `references/pm-decomposition-guide.md`
- Produce a decomposition plan with strictly disjoint file ownership
- Identify every Cross-Slice Interface using heuristics from `references/csi-guide.md`
- Produce a precise Contract Spec for every CSI (provider and consumers must agree on the same spec)
- Self-validate: no file in two slices, every contract has a provider and at least one consumer, every Builder's contracts reference existing specs

Constraints:
- Never writes source code
- Does not make product decisions — escalates to Orchestrator
- Does not skip CSI identification even if the PRD is silent on interfaces — propose defaults and escalate

### Builder-N (worker, BUILDING, spawned in parallel)

Deliverables: implemented slice + Agent Return with changed files, verification notes, risks, and Contract Compliance table.

Responsibilities:
- Read and implement only files in `files_allowed`
- Adhere to every Contract Spec referenced in the Task Contract's `contracts` field
- Report every changed file in the Agent Return
- Run the strongest available verification (type check, unit tests, lint)
- Escalate immediately if any required change is outside `files_allowed`

Constraints:
- Never touches files outside `files_allowed`
- Never reverts changes made by other Builders
- If a shared file needs a change the Builder does not own: describe in `Needs Orchestrator Decision`, do not modify the file
- Must report Contract Compliance per contract in Agent Return (status: `compliant / partial / blocked` with evidence)

### Tester-N (worker, TESTING, spawned in parallel)

Deliverables: test results + coverage gap report + pass/fail per acceptance criterion + contract verification results.

Responsibilities:
- Cover the assigned Builders' slices
- Run unit, integration, or E2E tests as available
- Verify cross-slice contracts: actual requests against api-* specs, type checker for shared-type, schema introspection for db-schema, event payload validation for event contracts
- Report AC-N status (met / failed / untestable)
- Identify coverage gaps and surface as RISK-N items

Constraints:
- May only write to test files
- May not modify source files
- If a bug is found: report it as RISK-N with severity, do not fix it (fixing is a new iteration slice)

### Integrator (worker, optional, INTEGRATION_CHECK)

Deliverables: resolved cross-slice conflicts + integration test results.

Constraints:
- Created only when the Orchestrator's integration check finds file overlap or critical risks
- Scope is limited to resolving the specific conflict — not a general refactor

---

## State Compression

Do not pass raw agent outputs forward. Every round must be compressed into a short `State Ledger` before the next delegation.

Recommended `State Ledger` fields:

```md
## State Ledger vN
- Goal:
- Phase:
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

Every subagent returns an `Agent Return`:

```md
## Agent Return
- Task ID:
- Status: done / partial / blocked
- Files Inspected:
- Files Changed or Proposed:
- Key Findings or Changes:
- Risks:
- Validation Performed:
- Contract Compliance:
  | Contract ID | Status | Evidence |
  |-------------|--------|----------|
  | C-1         | compliant | [brief evidence] |
- Needs Orchestrator Decision:
```

---

## Wait Policy

Do not wait on agents by reflex. After spawning a parallel batch, the Orchestrator should update the state file for the current phase transition, then wait.

Wait only when:
- the next phase cannot start without all agent returns
- the integration check cannot proceed without all Builder returns

---

## Context Durability

To survive `/clear` or a fresh thread:

1. Update the active state file after every phase transition
2. Record `phase` in frontmatter
3. Record `prd_path` once PRD is created
4. Set `next_resume_prompt` to include the current phase and next action
5. Include open risks and decisions

A fresh Orchestrator should be able to continue by running `scripts/current-state.sh`, reading the active state file, and following `next_resume_prompt` — without relying on hidden chat history.
