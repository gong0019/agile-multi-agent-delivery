---
name: agile-multi-agent-delivery
version: "2.4.0"
description: |
  Run a software task like a disciplined pipeline of independent agents. The main agent acts as a pure Orchestrator — it never writes code. Instead it drives a phase-gated pipeline: ProductOwner drafts a complete-state PRD (including brownfield feature inventory), Challenger reviews the completed PRD, one ProjectManager decomposes work into bounded slices with cross-slice contracts, N Builder agents implement in parallel with strictly disjoint file ownership and explicit preservation mandates, an integration check gate (including behavioral regression check), and M Tester agents. Every phase produces a validated artifact. The state file survives context resets. A project-level memory file (.agile/PROJECT.md) accumulates cross-iteration knowledge so each new iteration knows what was built before.
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
 └→ REQUIREMENTS_DRAFTING    ProductOwner (drafts complete-state PRD) → Challenger (reviews completed PRD)
 └→ REQUIREMENTS_REVIEW      Orchestrator mediates divergence → user confirms
 └→ REQUIREMENTS_CONFIRMED   PRD locked
 └→ PM_DECOMPOSITION         ProjectManager decomposes PRD into bounded slices
                              ↳ identifies Cross-Slice Interfaces (CSIs)
                              ↳ produces Contract Specs for every CSI
 └→ BUILDING                 N Builder agents (parallel, disjoint file ownership)
 └→ INTEGRATION_CHECK        Orchestrator validates all Builder returns + Contract Compliance
 └→ TESTING                  M Tester agents (parallel, 7-dimension protocol per tester-guide.md)
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
    PROJECT.md                     ← project-level memory, persists across all iterations
    constitution.md                ← optional: inviolable project-wide engineering rules
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

0. **Read Project Memory** — check for `.agile/PROJECT.md`:
   - If it exists: read it in full. Extract and carry forward into the delivery brief under a **"Project History"** section:
     - Current product version (from last completed iteration)
     - All delivered features (FEAT-N rows) — especially those in the area being changed
     - Active CSI Contracts (XSIC-N) — must not break without explicit amendment and user approval
     - Architecture Decisions (PDEC-N) in force — future builders must respect these
     - Known Limitations (PRIS-N open items) — may be in scope for this iteration
     - Deferred Items (DEF-N) — candidate input for this iteration's scope
   - If it does not exist: proceed without cross-iteration context (this is the first iteration).
   - Pass the full Project History to the ProductOwner in Step 2a. The PO must incorporate Active CSI Contracts and Architecture Decisions into the PRD's Technical Constraints section.

1. Read repository rules already required by the environment.
1b. Look for a **Project Constitution** — check `.agile/constitution.md`, then `CONSTITUTION.md` in the project root.
   - If found: read it. Record it in the delivery brief under "Constitution Rules." Every Task Contract in this iteration will inherit these rules in its `must_respect` field. The constitution is non-negotiable — no agent may silently skip a constitution rule.
   - If not found: proceed without one. Optionally note to the user that creating one (`references/constitution-guide.md`) would give all future agents consistent project-wide constraints.
2. Classify the request and read accordingly:
   - **greenfield** (new module, page, or feature with zero existing code in that area): inspect minimal code and docs needed to understand the request.
   - **brownfield** (modifying an existing module, page, or feature): read all files in the affected module to enumerate every existing behavior. Before drafting the brief, produce an **Existing Feature Inventory**:

     | EF-ID | Feature | Current Behavior | Disposition |
     | --- | --- | --- | --- |

     Disposition values: `preserve` / `modify` / `remove`. Any `remove` item requires explicit user approval at the confirmation gate. Include this table in the delivery brief — it is the source of truth for the ProductOwner.

3. Rewrite the request into a concrete delivery brief:
   - target outcome
   - business reason or user value
   - in-scope items
   - explicit out-of-scope items
   - constraints
   - candidate acceptance criteria
   - unknowns and risks

Do not ask a long list of questions. Infer aggressively. Ask only for details that would change the outcome or create material risk.

### 2. Spawn Requirements Agents (sequential)

#### Step 2a: Spawn ProductOwner

Spawn the ProductOwner agent. Provide: the delivery brief and, for brownfield changes, the full Existing Feature Inventory table.

- **ProductOwner**: Write `.agile/{iter}/prd.md` using `references/prd-template.md`.
  - The PRD must describe the **complete final state** of the feature, not just the changes (never a delta description).
  - For brownfield: every item in the Existing Feature Inventory must appear in Functional Requirements with an explicit disposition tag: `[PRESERVE]`, `[MODIFY]`, or `[REMOVE]`.
  - Acceptance Criteria must include regression ACs (tagged `[REGRESSION]`) for every EF item tagged `preserve` or `modify`.
  - Must not omit any item from the Existing Feature Inventory.

Wait for the ProductOwner to complete and confirm `prd.md` is written before proceeding to Step 2b.

#### Step 2b: Spawn Challenger

After `prd.md` is written, spawn the Challenger agent with the completed PRD path.

- **Challenger**: Read `.agile/{iter}/prd.md` and produce a challenge report:
  - Missing edge cases, ambiguous acceptance criteria, hidden assumptions, scope creep risks.
  - **Preservation review**: verify that every item in the Existing Feature Inventory appears in the PRD. Flag any EF item absent from the PRD as a hard coverage gap.
  - Flag any `remove` disposition that has no explicit justification.

The Challenger reviews the actual completed PRD, not just the delivery brief. The two agents do not communicate directly — all exchange goes through the Orchestrator.

### 3. Requirements Review and Confirmation Gate

The Orchestrator collects both returns and:

0. **`[NEEDS CLARIFICATION]` gate**: scan the PRD for any `[NEEDS CLARIFICATION: ...]` markers in Functional Requirements or Acceptance Criteria. If any are found:
   - List each one explicitly with its context.
   - Present them to the user and collect decisions.
   - Only after every marker is replaced with a concrete spec may the confirmation package be presented.
   - Do not present the confirmation package while any `[NEEDS CLARIFICATION]` marker remains unresolved.

1. Compiles a divergence table (objection vs. ProductOwner position).
2. Presents one compact confirmation package to the user:
   - PRD summary (new and changed features)
   - Divergence table with recommended resolution for each objection
   - **Complete Feature State Table** (brownfield only) — every existing feature with its final disposition:

     | Feature | Before | After | Disposition |
     | --- | --- | --- | --- |

     This table lets the user verify that nothing is silently removed.
   - Any `remove` items called out explicitly: "The following existing features will be **REMOVED**. Please confirm each."
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

**For brownfield changes**, the ProjectManager must execute Step 0.5 (PRD Completeness Check) from `references/pm-decomposition-guide.md` before decomposing. If the PM returns a PRD Gap Report, resolve all gaps — adding items to the Existing Feature Inventory or explicitly recording them as out-of-scope (DEC-N) — before proceeding.

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
- verify every EF item tagged `preserve` in the PRD appears in at least one Builder's `preserve_behaviors` list; if any is unassigned, return the plan to the ProjectManager for correction
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
- `must_respect`: API contracts (by Contract ID), migration constraints, coding standards, **all Project Constitution rules** (if a constitution was read at INIT — include each rule verbatim)
- `expected_deliverable`: Agent Return with changed files, verification, risks, Contract Compliance table
- `stop_when`: all owned files implemented and verified
- `escalate_if`: any required change is outside `files_allowed`

**Builder pre-modification mandate**: Before editing any file in `files_allowed`, the Builder must:
1. Read the full file and list all existing behaviors found.
2. Confirm every behavior in the `preserve_behaviors` Task Contract field survives the implementation.
3. If a PRD-preserved behavior would be lost by the required changes: escalate immediately under `Needs Orchestrator Decision`. Do not remove it.

Builder Agent Return must include two additional fields:
- `Behaviors Preserved`: list of EF-N items (from `preserve_behaviors`) confirmed intact, with one-line evidence each.
- `Behaviors Removed`: list of EF-N items explicitly tagged `remove` in the PRD, with reference to the user's approval in the Approval Record. Must be empty if no `remove` dispositions were assigned to this slice.

While Builders run, the Orchestrator updates the state file phase log and prepares the integration check criteria. Do not wait idly.

**Contract amendment during build**: Builders cannot communicate with each other mid-build. If a Builder discovers a contract issue, it marks the contract as `partial` or `blocked` in the Agent Return and describes the problem under `Needs Orchestrator Decision`. The Orchestrator resolves all contract escalations during Integration Check — see `references/error-recovery.md` Section 10-b for the full amendment loop.

### 7. Integration Check Gate

After all Builders return, the Orchestrator performs a structured check — based on agent returns only, no file reading:

1. Check `files_changed` across all returns for unexpected overlap.
2. Check for any `RISK` items with severity `high` or `critical`.
3. Check that all slices report a `Validation Performed` entry.
4. Check Contract Compliance: every Builder bound to a contract must report compliance status. Cross-check provider and consumer reports for the same contract — if they disagree, flag as `RISK-N: contract-drift`.

5. **Behavioral Regression Check** (brownfield only): cross-reference the PRD's Existing Feature Inventory (`preserve` and `modify` items) against all Builder returns' `Behaviors Preserved` lists. Every EF item tagged `preserve` must appear in at least one Builder's `Behaviors Preserved`. Any EF item with no corresponding entry → `RISK-N: behavioral-regression-EF-[N]`. Do not proceed to TESTING if any behavioral-regression risk is unresolved.

**If check passes**: update state file to `phase: TESTING`, spawn Tester agents.

**If check fails**: create one Integrator agent with a narrowly scoped Task Contract targeting only the conflict, critical risk, or contract drift. After Integrator completes, re-run the check.

### 8. Parallel Testing

`tester_count = max(1, ceil(builder_count / 2))`

Each Tester covers 2 Builders' output. Assign by feature proximity.

Tester Task Contract requirements:

- `agent_role`: `tester`
- `files_allowed`: test files for assigned slices, plus read-only access to all source files
- `files_avoid`: source files (no modifications)
- `slices_covered`: list of SL-N IDs assigned to this Tester
- `prd_path`: path to confirmed PRD (for intent alignment verification)
- `contracts`: list of Contract IDs to verify (from CSI system)
- `expected_deliverable`: Agent Return per `references/tester-guide.md` — 7-dimension results table, AC-N and RAC-N status, contract verification, all risks

The Tester executes **7 testing dimensions** defined in `references/tester-guide.md`:

1. **Impact Radius Analysis** — trace changed code's dependents; smoke-verify code outside the slice
2. **Full Regression Sweep** — run the full test suite; identify unexpected failures outside assigned slices
3. **Logic Consistency Check** — verify all states reachable, all operations closed, ACs mutually consistent, edge cases handled
4. **Contextual Coherence Analysis** — static review: does the change fit its surrounding code patterns and implicit contracts with callers?
5. **Frontend–Backend Data Flow Verification** — parameter correctness trace, response handling trace, business intent alignment against PRD
6. **UX Quality Review** — empty/loading/error/success states, interaction quality, visual consistency, accessibility basics (UI slices only)
7. **Exploratory Testing** — time-boxed session targeting boundary inputs, unexpected sequences, interruption recovery

Bugs and deviations found by Testers are recorded as `RISK-N` items with severity. Fixing them is a new iteration slice, not part of the current Tester's scope.

**Regression mandate** (brownfield only):
- For every EF item tagged `preserve` or `modify` in the PRD: include at least one test (Dimension 2 + 3).
- Regression ACs (tagged `[REGRESSION]`) are first-class — failure blocks the TESTING phase.
- Untested regression ACs must be reported as `RISK-N: regression-coverage-gap-EF-[N]`, not silently skipped.

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
6. `.agile/PROJECT.md` is updated with this iteration's results (see steps below)
7. Next Iteration Candidates are presented to the user

**PROJECT.md update at COMPLETE** (per `references/project-memory-guide.md`):

Before presenting the delivery summary, the Orchestrator must update `.agile/PROJECT.md`. If the file does not exist, create it from the template in `references/project-memory-guide.md`.

Mandatory updates:

- **Feature Registry**: add one row per delivered slice. If a slice modified an existing FEAT-N, update that row's status to `modified`.
- **Active CSI Contracts**: promote Contract Specs (C-N) that cross feature boundaries or will be consumed by future iterations to XSIC-N entries. Summarize key field names, types, HTTP methods, and response shapes.
- **Architecture Decisions**: add any iteration-level DEC-N item that encodes a lasting constraint for future builders. Skip ephemeral decisions.
- **Known Limitations**: add unresolved RISK-N items with severity `high` or `critical` as PRIS-N entries. Mark previously open PRIS-N items as `resolved-in-[iter]` if addressed.
- **Deferred Items**: add explicitly deferred out-of-scope items as DEF-N entries. Remove DEF-N items addressed in this iteration.
- **Next Iteration Candidates**: propose 2–4 ranked candidates based on open PRIS-N, high-priority DEF-N, and logical next steps.

After updating PROJECT.md, present the user with:
1. Delivery summary (what was built, verification status, residual risks)
2. Next Iteration Candidates table from PROJECT.md — so the user can immediately kick off the next iteration with one line

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
