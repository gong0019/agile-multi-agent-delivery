# Project Constitution Guide

The Project Constitution defines the inviolable engineering principles, technology constraints, and quality mandates for a specific project. Every agent in the agile-multi-agent-delivery pipeline reads the constitution at INIT and respects its rules throughout the delivery — without exception, without feature-by-feature re-negotiation.

## What a Constitution Is (and Is Not)

A constitution is **not** a PRD, not a CLAUDE.md, and not a coding style guide.

It is a short document of principles that answer one question: **"What makes this project non-negotiable?"**

| Belongs in Constitution | Does NOT Belong in Constitution |
|---|---|
| "All API responses must use the standard envelope `{data, error, meta}`" | Specific feature requirements |
| "No implementation before failing tests" | Tool permission settings |
| "No new npm dependencies without tech lead approval" | PR templates or git workflows |
| "All DB timestamps must be `timestamptz`, never `timestamp`" | Code style rules (use a linter for that) |
| "Frontend uses Tailwind CSS only — no inline styles, no CSS Modules" | Sprint planning or velocity metrics |
| "All user-facing errors must have a user-readable message and an error code" | Architecture diagrams |

If a rule needs to be re-evaluated per feature, it is not a constitution rule. Constitution rules are the ones you would enforce even if a PM asked you to skip them just this once.

---

## Constitution File Location

The Orchestrator checks in this order:

1. `.agile/constitution.md` — project-specific, team-maintained, committed to git
2. `CONSTITUTION.md` — project root, visible to all contributors

If neither exists: proceed without one. No constitution is valid — it means the team has not yet defined its non-negotiables. The Orchestrator may recommend creating one.

---

## Constitution Template

```markdown
# [Project Name] — Project Constitution

> These rules apply to every feature, every iteration, every agent.
> They are not re-negotiated per PRD. Violations must be escalated, not silently skipped.

## Article I: API Conventions

- All HTTP responses use the standard envelope:
  `{ "data": T | null, "error": { "message": string, "code": string } | null }`
- Error codes are SCREAMING_SNAKE_CASE strings, never numeric
- All endpoints require authentication unless explicitly listed in the public-routes registry
- Pagination uses `{ "data": T[], "meta": { "total": number, "page": number, "per_page": number } }`

## Article II: Data Layer

- All timestamps are `timestamptz` (UTC) — never `timestamp` without timezone
- Table names are plural snake_case
- Foreign keys are `{singular_table_name}_id`
- Soft deletes use `deleted_at timestamptz` — never hard-delete user data
- All migrations are additive — no column drops, no type changes without a migration plan

## Article III: Testing Mandate

- No implementation code before failing tests (TDD)
- No mocks for database access — use the test database
- Integration tests must run against real service instances, not stubs
- Test coverage must not decrease below [N]% on any PR

## Article IV: Frontend Conventions

- CSS: Tailwind CSS v3 only — no inline styles, no CSS Modules, no styled-components
- Component library: [name] — do not introduce alternatives
- All user-facing error messages must be human-readable (not "Error 500") and actionable
- All forms must handle loading, error, and success states explicitly

## Article V: Dependency Policy

- No new npm/pip/go dependencies without tech lead approval
- Approved dependencies must be pinned to an exact version
- Security audit required before adding any dependency with network access

## Article VI: Prohibited Patterns

- No `console.log` / `print` in production code paths
- No hardcoded secrets or credentials — use environment variables
- No `any` type in TypeScript except in explicitly annotated escape hatches
- No `eval()` or equivalent dynamic code execution
```

---

## How to Write Your Constitution

**Keep it short.** A constitution that cannot be read in 5 minutes will not be followed. Aim for 6–10 articles, each with 3–6 rules.

**Make rules verifiable.** "Write good code" is not a constitution rule. "No `any` type in TypeScript except in annotated escape hatches" is.

**Escalate, don't skip.** Every rule should include an implicit "if you cannot comply with this rule in your slice, escalate to the Orchestrator — do not silently violate it."

**Version it.** Include a version and a date so teams can see when principles changed.

---

## How the Constitution Affects the Pipeline

| Phase | Effect |
|---|---|
| **INIT** | Orchestrator reads constitution; records it in the delivery brief under "Constitution Rules" |
| **REQUIREMENTS_DRAFTING** | PO includes constitution rules as implicit Technical Constraints in the PRD |
| **PM_DECOMPOSITION** | PM includes all constitution rules in every Builder Task Contract's `must_respect` |
| **BUILDING** | Builders must comply with constitution rules in addition to Task Contract scope |
| **INTEGRATION_CHECK** | Orchestrator checks Agent Returns for any reported constitution violations |
| **TESTING** | Dimension 4 (Contextual Coherence) explicitly checks constitution compliance |

---

## Constitution Violation Protocol

When a Builder discovers that a constitution rule cannot be respected in its slice:

1. Do NOT silently violate the rule.
2. Record under `Needs Orchestrator Decision`: "Constitution Article [N] requires [rule], but [reason it cannot be followed]. Proposed resolution: [option A] or [option B]."
3. The Orchestrator decides: grant a one-time exception (recorded as DEC-N with rationale) or require a different approach.

A recorded exception is not a violation. A silent skip is.
