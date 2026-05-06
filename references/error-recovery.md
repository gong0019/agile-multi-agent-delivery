# Error Recovery Procedures

This document defines how the agile multi-agent delivery skill handles common failure modes. The delivery lead should reference these procedures when a problem occurs rather than improvising.

## 1. User Rejects the Delivery Brief

**Trigger:** The user does not approve the brief presented in the confirmation gate.

**Recovery:**

1. Record the rejection reason in `current-iteration.md` under `Risks And Blockers` as `RISK-N: brief-rejected - [reason]`.
2. Ask targeted questions to clarify the specific objection (scope, approach, timeline, or assumptions).
3. Rewrite the brief with the corrected information.
4. Do not bump `iteration_version` for a brief revision — only bump when a confirmed request materially changes after work has begun.
5. Present the revised brief for confirmation.

**If the user keeps rejecting:** After two rejections, pause and ask whether the request should be split into smaller iterations or deferred.

## 2. State File Corruption or Format Error

**Trigger:** `scripts/validate-state.sh` reports the state file is invalid, or the frontmatter is missing/malformed.

**Recovery:**

1. Check `git log` for the last known-good version: `git log --oneline current-iteration.md`
2. If a good version exists in git history: `git checkout HEAD~1 -- current-iteration.md`
3. If no good version exists, rebuild from `references/iteration-state-template.md`:
   - Run `scripts/init-state.sh`
   - Manually re-fill fields from the Markdown body (which is not lost even if frontmatter is broken)
4. Bump `iteration_version` and record `DEC-N: state-rebuilt - [reason]` in the decisions section.

## 3. Sub-Agent Returns Incomplete or Invalid Results

**Trigger:** A builder or reviewer agent returns partial work, fails to report changed files, or introduces errors outside its allowed scope.

**Recovery:**

1. Record the issue under `Risks And Blockers`: `RISK-N: task-[ID]-incomplete - [description]`.
2. If the result is partially usable: integrate the valid portions and mark the slice as `in_progress` rather than `done`.
3. Do not re-delegate the same task to another agent without changing the contract — add a `Must Respect` clause referencing the previous attempt's failure.
4. If the task is on the critical path: the delivery lead completes it locally rather than delegating again.
5. If the task is non-critical: defer it and record under `Next Steps`.

## 4. Concurrent Iteration Conflict

**Trigger:** Two threads or sessions attempt to update the same `current-iteration.md` simultaneously.

**Recovery:**

1. The iteration file should always be under git version control.
2. Before starting work, run `git status` to check for uncommitted changes to `current-iteration.md`.
3. If changes exist from another session: read the file, merge the relevant updates, and bump `iteration_version`.
4. Record `DEC-N: concurrent-merge - [summary]` in decisions.
5. If the conflict involves incompatible scope changes, ask the user which direction to take.

## 5. Context Loss After `/clear` or New Thread

**Trigger:** A new thread starts and the previous conversation history is unavailable.

**Recovery:**

1. The user (or new agent) should run: `cat current-iteration.md`
2. The `next_resume_prompt` field in the frontmatter contains the exact instruction to continue.
3. If `next_resume_prompt` is empty or missing:
   - Read the `Slice Board` to find the first non-`done` slice.
   - Read the `Decisions` and `Risks And Blockers` sections.
   - Construct a resume prompt: `Continue from SL-XX [summary]. Respect DEC-N and RISK-N.`
4. Validate the state file with `scripts/check-constraints.sh` before resuming work.

## 6. State Drift (Markdown Body vs Frontmatter Disagreement)

**Trigger:** The YAML frontmatter says `overall_completion: "100%"` but the slice board shows `todo` items.

**Recovery:**

1. Run `scripts/check-constraints.sh` — it checks for this inconsistency.
2. Trust the slice board over the percentage. The percentage is a summary; the board is the detail.
3. Recalculate `overall_completion` based on slice status: `done_count / total_count * 100`.
4. Update both the frontmatter and the Markdown body to match.
5. Do not bump `iteration_version` for a consistency fix unless the scope itself changed.
