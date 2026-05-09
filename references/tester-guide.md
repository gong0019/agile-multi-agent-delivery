# Tester Guide

This guide defines how the **Tester** agent executes the TESTING phase. The Tester is not a test-runner that verifies a checklist — it is a quality engineer that actively discovers problems the pipeline may have missed.

A Tester that only confirms "AC-1 passes, AC-2 passes" is not testing. It is auditing. These are different jobs.

Companion reference: `references/csi-guide.md` — contract verification methods for each CSI type.

---

## Role Mindset

The Tester's job is to answer one question: **"Can I find a reason why this should not ship?"**

That requires:
- Running specified tests (confirmatory)
- Reasoning about code that was not tested (analytical)
- Tracing data flows across layers (investigative)
- Trying paths the implementer did not plan for (exploratory)

A Tester that cannot do all four is not replacing a human QA engineer — it is replacing a CI bot.

---

## The 7 Testing Dimensions

Execute all 7 dimensions for every assigned slice. Skip a dimension only when it is structurally inapplicable (e.g., skip UX Quality for a pure backend slice) — and record the skip reason in the Agent Return.

---

### Dimension 1: Impact Radius Analysis

**Before writing or running any tests**, identify everything that could be affected by the changes in this slice — not just what was changed, but what depends on what was changed.

**Steps:**

1. For each file changed in this slice, identify its **outbound references**: what does it import from other modules?
2. For each changed function/class/export, identify its **inbound references**: what other files import or call it?
3. Build an impact map:

```
Changed: src/settings/layout.tsx
  → exports: SettingsLayout (component)
  → imported by: src/pages/settings.tsx, src/pages/admin/settings.tsx
  → implication: both pages must render correctly with the new layout

Changed: src/utils/groupBy.ts (utility function signature changed)
  → imported by: src/settings/layout.tsx, src/dashboard/widgets.tsx
  → implication: dashboard/widgets.tsx may break even though it wasn't in scope
```

4. For every item in the impact map that is **outside the slice's files_allowed**: perform a smoke verification (does it still render/run without error?).
5. Report any impact-radius item that fails as `RISK-N: impact-radius-[file]: [description]`.

**Why this matters:** Builders have disjoint file ownership. A Builder modifies `src/utils/groupBy.ts` but cannot see that `src/dashboard/widgets.tsx` depends on it. The Tester's read-only access to all source files makes it uniquely positioned to catch this.

---

### Dimension 2: Full Regression Sweep

Run the project's full test suite, not just tests for the assigned slices.

**Steps:**

1. Run the full test command (e.g., `npm test`, `pytest`, `go test ./...`).
2. Record: total tests, passed, failed, skipped.
3. Identify any failure in a test **outside the assigned slices** — these are unexpected regressions.
4. For each unexpected regression: trace whether it was caused by a change in this iteration's slices.
5. Report as `RISK-N: unexpected-regression - [test name]: [root cause if identified]`.

If the project has no test suite: record `RISK-N: no-test-suite` and increase depth of Dimensions 3–5.

**Smoke test of adjacent features** (brownfield only):

Beyond the test suite, manually verify 2–3 key user flows in features adjacent to the changed area. Record what was checked and the result. A smoke test does not need to be exhaustive — it needs to confirm the surface still works.

---

### Dimension 3: Logic Consistency Check

Verify that the new or modified feature is internally self-consistent — not just that individual ACs pass, but that the feature works coherently across all states, paths, and edge cases.

**Checklist:**

- **State reachability**: can every documented state of the feature be reached through normal user actions? (e.g., if a grouped view has an "empty group" state, can you actually reach it? What does it show?)
- **Operation closure**: for every action the user can take (create, edit, delete, sort, filter), does it work in every context the feature supports? (e.g., if items can be edited, can they be edited in every group, not just the first one?)
- **AC mutual consistency**: do the acceptance criteria contradict each other? (e.g., AC-1 says "groups are collapsible" but AC-3 says "all items always visible" — these cannot both be true)
- **Error path coverage**: what happens when an operation fails (network error, validation error, permission denied)? Is the error state handled, or does the UI silently break?
- **Boundary values**: empty list, single item, maximum items, special characters in inputs, very long strings.

For each gap found: `RISK-N: logic-gap - [description of unhandled state or path]`.

---

### Dimension 4: Contextual Coherence Analysis

Verify that the changes integrate correctly into their surrounding codebase context — that the implementation fits, not just works.

This is a **static analysis + code review** step, not a test execution step.

**What to check:**

#### Code Pattern Consistency
- Does the changed code follow the same patterns as neighboring code in the same file? (naming conventions, error handling approach, return type conventions)
- If a new function was added, does its signature style match the other functions in the module?
- If a component was added, does its prop interface style match other components?

#### Implicit Contract with Callers
- For every function/export that was changed: read its callers (from the impact map in Dimension 1).
- Do the callers' assumptions still hold? (e.g., caller assumes the function returns `null` on failure, but the change now throws an exception instead)
- Are there any callers that pass arguments in ways the new implementation no longer supports?

#### State and Side Effect Coherence
- If state management was changed (Redux store, React context, Vuex, etc.): do all components that read that state still get the shape they expect?
- If a side effect was added or removed (event listeners, timers, subscriptions): are there corresponding cleanup paths?

#### Import and Dependency Coherence
- Did the change introduce new dependencies? Are they already in the project's dependency manifest?
- Did the change remove code that other files still import?

Report findings as `RISK-N: coherence-[type] - [description]`.

---

### Dimension 5: Frontend–Backend Data Flow Verification

**Applies when the iteration includes both frontend and backend slices, or when a frontend slice calls an existing backend API.**

This dimension verifies that the frontend's implementation correctly realizes the PRD's business intent — not just that the interface contract is satisfied, but that the full data flow from user action to backend response to UI update is correct.

The CSI contract system ensures provider and consumer agreed on a spec. This dimension verifies the frontend **correctly uses** that spec to implement the intended behavior.

**Steps:**

#### Step A: Parameter Correctness Trace

For each API call made by the frontend slice:

1. Identify the frontend code that constructs the request (the `fetch`/`axios`/`http` call).
2. Read what parameters it sends (field names, types, values).
3. Cross-check against the Contract Spec (C-N) for that endpoint.
4. Verify: correct HTTP method, correct path, correct Content-Type, all required fields present, field names match exactly (case-sensitive), field types match.

Common failures to look for:
- `username` sent as `userName` or `user_name`
- Missing required field (silently omitted because it was added to the API contract after the frontend was written)
- Extra fields sent that the API ignores but shouldn't be there
- Wrong HTTP method (POST vs PUT vs PATCH)

#### Step B: Response Handling Trace

For each API response consumed by the frontend slice:

1. Identify the response handling code (`.then()`, `await`, destructuring).
2. Read what fields it reads from the response.
3. Cross-check against the Contract Spec response schema.
4. Verify: correct field paths accessed, correct status codes used for branching, correct error field read for error display.

Common failures to look for:
- `response.data.user.id` when API returns `response.user.id`
- Treating `200` as always success when API returns `201` for creation
- Reading `error.message` when API returns `error.detail`
- Not handling a documented error status code (e.g., 409 Conflict falls through to a generic error handler)

#### Step C: Business Intent Alignment

Read the PRD's functional requirements and user stories. Then trace the complete user flow for each:

```
User action → event handler → state update → API call → response → state update → UI re-render
```

Verify that this full chain implements what the PRD intended, not just what each individual piece technically does.

Questions to ask:
- Does the user flow match the PRD's user story? (e.g., "User submits form → sees confirmation" — does the code actually show a confirmation, or does it just navigate away?)
- Is the data the user sees after the action the data the PRD says they should see?
- Are there steps in the PRD flow that the implementation skips? (e.g., PRD says "preview → confirm → submit" but implementation goes directly to "submit")
- Does the frontend enforce the same business rules as the backend? (e.g., PRD says field is required — does frontend validate it before sending, or rely entirely on backend error?)

Report deviations as `RISK-N: intent-deviation - [PRD reference]: [actual vs intended behavior]`.

---

### Dimension 6: UX Quality Review

**Applies to slices that include UI files (pages, components, views, templates).**

This is a qualitative review, not a test execution. The Tester reads the frontend code and reasons about the user experience it produces.

**Checklist:**

#### State Coverage
- **Empty state**: when there is no data, what does the UI show? (blank screen? helpful message? skeleton? error?) Is it clear to the user what to do?
- **Loading state**: when data is being fetched, does the UI indicate progress? Or does it appear frozen?
- **Error state**: when an operation fails, does the UI show a clear, actionable error message? Or does it silently fail?
- **Success state**: when an operation succeeds, does the UI provide clear feedback?

#### Interaction Quality
- Are interactive elements (buttons, inputs, dropdowns) reachable by keyboard?
- Do destructive actions (delete, clear, reset) have a confirmation step?
- Is there visual feedback when a user triggers an action (button press, form submit)?
- Are form validation messages shown inline (near the field) or only after submit?

#### Visual Consistency
- Does the new UI use the same CSS framework, component library, and design tokens as the rest of the project? (Reference: the Design Constraints block from the Builder's Task Contract)
- Are spacing, typography, and color usage consistent with adjacent pages?
- Does the layout work at the breakpoints the project supports (mobile, tablet, desktop)?

#### Accessibility Basics
- Do interactive elements have accessible labels (aria-label, title, or visible text)?
- Is focus order logical (tab through the page in a sensible sequence)?
- Are color-only indicators accompanied by text or icons?

Report UX issues as `RISK-N: ux-[category] - [description]`. Severity:
- `critical`: user cannot complete the core action
- `high`: user is likely to be confused or make errors
- `medium`: friction or inconsistency that degrades experience
- `low`: polish issue, no functional impact

---

### Dimension 7: Exploratory Testing

Run a time-boxed exploratory session targeting paths and states the implementation did not plan for.

**Protocol:**

1. Set a scope: the feature(s) changed in the assigned slices.
2. Run for a defined session length: short (10 min equivalent) for small slices, medium (20 min equivalent) for larger ones.
3. Focus exploration on:
   - **Boundary inputs**: empty string, very long string, special characters (`<script>`, SQL-like strings, unicode), zero, negative numbers, maximum values
   - **Unexpected sequences**: do actions out of the expected order (delete before save, navigate away mid-form, submit twice quickly)
   - **Permission edge cases**: what happens if the user lacks a required permission mid-flow?
   - **Concurrent state**: what if data changes on the server while the user is editing locally?
   - **Interruption recovery**: navigate away and back — does state persist correctly or reset unexpectedly?

4. Document findings as `RISK-N: exploratory - [path taken]: [what happened]`.

Exploratory testing does not need to be exhaustive. The goal is to find **one class of problem the spec did not anticipate** per session. If none found: record "exploratory session completed, no unspecified failures found."

---

## Agent Return Format for Testers

```md
## Agent Return
- Task ID: [TASK-N]
- Status: done / partial / blocked
- Slices Covered: [SL-XX, SL-YY]

### Dimension Results

| Dimension | Status | Key Findings |
|-----------|--------|--------------|
| 1. Impact Radius | pass / risk | [summary or "none found"] |
| 2. Regression Sweep | pass / risk | [N tests, M unexpected failures] |
| 3. Logic Consistency | pass / risk | [summary] |
| 4. Contextual Coherence | pass / risk | [summary] |
| 5. Frontend–Backend Flow | pass / risk / N/A | [summary] |
| 6. UX Quality | pass / risk / N/A | [summary] |
| 7. Exploratory | pass / risk | [summary] |

### AC-N Results
| Criterion | Status | Evidence |
|-----------|--------|----------|
| AC-1 | met / failed / untestable | [one line] |
| RAC-1 | met / failed / untestable | [one line] |

### Contract Verification
| Contract ID | Method | Result |
|-------------|--------|--------|
| C-1 | actual request | compliant / drift |

### Risks
- RISK-N: [type] - [description] (severity: critical / high / medium / low)

### Skipped Dimensions
- Dimension 6 (UX): N/A — no UI files in assigned slices

### Validation Performed
- [list of commands run, test suites executed, files reviewed]
```

---

## What Testers Do NOT Do

- Do not fix bugs — record as RISK-N and stop. Fixes are new iteration slices.
- Do not modify source files — read-only access to source, write access to test files only.
- Do not re-implement functionality — if a behavior is missing, report it, do not add it.
- Do not skip a dimension without recording the reason.
- Do not report "pass" for a dimension that was not executed.
