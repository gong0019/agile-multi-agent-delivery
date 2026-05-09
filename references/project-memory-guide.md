# Project Memory Guide

This reference defines the `.agile/PROJECT.md` file — the project-level memory document that persists across all iterations. Unlike iteration state files (which are per-iteration snapshots), PROJECT.md is the single accumulating record of what the project is, what has been built, and what the next iteration should know before it starts.

---

## What PROJECT.md Is

A living document that grows with each completed iteration. It answers three questions:

1. **What exists?** — the Feature Registry of all delivered capabilities
2. **What must not break?** — Active CSI Contracts and Architecture Decisions that future builders must respect
3. **What's next?** — Known Limitations, Deferred Items, and Next Iteration Candidates

PROJECT.md is NOT a state file. It does not track slice boards, phase transitions, or per-iteration decisions. It is a distilled record of cross-iteration knowledge.

---

## File Location

```
[project-root]/
  .agile/
    PROJECT.md        ← project-level memory (this file)
    CURRENT           ← one-line: active iteration ID
    iter-YYYYMMDD-01/ ← per-iteration files
```

If `.agile/PROJECT.md` does not exist when the first iteration starts, it is created at the end of that iteration's COMPLETE phase.

---

## PROJECT.md Template

```markdown
---
project_name: "[project name]"
created_at: "[ISO 8601 timestamp]"
last_updated: "[ISO 8601 timestamp]"
current_product_version: "[semver — matches last completed iteration's product_version]"
total_iterations: N
---

# Project Memory

## Feature Registry

All features delivered across all iterations. One row per delivered capability.

| Feature ID | Feature | Iteration | Product Version | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| FEAT-1 | `[feature name]` | `iter-YYYYMMDD-01` | `v1.0.0` | `delivered` | `[brief]` |

Status values: `delivered` / `modified` (updated in a later iteration) / `removed` (explicitly deleted)

## Active CSI Contracts

Cross-slice interface contracts from previous iterations that remain valid across future iterations.
Any future Builder working on code that touches these interfaces MUST respect these contracts.
A future PM may propose amendments — but only after flagging the conflict and getting user approval.

| Contract ID | Interface | Defined In | Spec Summary | Breaking Change Risk |
| --- | --- | --- | --- | --- |
| XSIC-1 | `[endpoint / type / schema name]` | `iter-YYYYMMDD-01` | `[key fields, types, HTTP method, response shape]` | `high / medium / low` |

## Architecture Decisions

Key technical decisions made in previous iterations that constrain future work.

| Decision ID | Decision | Made In | Rationale | Expires |
| --- | --- | --- | --- | --- |
| PDEC-1 | `[decision]` | `iter-YYYYMMDD-01` | `[why — the constraint it encodes]` | `never` / `[condition under which it may be revisited]` |

## Known Limitations

Unresolved RISK-N items from previous iterations that future iterations may need to address.

| Risk ID | Description | Severity | From Iteration | Status |
| --- | --- | --- | --- | --- |
| PRIS-1 | `[description of the risk or limitation]` | `critical / high / medium / low` | `iter-YYYYMMDD-01` | `open / mitigated / resolved-in-[iter]` |

## Deferred Items

Features or improvements explicitly deferred from previous iterations.

| Item ID | Description | Deferred From | Reason | Suggested Priority |
| --- | --- | --- | --- | --- |
| DEF-1 | `[feature or improvement]` | `iter-YYYYMMDD-01` | `[out of scope / too risky / user decision]` | `high / medium / low` |

## Next Iteration Candidates

Proposed topics for the next iteration, ranked by priority. The Orchestrator presents these at COMPLETE.

| Priority | Candidate | Rationale | Source |
| --- | --- | --- | --- |
| 1 | `[topic]` | `[why it matters now]` | `PRIS-N / DEF-N / user-request / design-gap` |
```

---

## Reading Protocol (INIT Phase)

When the Orchestrator starts a new iteration, it MUST check for `.agile/PROJECT.md` before drafting the delivery brief.

**If PROJECT.md does not exist:** proceed without cross-iteration context (first iteration).

**If PROJECT.md exists:**

1. Read the entire file (it must remain concise — see Writing Protocol below).
2. Extract and inject into the delivery brief under a **"Project History"** section:

   ```
   ## Project History (from .agile/PROJECT.md)
   
   Current product version: v1.2.0 (as of iter-20260510-01)
   
   Existing features (all iterations):
   - FEAT-1: [name] (iter-20260508-01, delivered)
   - FEAT-2: [name] (iter-20260510-01, delivered)
   
   Active CSI Contracts (must not break without explicit amendment):
   - XSIC-1: POST /api/v1/users — {username, email} → {id, token} [high breaking risk]
   
   Architecture Decisions in force:
   - PDEC-1: [decision] — [brief rationale]
   
   Known Limitations from previous iterations:
   - PRIS-1: [description] (severity: high) — open
   
   Deferred Items available for this iteration:
   - DEF-1: [description] (priority: high)
   ```

3. Pass this Project History to the ProductOwner when spawning Step 2a. The PO must incorporate it:
   - For brownfield changes: the EFI must cover all FEAT-N items that are in the affected area
   - Active CSI Contracts appear in the PRD's Technical Constraints section
   - Architecture Decisions appear in Technical Constraints

4. Pass Active CSI Contracts to the ProjectManager as additional constraints. The PM must:
   - Treat XSIC-N contracts as pre-existing Contract Specs — they cannot be overridden without an explicit amendment proposal
   - If a new requirement conflicts with an XSIC-N contract: record a PRD Gap Report noting the conflict; the Orchestrator resolves per error-recovery.md Section 14

---

## Writing Protocol (COMPLETE Phase)

When an iteration reaches COMPLETE, the Orchestrator updates `.agile/PROJECT.md` before presenting the delivery summary to the user. If the file does not exist, create it from the template.

**Steps:**

1. **Feature Registry** — for each slice that reached `done` status, add a row:
   - Feature ID: next available `FEAT-N`
   - Feature: concise name from the PRD's Functional Requirements
   - Iteration: current `iteration_version`
   - Product Version: current `product_version`
   - Status: `delivered`
   - If the slice modified an existing FEAT-N: change that row's Status to `modified` and add a Notes entry referencing the current iteration

2. **Active CSI Contracts** — for each Contract Spec (C-N) produced in PM_DECOMPOSITION:
   - If the interface will be called by future iterations (APIs, shared types, DB schemas): add as XSIC-N
   - Summarize: HTTP method + path, key request/response fields, critical constraints
   - Assess breaking change risk: high (external API or type used everywhere), medium (internal service), low (single-consumer utility)
   - If an existing XSIC-N was amended in this iteration: update its row and note the new shape

3. **Architecture Decisions** — for each `DEC-N` item recorded in the state file that encodes a lasting constraint:
   - Include in PDEC-N only if the decision remains binding for future iterations
   - Skip ephemeral decisions (e.g., "used Builder B for slice 3" — not a lasting constraint)

4. **Known Limitations** — for each unresolved `RISK-N` item with severity `high` or `critical`:
   - Add as PRIS-N
   - If an existing PRIS-N was resolved in this iteration: change its status to `resolved-in-[iter]`

5. **Deferred Items** — for each item in the PRD's Out of Scope section that was deferred (not eliminated):
   - Add as DEF-N with the reason
   - If an existing DEF-N was addressed in this iteration: remove it from the list

6. **Next Iteration Candidates** — propose 2–4 candidates ranked by priority:
   - PRIS-N items with unresolved severity `critical` or `high`
   - DEF-N items with suggested priority `high`
   - Gaps discovered during PM Step 0.5 or Tester RISK-N items
   - Logical next steps from the delivered feature (e.g., "delivered the list view → natural next: detail view")

7. **Update frontmatter**: `last_updated`, `current_product_version`, `total_iterations`

**Size discipline:** PROJECT.md must not grow unbounded. Keep each section to the minimum needed for a new Orchestrator to make informed decisions. Compress old rows into summaries when a section exceeds 20 rows.

---

## Cross-Iteration Interface Inheritance Rules

These rules govern how XSIC-N contracts from PROJECT.md constrain new iterations:

### Rule 1: Active contracts are read-only by default

A new iteration's PM and Builders treat every XSIC-N contract as a fixed constraint — not a suggestion. They may propose an amendment, but may not unilaterally deviate.

### Rule 2: Amendment requires explicit escalation

If a new PRD requires behavior that conflicts with an XSIC-N contract:

1. PM records the conflict in the PRD Gap Report (Step 0.5)
2. Orchestrator presents the conflict to the user: "New requirement X conflicts with XSIC-N (defined in iter-YYYYMMDD-01). Options: amend the contract (may require coordination with consumers), or constrain the new requirement to avoid the conflict."
3. User decides
4. If amended: update XSIC-N in PROJECT.md and update the affected Contract Spec in the current iteration's state file

### Rule 3: New interfaces become candidates for XSIC-N

At COMPLETE, every C-N contract is evaluated for promotion to XSIC-N. Promote if:
- The interface crosses a frontend/backend boundary (always promote)
- The interface is shared by multiple features or future-iteration scope is likely
- The contract encodes a business rule, not just an implementation detail

Do not promote: utility types internal to one module that have no cross-iteration consumers.

### Rule 4: Version compatibility

When amending an XSIC-N contract, record both the old and new shape if consumers from previous iterations might still be in production. If the project has no versioning concern (e.g., a monorepo with no external consumers), the old shape can be dropped.

---

## Conflict Resolution

When a new iteration's requirements conflict with PROJECT.md content, always escalate rather than silently override. The project memory represents hard-won decisions — circumventing it without a recorded decision is the pattern that PROJECT.md was created to prevent.

See `references/error-recovery.md` Section 14 for the full conflict recovery procedure.
