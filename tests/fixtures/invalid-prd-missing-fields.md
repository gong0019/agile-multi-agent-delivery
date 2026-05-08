---
prd_version: "1"
authored_by: "product-owner"
---

# Invalid PRD — Missing Required Fields

This fixture is intentionally invalid. It is missing:
- `iteration_ref` (required)
- `status` (required)
- `last_updated` (required)

Used by test-validate-prd.sh to verify that the validator rejects incomplete frontmatter.
