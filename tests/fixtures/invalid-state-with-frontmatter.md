---
skill_version: "1.0.0"
product_version: "invalid"
iteration_version: "not-a-date"
overall_completion: "50%"
current_slice_completion: "100%"
last_updated: "2026-05-06T10:00:00Z"
active_objective: "Missing acceptance criteria"
acceptance_criteria: []
slice_board: []
next_resume_prompt: ""
---

# Invalid State

This file has a frontmatter but with intentionally bad values:
- product_version doesn't match v*.*.* pattern
- iteration_version doesn't match iter-YYYYMMDD-N pattern
- acceptance_criteria is empty (minItems: 1)
- slice_board is empty (minItems: 1)
- next_resume_prompt is empty (minLength: 1)
