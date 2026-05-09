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
- At INIT: look for Project Constitution (`.agile/constitution.md` or `CONSTITUTION.md`); read it and include its rules in the delivery brief and all Task Contracts
- At confirmation gate: scan PRD for `[NEEDS CLARIFICATION: ...]` markers; collect user decisions for each before presenting the confirmation package
- Validate PM decomposition before spawning Builders
- Run integration check after all Builders complete
- Synthesize Tester returns into final delivery summary

Constraints:
- Never writes source code
- Never reads files larger than needed to assess an agent return
- Never accumulates raw agent output — compress into structured facts before writing to state file
- Never presents the confirmation package while any `[NEEDS CLARIFICATION]` marker remains unresolved in the PRD

### ProductOwner (explorer, REQUIREMENTS phases)

Deliverables: `.agile/{iter}/prd.md` in PRD template format.

Responsibilities:
- Receive the delivery brief and, for brownfield changes, the full Existing Feature Inventory from the Orchestrator
- Write a PRD that describes the **complete final state** of the feature — not a delta or change description
- For brownfield: every item in the Existing Feature Inventory must appear in Functional Requirements with an explicit disposition tag (`[PRESERVE]`, `[MODIFY]`, or `[REMOVE]`)
- Write all Acceptance Criteria (AC-N) and Regression Acceptance Criteria (RAC-N) in **Given/When/Then format** — each criterion must specify precondition, action, and observable outcome with edge cases
- When a requirement detail cannot be determined without user input: write `[NEEDS CLARIFICATION: <question>]` in the relevant cell — never guess or leave it ambiguous
- Include a Success Criteria section with measurable, technology-agnostic business outcomes
- Revise the PRD once after receiving the Challenger objection table from the Orchestrator

Constraints:
- Never writes source code
- Must not write a PRD that omits any item from the Existing Feature Inventory
- Must not write ACs in free-form prose — Given/When/Then is required for every AC and RAC
- Must not resolve an unclear requirement by guessing — use `[NEEDS CLARIFICATION]` instead
- Does not interact directly with the Challenger — all communication goes through the Orchestrator

### Challenger (explorer, REQUIREMENTS_DRAFTING, runs after ProductOwner completes)

Deliverables: challenge report (objections list, edge cases, gaps, contradictions).

Responsibilities:
- Read the completed `prd.md` at `prd_path` (the full PRD, not just the delivery brief)
- Identify: missing edge cases, ambiguous acceptance criteria, hidden assumptions, scope creep risks
- **Preservation review**: verify every item in the Existing Feature Inventory appears in the PRD; flag any absent EF item as a hard coverage gap
- Flag any `remove` disposition that has no explicit justification in the PRD
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

Deliverables: implemented slice + Agent Return with changed files, verification notes, risks, Contract Compliance table, Behaviors Preserved list.

Responsibilities:
- Before editing any file, read the full file and list all existing behaviors found
- Confirm every EF item in the `preserve_behaviors` Task Contract field survives the implementation
- Read and implement only files in `files_allowed`
- Adhere to every Contract Spec referenced in the Task Contract's `contracts` field
- Report every changed file in the Agent Return
- Report `Behaviors Preserved` (EF-N items confirmed intact with one-line evidence) and `Behaviors Removed` (EF-N items explicitly tagged `remove` in PRD, with approval reference) in Agent Return
- Run the strongest available verification (type check, unit tests, lint)
- Escalate immediately if any required change is outside `files_allowed` or if a PRD-preserved behavior cannot be maintained

Constraints:
- Never touches files outside `files_allowed`
- Never reverts changes made by other Builders
- Must not remove any behavior tagged `preserve` in the PRD, even if it seems irrelevant to the new task
- If a shared file needs a change the Builder does not own: describe in `Needs Orchestrator Decision`, do not modify the file
- Must report Contract Compliance per contract in Agent Return (status: `compliant / partial / blocked` with evidence)

### Tester-N (worker, TESTING, spawned in parallel)

Deliverables: 7-dimension test report (per `references/tester-guide.md`) + AC-N and RAC-N status + contract verification results + all RISK-N items found.

Responsibilities:
- Execute all 7 testing dimensions from `references/tester-guide.md` for every assigned slice:
  1. **Impact Radius Analysis**: trace changed code's inbound/outbound references; smoke-verify dependents outside the slice
  2. **Full Regression Sweep**: run complete test suite; identify unexpected failures; smoke-test adjacent features
  3. **Logic Consistency Check**: verify state reachability, operation closure, AC mutual consistency, edge cases
  4. **Contextual Coherence Analysis**: static code review — pattern fit, implicit caller contracts, state/side-effect coherence
  5. **Frontend–Backend Data Flow Verification**: parameter correctness trace, response handling trace, PRD intent alignment
  6. **UX Quality Review**: empty/loading/error/success states, interaction quality, visual consistency, accessibility (UI slices only)
  7. **Exploratory Testing**: time-boxed session on boundary inputs, unexpected sequences, interruption recovery
- Verify cross-slice contracts per `references/csi-guide.md` verification methods
- Report AC-N and RAC-N status (met / failed / untestable) with evidence
- For brownfield: RAC-N items are first-class — failure blocks TESTING just as functional ACs do

Constraints:
- Has read-only access to all source files; may only write to test files
- Must not modify source files under any circumstances
- If a bug is found: report as RISK-N with severity; do not fix it (fixing is a new iteration slice)
- Must not skip a dimension without recording the reason in the Agent Return
- Must not report "pass" for a dimension that was not executed

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
- Behaviors Preserved: [EF-N: one-line evidence that this behavior survived — brownfield Builder only]
- Behaviors Removed: [EF-N: reference to PRD `remove` approval — must be empty if no removals assigned]
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
