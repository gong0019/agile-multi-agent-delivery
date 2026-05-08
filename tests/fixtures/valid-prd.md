---
prd_version: "2"
iteration_ref: "iter-20260506-01"
status: "confirmed"
authored_by: "product-owner"
challenged_by: "challenger"
last_updated: "2026-05-06T09:00:00Z"
challenge_rounds: 1
---

# Product Requirements Document

## Problem Statement

The API currently has no authentication. Any caller can access all endpoints. We need to add email/password registration and login with JWT session tokens so that resources can be protected by identity.

## User Stories

- `US-1` As an API consumer, I want to register with email and password so that I have an authenticated identity.
- `US-2` As an API consumer, I want to log in with my credentials and receive a JWT so that I can call protected endpoints.

## Functional Requirements

| ID | Requirement | AC Reference | Priority |
| --- | --- | --- | --- |
| FR-1 | POST /auth/register accepts email and password, returns 201 on success | AC-1 | Must |
| FR-2 | POST /auth/login accepts credentials, returns a signed JWT on success | AC-2 | Must |

## Non-Functional Requirements

- Security: passwords must be hashed with bcrypt before storage
- Performance: login endpoint p95 latency < 100ms under 100 concurrent users
- Reliability: no unhandled exceptions on invalid input

## Out of Scope

- OAuth or third-party login providers
- Password reset flow
- Refresh token rotation
- Rate limiting (tracked as RISK-1 for a future iteration)

## Technical Constraints

- Must not modify the existing `/api/v1/` route structure
- JWT secret must be read from environment variable, not hardcoded
- All new code must pass existing type checks

## Open Questions

| ID | Question | Owner | Status |
| --- | --- | --- | --- |
| Q-1 | What JWT expiry time is acceptable? | user | resolved: 24 hours |

## Challenger Objections and Resolutions

| Objection ID | Objection | ProductOwner Response | Resolution |
| --- | --- | --- | --- |
| OBJ-1 | No mention of password complexity requirements | Added: min 8 chars, no other constraint for now | accepted |
| OBJ-2 | JWT secret rotation not addressed | Deferred to future iteration, noted as RISK | deferred |

## Approval Record

- Confirmed by user: yes
- Confirmed at: 2026-05-06T09:30:00Z
- Final PRD version: 2
- Notes: Rate limiting explicitly deferred. JWT expiry set to 24h.
