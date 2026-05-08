# ProjectManager Decomposition Guide

This guide defines how the **ProjectManager** agent must decompose a confirmed PRD into Builder Task Contracts. The Orchestrator validates the output before spawning Builder agents.

## Role Constraints

The ProjectManager:

- reads the confirmed PRD and the repository file tree
- reads individual files only when necessary to estimate scope
- produces an ownership map and Task Contracts
- does NOT write any source code
- does NOT make product decisions — escalates ambiguity to the Orchestrator

## Step-by-Step Decomposition Process

### Step 1: Read the file tree first

Before opening any file, run a full directory listing. Understand the top-level module structure. Identify:

- entry points
- shared utilities and config files
- test directories
- migration or schema directories

Do not open individual files until you have the full tree.

### Step 2: Map requirements to files

For each functional requirement in the PRD, list the files likely to change. This is the **file impact map**.

Format:

```
FR-1: src/auth/register.py, src/models/user.py, tests/test_register.py
FR-2: src/auth/login.py, tests/test_login.py
```

Shared utility files (e.g. `src/utils/db.py`, `src/config.py`) should be noted separately. They require special handling (see Step 4).

### Step 3: Apply the granularity table

Count the total unique files across all requirements. Use this table to determine the number of Builder agents:

| Total estimated file changes | Builder count |
| --- | --- |
| 1–3 files | 1 |
| 4–10 files | 2–3 |
| 11–20 files | 3–4 |
| 21+ files | 4–6 |

Hard maximum: **6 Builders**. More than 6 produces coordination overhead that exceeds the parallelism benefit.

Adjust downward if:
- requirements are deeply sequential (one cannot start until another is done)
- the repository has very few distinct module boundaries

Adjust upward (within the table range) if:
- requirements are fully independent
- the repository has clean module separation

### Step 4: Group by feature boundary, not file proximity

Group files by **functional cohesion**, not by folder location. A bad grouping puts files in the same folder together even when they serve different features. A good grouping keeps one feature's data model, business logic, and tests together in one Builder slice.

Bad: "all files in `src/auth/`"
Good: "registration flow: `src/auth/register.py`, `src/models/user.py`, `tests/test_register.py`"

### Step 5: Handle shared files

Shared utility files (used by multiple features) must be owned by exactly one Builder. Other Builders must not touch them.

Assignment rule: assign the shared file to the Builder whose slice has the highest dependency on it.

If other Builders need a change in a shared file, they must:
1. Describe the needed change in their Agent Return under `Needs Orchestrator Decision`
2. The Orchestrator decides whether the owning Builder adds it or a follow-up slice is created

Never split ownership of a shared file across two Builders.

### Step 6: Assign test files

Test files follow the feature they test. If a Builder owns `src/auth/register.py`, they also own `tests/test_register.py`.

Exception: if more than 5 test files are needed across all Builders, create a dedicated **test Builder** slice that owns all test files. This Builder runs after implementation Builders complete.

### Step 7: Produce the ownership map

Output a strict ownership map. No file should appear in two slices.

Format:

```
SL-01 (builder): src/auth/register.py, src/models/user.py, tests/test_register.py
SL-02 (builder): src/auth/login.py, src/models/session.py, tests/test_login.py
SL-03 (builder): src/utils/db.py  [shared file, owned here]
```

### Step 8: Self-validate before returning

Before returning the decomposition plan to the Orchestrator:

1. List every file from the impact map
2. Confirm each appears in exactly one slice
3. If any file appears in two slices: resolve the conflict, then re-check
4. If any file is missing: assign it to the most appropriate slice

Report any files you could not assign under `Needs Orchestrator Decision`.

## Task Contract Requirements

Each Builder Task Contract must include:

- `task_id`: `TASK-N`
- `round_version`: `v1`
- `phase`: `BUILDING`
- `agent_role`: `builder`
- `parallel_group`: same tag for all Builders in this batch (e.g. `build-round-1`)
- `objective`: one sentence
- `in_scope`: flat list of allowed work
- `out_of_scope`: at minimum includes all files owned by other Builders
- `files_allowed`: exact list of owned files
- `files_avoid`: all shared files not owned by this Builder
- `must_respect`: reference any API contracts, migration constraints, or coding standards
- `expected_deliverable`: Agent Return with changed files, verification notes, and risks
- `stop_when`: "all files in `files_allowed` are implemented and verified"
- `escalate_if`: "any required change falls outside `files_allowed`"

## Tester Count Formula

After Builders are defined:

```
tester_count = max(1, ceil(builder_count / 2))
```

Each Tester covers 2 Builders' output. Assign Testers to Builder pairs by feature proximity.

## Output Format

Return to the Orchestrator in this format:

```
## PM Decomposition Plan

- Total files estimated: N
- Builder count: N
- Tester count: N

### Ownership Map
SL-01 (builder): [files]
SL-02 (builder): [files]
...

### Task Contracts
[one Task Contract block per Builder]

### Shared Files
[file]: owned by SL-XX, needed by SL-YY (change described in SL-YY's escalate_if)

### Needs Orchestrator Decision
[any unresolved assignments or product ambiguities]
```
