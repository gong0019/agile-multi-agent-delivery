---
name: agile-multi-agent-delivery
version: "2.0.0"
description: |
  Run a software task like a disciplined pipeline of independent agents. The main agent acts as a pure Orchestrator — it never writes code. Instead it drives a phase-gated pipeline: two requirement agents (ProductOwner + Challenger) in parallel, one ProjectManager that decomposes work into bounded slices, N Builder agents that implement in parallel with strictly disjoint file ownership, an integration check gate, and M Tester agents. Every phase produces a validated artifact. The state file survives context resets.
---

# Agile Multi Agent Delivery

Use this skill when the user wants a disciplined, multi-phase delivery workflow instead of a single linear coding pass.

This skill is for:

- multi-module or multi-file feature work
- iterative delivery with persistent state tracking
- implementation tasks that can be split into safe parallel slices
- requests that need explicit requirements, scope, acceptance criteria, and risk tracking

This skill is not for:

- one-off trivial edits
- brainstorming with no execution intent
- handing the whole critical path to subagents

---

## Architecture

### Pipeline Phases

```
INIT
 └→ REQUIREMENTS_DRAFTING    ProductOwner + Challenger (parallel, independent)
 └→ REQUIREMENTS_REVIEW      Orchestrator mediates divergence → user confirms
 └→ REQUIREMENTS_CONFIRMED   PRD locked
 └→ PM_DECOMPOSITION         ProjectManager decomposes PRD into bounded slices
                              ↳ identifies Cross-Slice Interfaces (CSIs)
                              ↳ produces Contract Specs for every CSI
 └→ BUILDING                 N Builder agents (parallel, disjoint file ownership)
 └→ INTEGRATION_CHECK        Orchestrator validates all Builder returns + Contract Compliance
 └→ TESTING                  M Tester agents (parallel)
 └→ COMPLETE
```

### Role Set

| Role | Type | Owns | Never Does |
| --- | --- | --- | --- |
| Orchestrator | main agent | state file, phase transitions, user communication | writes code, reads large source files |
| ProductOwner | explorer | PRD document | writes code |
| Challenger | explorer | adversarial PRD review | writes code, modifies PRD directly |
| ProjectManager | explorer | decomposition plan, Task Contracts | writes code, makes product decisions |
| Builder-N | worker | one bounded implementation slice | touches files outside its Task Contract |
| Tester-N | worker | test files for assigned slices | modifies non-test source files |
| Integrator | worker (optional) | cross-slice integration conflicts | re-implements already-done slices |

---

## Iteration Directory Structure

All skill-generated files live under `.agile/` in the repository root. This keeps the project's own files completely untouched.

```
[project-root]/
  .agile/
    CURRENT                        ← one-line text file: active iteration ID
    iter-20260508-01/              ← active iteration
      state.md                     ← machine-validated delivery state
      prd.md                       ← PRD document (created in REQUIREMENTS phase)
    iter-20260421-01/              ← completed iteration, permanently archived
      state.md
      prd.md
```

**Key invariants:**

- `CURRENT` is the single authority on which iteration is active
- Each iteration directory is named `iter-YYYYMMDD-NN` (auto-increments if multiple per day)
- Completed iterations (`phase: COMPLETE`) remain in their directory forever — never deleted or overwritten
- Starting a new iteration creates a new directory; the previous one is untouched
- Commit `.agile/` to git to preserve the full delivery history

**Required files (skill infrastructure, not generated per project):**

- Template: `references/iteration-state-template.md`
- PRD template: `references/prd-template.md`
- Role boundaries: `references/team-operating-model.md`
- PM decomposition rules: `references/pm-decomposition-guide.md`

---

## Workflow

### 1. Build the Delivery Brief (Orchestrator)

Before doing any substantial work:

1. Read repository rules already required by the environment.
2. Inspect only the minimal code and docs needed to understand the request.
3. Rewrite the request into a concrete delivery brief:
   - target outcome
   - business reason or user value
   - in-scope items
   - explicit out-of-scope items
   - constraints
   - candidate acceptance criteria
   - unknowns and risks

Do not ask a long list of questions. Infer aggressively. Ask only for details that would change the outcome or create material risk.

### 2. Spawn Requirements Agents (parallel)

After forming an initial understanding, spawn ProductOwner and Challenger in the same turn:

- **ProductOwner**: Write `.agile/{iter}/prd.md` using `references/prd-template.md`. Include user stories, functional requirements (with AC-N IDs), non-functional requirements, out-of-scope items, and open questions.

- **Challenger**: Read the PRD draft and produce a challenge report: missing edge cases, ambiguous acceptance criteria, hidden assumptions, scope creep risks.

Both agents work independently. They do not communicate with each other.

### 3. Requirements Review and Confirmation Gate

The Orchestrator collects both returns and:

1. Compiles a divergence table (objection vs. ProductOwner position).
2. Presents one compact confirmation package to the user: the PRD summary, the divergence table, and a recommended resolution for each objection.
3. After user confirms: ProductOwner produces the final PRD (prd_version incremented, status: confirmed). Run `scripts/validate-prd.sh` on the final PRD.
4. Update state file: `phase: REQUIREMENTS_CONFIRMED`, `prd_path: .agile/{iter}/prd.md`.

Do not start decomposition before user confirmation.

After confirmation, enter autonomous execution mode. Do not ask permission on every micro-step unless there is destructive risk, genuine ambiguity, or a product choice that materially changes UX, data shape, or architecture.

### 4. Initialize or Update the Persistent State

Create or update `.agile/{iteration_version}/state.md` immediately after confirmation. Use `scripts/init-state.sh` to create the iteration directory if it does not exist. Use `scripts/current-state.sh` to locate the active state file in subsequent steps.

This file is the single source of truth across `/clear`, new threads, and context compression. Update it after every phase transition and every completed slice.

Run `scripts/validate-state.sh` (no argument needed — it reads `CURRENT` automatically) before delegating new work and after completing a slice.

Required frontmatter fields:

- `skill_version` — version of this skill
- `phase` — current pipeline phase
- `product_version` — semantic version of the product
- `iteration_version` — `iter-YYYYMMDD-NN`
- `overall_completion` — percentage matching slice board within 10%
- `current_slice_completion`
- `last_updated` — ISO 8601 with timezone
- `prd_path` — path to confirmed PRD
- `builder_count` — set by PM decomposition
- `tester_count` — set by PM decomposition
- `active_objective`
- `acceptance_criteria` — array with AC-N IDs
- `slice_board` — array with SL-N IDs
- `next_resume_prompt` — exact instruction for resuming after reset

Use stable IDs: `AC-N`, `DEC-N`, `SL-N`, `RISK-N`, `TASK-N`.

### 5. ProjectManager Decomposition

Spawn one ProjectManager agent. Provide:

- the confirmed PRD path
- a compact summary of the repository structure (file tree, not file contents)
- a reference to `references/pm-decomposition-guide.md`
- a reference to `references/csi-guide.md`

The ProjectManager must return:

- an Interface Conventions Summary (brownfield only — extracted from existing interface-layer code per Step 8 of pm-decomposition-guide.md)
- an ownership map (strict disjoint sets: `{SL-N: [file1, file2]}`)
- one Contract Spec per Cross-Slice Interface per `references/csi-guide.md`
- one Task Contract per Builder (each listing its bound Contract IDs, design constraints for frontend slices)
- `builder_count` and `tester_count`

Before spawning Builder agents, the Orchestrator validates:

- run `scripts/check-constraints.sh` which checks Constraint 7 (no two slices share a file in BUILDING phase)
- verify every Contract ID referenced in a Task Contract has a corresponding Contract Spec
- verify every CSI has both a provider and at least one consumer bound to it
- if conflicts or missing contracts found: return the plan to the ProjectManager for re-decomposition

Update state file: `phase: BUILDING`, `builder_count: N`, `tester_count: M`.

#### Granularity Rules (summary)

| Estimated file changes | Builder count |
| --- | --- |
| 1–3 | 1 |
| 4–10 | 2–3 |
| 11–20 | 3–4 |
| 21+ | 4–6 (hard max) |

Full rules in `references/pm-decomposition-guide.md`.

### 6. Parallel Building

Spawn all Builder agents in the same turn. Each Builder receives its Task Contract.

Builder Task Contract requirements:

- `task_id`: `TASK-N`
- `phase`: `BUILDING`
- `agent_role`: `builder`
- `parallel_group`: same tag for this batch
- `files_allowed`: exact owned files
- `files_avoid`: all files owned by other Builders
- `contracts`: list of Contract IDs this Builder must comply with
- `must_respect`: API contracts (by Contract ID), migration constraints, coding standards
- `expected_deliverable`: Agent Return with changed files, verification, risks, Contract Compliance table
- `stop_when`: all owned files implemented and verified
- `escalate_if`: any required change is outside `files_allowed`

While Builders run, the Orchestrator updates the state file phase log and prepares the integration check criteria. Do not wait idly.

**Contract amendment during build**: Builders cannot communicate with each other mid-build. If a Builder discovers a contract issue, it marks the contract as `partial` or `blocked` in the Agent Return and describes the problem under `Needs Orchestrator Decision`. The Orchestrator resolves all contract escalations during Integration Check — see `references/error-recovery.md` Section 10-b for the full amendment loop.

### 7. Integration Check Gate

After all Builders return, the Orchestrator performs a structured check — based on agent returns only, no file reading:

1. Check `files_changed` across all returns for unexpected overlap.
2. Check for any `RISK` items with severity `high` or `critical`.
3. Check that all slices report a `Validation Performed` entry.
4. Check Contract Compliance: every Builder bound to a contract must report compliance status. Cross-check provider and consumer reports for the same contract — if they disagree, flag as `RISK-N: contract-drift`.

**If check passes**: update state file to `phase: TESTING`, spawn Tester agents.

**If check fails**: create one Integrator agent with a narrowly scoped Task Contract targeting only the conflict, critical risk, or contract drift. After Integrator completes, re-run the check.

### 8. Parallel Testing

`tester_count = max(1, ceil(builder_count / 2))`

Each Tester covers 2 Builders' output. Assign by feature proximity.

Tester Task Contract requirements:

- `agent_role`: `tester`
- `files_allowed`: test files for assigned slices, plus read-only access to source files
- `files_avoid`: source files (no modifications)
- `expected_deliverable`: test results, AC-N status per criterion (met / failed / untestable), coverage gaps as RISK-N items

Bugs found by Testers are recorded as `RISK-N` items. Fixing them is a new iteration slice, not part of the current Tester's scope.

### 9. Cross-Slice Interface (CSI) Contract System

Parallel Builders with disjoint file ownership create a risk: any interface between slices is independently interpreted by each Builder. The CSI Contract System eliminates this risk by producing precise, shared specifications before any code is written.

#### CSI Types

| Type | When |
|------|------|
| `api-rest`, `api-rpc`, `api-graphql` | Any endpoint crossing slice boundaries (frontend↔backend, service↔service) |
| `shared-type` | Any type/interface/enum/model consumed by multiple slices |
| `db-schema` | Any table/collection/index created by one slice and queried by another |
| `event` | Any event/message published by one slice and consumed by another |
| `behavioral` | Auth flows, routing, state transitions that span slices |
| `operational` | Config keys, env vars, feature flags shared across slices |

Full identification heuristics and Contract Spec templates: `references/csi-guide.md`.

#### Contract Lifecycle

1. **PM identifies CSIs** during decomposition (Step 8 of `references/pm-decomposition-guide.md`)
2. **PM produces a Contract Spec** for every CSI (Step 9) — precise enough that two Builders who only read the contract produce compatible code
3. **Task Contracts bind Builders to contracts** — `must_respect` references Contract IDs
4. **Builders report Contract Compliance** in Agent Returns — `compliant / partial / blocked` per contract
5. **Orchestrator validates contracts** during Integration Check — cross-checks provider vs consumer reports
6. **Testers verify contracts** in TESTING phase — actual requests, type checks, schema introspection

#### Orchestrator Responsibility

The Orchestrator does not read source code to verify contracts. Instead:
- Confirms every contract has compliance reports from all bound Builders before TESTING
- Flags contract drift (provider says compliant, consumer says partial) as `RISK-N: contract-drift`
- Testers perform the code-level contract verification

### 10. Versioning Rules

`product_version` follows semantic intent:
- major: breaking flow, migration, or architecture reset
- minor: new feature slice or meaningful capability expansion
- patch: bug fix, refinement, or small behavior correction

`iteration_version` format: `iter-YYYYMMDD-NN`

Bump `iteration_version` when a new confirmed request or new major slice starts. Do not bump for brief revisions or consistency fixes.

### 11. Update Cadence

Update the active state file (`.agile/{iteration_id}/state.md`) when any of these happen:

- request is confirmed
- phase transitions
- a slice starts or completes
- scope changes
- a blocker appears
- integration check runs
- final delivery is ready

The file must always be complete enough for a fresh Orchestrator to resume with no other context.

Do not forward long subagent outputs verbatim. Compress into structured facts before writing to the state file.

### 12. Context Reset Protocol

The Orchestrator cannot execute `/clear` itself, but must actively prepare for it.

After each completed phase or major slice, write a precise resume prompt into the `next_resume_prompt` field of the active state file and tell the user:

`Run scripts/current-state.sh to find the active state file, read it, then continue with $agile-multi-agent-delivery from the next_resume_prompt field.`

The `next_resume_prompt` must include:
- current `phase`
- the next action (e.g. "Spawn Tester agents for SL-01 and SL-02")
- relevant decision and risk IDs to respect

### 13. Verification Rules

Every slice must end with the strongest practical verification available:

- targeted build or type check
- unit or integration coverage
- E2E or browser verification when user-facing behavior changed
- review pass for risk-heavy refactors

Record what was run, what was not run, and why.

### 14. Completion Rules

A request is complete only when all of these are true:

1. confirmed scope is implemented or explicitly deferred
2. the state file reflects the latest truth (`phase: COMPLETE`)
3. all acceptance criteria have a recorded status
4. verification status is recorded honestly
5. residual risks are surfaced
6. the next resume prompt is ready for the next iteration

### 15. State Validation Cadence

Run `scripts/validate-state.sh`:

- before delegating new work
- after completing a slice
- before declaring an iteration complete
- when resuming from a context reset

Run `scripts/validate-prd.sh`:

- after ProductOwner produces the PRD
- after the final confirmed revision

Run `scripts/check-constraints.sh`:

- before spawning Builder agents (validates ownership map via Constraint 7)
- when resuming from a context reset

### 16. Error Handling

When problems occur, follow `references/error-recovery.md`. Key scenarios:

- **User rejects brief**: record reason, ask targeted questions, rewrite
- **State file corruption**: recover from git history or re-initialize from template
- **Challenger blocks indefinitely**: after 2 rounds, compile table and escalate to user
- **PM ownership conflict**: reject plan, PM re-decomposes; after 2 failures Orchestrator resolves directly
- **Builder touches forbidden files**: assess impact, accept if non-conflicting, or revert and re-contract
- **Sub-agent incomplete work**: integrate valid portions, mark slice `in_progress`, escalate if critical
- **Context loss**: read `next_resume_prompt` from state file frontmatter

---

## Operating Stance

This skill should feel like a strong delivery pipeline:

- structured, not bureaucratic
- autonomous after confirmation
- aggressive about parallelism when file ownership is clean
- conservative about ambiguity and destructive risk
- explicit about ownership, verification, and phase continuity

---

## Resume Command

When resuming after `/clear` or in a new thread:

`Run scripts/current-state.sh to find the active state file, read it, then continue with $agile-multi-agent-delivery from the next_resume_prompt field.`
