# Error Recovery Procedures

This document defines how the agile multi-agent delivery skill handles common failure modes. The Orchestrator should reference these procedures when a problem occurs rather than improvising.

---

## 1. User Rejects the Delivery Brief

**Trigger:** The user does not approve the brief presented in the confirmation gate.

**Recovery:**

1. Record the rejection reason in the active state file under `Risks And Blockers` as `RISK-N: brief-rejected - [reason]`.
2. Ask targeted questions to clarify the specific objection (scope, approach, timeline, or assumptions).
3. Rewrite the brief with the corrected information.
4. Do not bump `iteration_version` for a brief revision — only bump when a confirmed request materially changes after work has begun.
5. Present the revised brief for confirmation.

**If the user keeps rejecting:** After two rejections, pause and ask whether the request should be split into smaller iterations or deferred.

---

## 2. State File Corruption or Format Error

**Trigger:** `scripts/validate-state.sh` reports the state file is invalid, or the frontmatter is missing/malformed.

**Recovery:**

1. Check `git log` for the last known-good version: `git log --oneline .agile/`
2. If a good version exists in git history: restore the iteration directory from git history
3. If no good version exists, rebuild from `references/iteration-state-template.md`:
   - Run `scripts/init-state.sh`
   - Manually re-fill fields from the Markdown body (which is not lost even if frontmatter is broken)
4. Bump `iteration_version` and record `DEC-N: state-rebuilt - [reason]` in the decisions section.

---

## 3. Sub-Agent Returns Incomplete or Invalid Results

**Trigger:** A Builder or Tester agent returns partial work, fails to report changed files, or introduces errors outside its allowed scope.

**Recovery:**

1. Record the issue under `Risks And Blockers`: `RISK-N: task-[ID]-incomplete - [description]`.
2. If the result is partially usable: integrate the valid portions and mark the slice as `in_progress` rather than `done`.
3. Do not re-delegate the same task to another agent without changing the contract — add a `Must Respect` clause referencing the previous attempt's failure.
4. If the task is on the critical path: the Orchestrator creates a targeted follow-up slice rather than re-delegating the full original task.
5. If the task is non-critical: defer it and record under `Next Steps`.

---

## 4. Concurrent Iteration Conflict

**Trigger:** Two threads or sessions attempt to update the same state file simultaneously.

**Recovery:**

1. The `.agile/` directory should always be under git version control.
2. Before starting work, run `git status` to check for uncommitted changes in `.agile/`.
3. If changes exist from another session: read the active state file, merge the relevant updates, and bump `iteration_version`.
4. Record `DEC-N: concurrent-merge - [summary]` in decisions.
5. If the conflict involves incompatible scope changes, ask the user which direction to take.

---

## 5. Context Loss After `/clear` or New Thread

**Trigger:** A new thread starts and the previous conversation history is unavailable.

**Recovery:**

1. The user (or new Orchestrator) should run: `scripts/current-state.sh` to locate the active state file, then read it.
2. The `next_resume_prompt` field in the frontmatter contains the exact instruction to continue.
3. If `next_resume_prompt` is empty or missing:
   - Read the `phase` field to identify the current pipeline stage
   - Read the `Slice Board` to find the first non-`done` slice
   - Read the `Decisions` and `Risks And Blockers` sections
   - Construct a resume prompt: `Continue from phase [PHASE], slice SL-XX [summary]. Respect DEC-N and RISK-N.`
4. Validate the state file with `scripts/check-constraints.sh` before resuming work.

---

## 6. State Drift (Markdown Body vs Frontmatter Disagreement)

**Trigger:** The YAML frontmatter says `overall_completion: "100%"` but the slice board shows `todo` items.

**Recovery:**

1. Run `scripts/check-constraints.sh` — it checks for this inconsistency.
2. Trust the slice board over the percentage. The percentage is a summary; the board is the detail.
3. Recalculate `overall_completion` based on slice status: `done_count / total_count * 100`.
4. Update both the frontmatter and the Markdown body to match.
5. Do not bump `iteration_version` for a consistency fix unless the scope itself changed.

---

## 7. Challenger Blocks Requirements Indefinitely

**Trigger:** After two challenge-and-revision rounds, the Challenger still raises unresolved objections and the PRD `status` remains `challenged`.

**Recovery:**

1. Record `RISK-N: requirements-stalled - [summary of unresolved objections]`.
2. The Orchestrator does NOT spawn a third challenge round.
3. Compile a resolution table from both agents' last returns:

   | Objection | ProductOwner Position | Recommended Resolution |
   | --- | --- | --- |
   | `[OBJ-1]` | `[position]` | `[accept / reject / defer]` |

4. Present the table to the user with a recommendation. User decides.
5. Once resolved, ProductOwner updates the PRD to `status: confirmed`. Proceed to PM_DECOMPOSITION.

---

## 8. ProjectManager Produces Overlapping File Ownership

**Trigger:** The Orchestrator's pre-spawn validation finds that two or more slices in the decomposition plan claim the same file.

**Recovery:**

1. Do NOT spawn Builder agents with the conflicting plan.
2. Record `RISK-N: ownership-conflict - [file]: claimed by [SL-XX] and [SL-YY]`.
3. Return the plan to the ProjectManager with an explicit `Must Respect` clause: "File [path] must appear in exactly one slice."
4. The ProjectManager re-runs decomposition and resubmits.
5. If the conflict persists after two attempts: the Orchestrator resolves it directly (assign the file to the slice with the highest dependency) and records `DEC-N: ownership-resolved - [rationale]`.

---

## 9. Builder Touches Forbidden Files

**Trigger:** A Builder's Agent Return lists files in `files_changed` that are not in its `files_allowed` Task Contract.

**Recovery:**

1. Mark the slice as `blocked`.
2. Record `RISK-N: scope-violation - task-[ID]: touched [forbidden files]`.
3. Assess impact:
   - If the touched file is also owned by another Builder: check whether the change conflicts with that Builder's work.
   - If not conflicting: accept the change, record `DEC-N: retroactive-scope-expansion - [rationale]`, update the ownership map.
   - If conflicting: revert the forbidden change (or create an Integrator slice to resolve it) and rerun the original Builder with a corrected Task Contract that includes an explicit `Must Respect: do not modify [file]` clause.
4. Do not re-spawn the same Builder without updating its `Must Respect` list.

---

## 10. Contract Mismatch (Cross-Slice Interface Drift)

**Trigger:** Integration check reveals that provider and consumer Builders report conflicting Contract Compliance for the same contract (e.g., provider says C-1 is compliant, consumer says C-1 is partial/blocked).

**Recovery:**

1. Record `RISK-N: contract-drift-C-[N] - [provider] reports compliant, [consumer] reports [status]: [reason]`.
2. Do NOT proceed to TESTING. Contract drift means the provider and consumer have incompatible implementations.
3. Determine which side is correct:
   - If the provider implemented to the contract spec and the consumer did not: the consumer's slice is `blocked`. Create a targeted follow-up slice for the consumer that references the contract spec explicitly in `must_respect`.
   - If the consumer implemented to the contract spec and the provider did not: the provider's slice is `blocked`. Same recovery as above but for the provider.
   - If the contract spec itself was ambiguous: record `DEC-N: contract-clarified-C-[N] - [clarification]`. Update the contract spec. Both provider and consumer may need follow-up slices.
4. If the drift affects other slices (e.g., a shared type used by 3 slices), assess whether all consumers need correction.
5. After correction, re-run Integration Check with contract compliance cross-check.

---

## 10-b. Builder Escalates Contract Issue Mid-Build

**Trigger:** During BUILDING, a Builder discovers that a Contract Spec is wrong, incomplete, or impossible to implement as specified. The Builder marks the contract as `partial` or `blocked` in their Agent Return and describes the issue under `Needs Orchestrator Decision`.

This is not a bug — it is expected behavior in brownfield projects where PM can only read interface-layer code, not implementation logic. The probability is non-trivial: hidden constraints in service-layer code, undocumented side effects, or library version incompatibilities may only surface when a Builder actually writes code.

**Why this can't be fixed mid-build:** All Builders run in parallel. The Orchestrator cannot "pause" Builder B while Builder A's contract issue is resolved. The feedback loop is therefore **post-hoc**: collect all Builder returns, then amend the contract and create correction slices.

**Recovery:**

1. The Orchestrator collects all Builder Agent Returns. Note which contracts have `partial` or `blocked` status and the specific reasons.
2. For each affected contract, assess severity:
   - **Contract is implementable but imprecise** (e.g., missing an edge case response code): The Builder that discovered the issue likely handled it. Record `DEC-N: contract-clarified-C-[N] - [detail]`. Update the Contract Spec for future reference. No correction slice needed if both provider and consumer handled it consistently.
   - **Contract is wrong** (e.g., field type is `string` but must be `number` for the library to work): The contract must be amended. Spawn PM with the amendment request (not the full decomposition — just the one contract). PM returns the amended Contract Spec. Create a correction slice for the provider and all consumers of that contract. Mark the original slices as `partial`.
   - **Contract is impossible** (e.g., the API framework doesn't support the specified pattern): Escalate to user. Record `RISK-N: contract-blocked-C-[N] - [reason]`. The Orchestrator proposes an alternative approach based on the Builder's findings.
3. After all contract amendments are resolved, re-run the Integration Check with contract compliance cross-check on the amended contracts.
4. Record all contract amendments in the state file's `Decisions` section with rationale.
5. Update the Contract Board in the state file: changed contracts get a new row status `amended`.

**Prevention:** The more thoroughly PM executes Step 8 (Read existing interface patterns), the lower the probability of mid-build contract escalations. In greenfield projects, this probability is near zero. In brownfield projects with deep service-layer logic, it is moderate.

---

## 11. Missing Contract Spec

**Trigger:** A Builder's Task Contract references a Contract ID that has no corresponding Contract Spec in the PM Decomposition Plan, or a CSI was identified in the ownership map but no contract was produced.

**Recovery:**

1. Do NOT spawn Builder agents.
2. Return the decomposition plan to the ProjectManager with the specific missing contract IDs.
3. The ProjectManager produces the missing Contract Spec(s) and updates affected Task Contracts.
4. Re-validate before spawning Builders.

---

## 13. PM Returns a PRD Gap Report

**Trigger:** During PM_DECOMPOSITION Step 0.5, PM finds existing behaviors in the codebase that are absent from the PRD's Existing Feature Inventory.

**Recovery:**

1. Record `RISK-N: prd-coverage-gap - [feature]: found in [file], not in PRD Inventory`.
2. The Orchestrator does NOT proceed to decomposition.
3. For each gap, the Orchestrator makes a disposition decision:
   - If the gap is clearly within the scope of the user's request: add it to the PRD Inventory as `preserve`. No user re-confirmation needed if the disposition is obviously preservation.
   - If the gap's disposition is unclear: present it to the user with a recommended disposition and wait for a decision.
   - If the gap is explicitly out of scope: record `DEC-N: out-of-scope - [feature] - [rationale]` and do not add it to the Inventory.
4. Once all gaps are resolved, PM proceeds with decomposition against the updated Inventory.
5. Do not skip this step to save time — a gap caught here is 10× cheaper to fix than a regression discovered in TESTING.

---

## 14. Cross-Iteration Interface Incompatibility (PROJECT.md Conflict)

**Trigger:** During INIT, PM_DECOMPOSITION (Step 0.5), or BUILDING, a new requirement conflicts with an Active CSI Contract (XSIC-N) or Architecture Decision (PDEC-N) recorded in `.agile/PROJECT.md`. This includes: a new API endpoint that contradicts a previous API contract shape, a new data model that breaks a cross-iteration shared type, a new architecture pattern that contradicts a recorded PDEC-N, or a Builder discovering at build time that a previous-iteration interface constrains what can be implemented.

**Why this matters:** PROJECT.md represents decisions that were validated across a previous full delivery cycle. Silent deviations create the exact same class of regression that EF-N tracking prevents inside a single iteration — except they span multiple iterations and may break production consumers.

**Recovery:**

1. Record `RISK-N: cross-iteration-conflict-[XSIC-N or PDEC-N] - [new requirement]: conflicts with [existing contract/decision] defined in [source iteration]`.
2. **Do NOT proceed** past the current phase. Do not ask Builders to work around the conflict silently.
3. The Orchestrator presents the conflict to the user:
   ```
   Cross-iteration conflict detected.

   Existing constraint: XSIC-1 — POST /api/v1/users expects {username, email} → {id, token}
   Source: iter-20260508-01
   New requirement: POST /api/v1/users must now accept {username, email, phone}

   Options:
   A) Amend XSIC-1 to include the `phone` field (backward-compatible addition — low risk)
   B) Version the API: create v2 endpoint, keep v1 unchanged (higher effort, no consumers broken)
   C) Constrain the new requirement to avoid this field (simplest, if acceptable)
   ```
4. Wait for user decision before proceeding.
5. Once resolved, record `DEC-N: cross-iteration-amendment - [XSIC-N or PDEC-N]: [decision and rationale]` in the state file.
6. Update `.agile/PROJECT.md`: amend the XSIC-N or PDEC-N row to reflect the new agreed shape. Note the amendment's iteration and reason.
7. Pass the amended contract as the authoritative Contract Spec to the PM (if in PM_DECOMPOSITION) or the affected Builders (if in BUILDING) via a targeted follow-up slice.

**Prevention:** The Orchestrator's Step 0 at INIT reads PROJECT.md and injects Active CSI Contracts into the delivery brief. The ProductOwner includes them in Technical Constraints. The PM treats XSIC-N contracts as pre-existing Contract Specs. This chain means most conflicts surface at INIT or PM_DECOMPOSITION, before any code is written.

---

## 12. Tester Detects Contract Violation

**Trigger:** A Tester's contract verification (actual API requests, type checks, schema introspection) reveals that the implementation does not match the contract spec, even though the Builder reported `compliant`.

**Recovery:**

1. Record `RISK-N: contract-violation-C-[N] - [Tester] detected [violation]: [evidence]`.
2. Mark the contract status in the Contract Board as `drift`.
3. The violating slice is `blocked`. The fix is a new iteration slice, not part of the current Tester's scope.
4. If the violation is in the provider's implementation: the provider slice must be corrected. All consumers should be checked for cascading impact.
5. Do not lower the bar — if a Builder incorrectly reported `compliant`, the contract must be re-verified after the fix.
