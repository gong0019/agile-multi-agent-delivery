# ProjectManager Decomposition Guide

This guide defines how the **ProjectManager** agent must decompose a confirmed PRD into Builder Task Contracts. The Orchestrator validates the output before spawning Builder agents.

Companion reference: `references/csi-guide.md` — defines how to identify and specify Cross-Slice Interfaces.

## Role Constraints

The ProjectManager:

- reads the confirmed PRD and the repository file tree
- reads individual files only when necessary to estimate scope
- produces an ownership map, Task Contracts, and Contract Specs for all cross-slice interfaces
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

### Step 8: Read existing interface patterns (brownfield projects)

**Skip this step only for greenfield projects with zero existing code.**

Before writing Contract Specs, read the existing interface surface to understand the project's conventions. A Contract Spec that violates existing patterns is itself a source of inconsistency — even if both Builders follow it perfectly, the overall codebase will be incoherent.

**Files PM must read (and only these):**

| Must Read | Why | What to Extract |
|-----------|-----|-----------------|
| Route/handler files that overlap with the impact map | Understand existing API style | Method+path conventions, parameter naming style, response envelope shape, error response format, auth header expectations |
| Type/interface/model files referenced by the impact map | Understand existing type conventions | Naming style, field optionality patterns, enum patterns, whether types use classes or plain objects |
| Schema/migration files referenced by the impact map | Understand existing DB conventions | Table naming (plural/singular), column naming (snake_case/camelCase), constraint naming, migration ordering conventions |
| Middleware/auth files referenced by the impact map | Understand existing behavioral conventions | Token claim names, header names, error response shape for 401/403, session vs JWT pattern |
| Package/dependency manifest (`package.json`, `go.mod`, `Cargo.toml`, `requirements.txt`) | Understand existing library constraints | Which framework version, which component library, which CSS solution |

**Files PM must NOT read:**
- Service/business-logic files — interface shape, not implementation, is what matters
- Utility/helper files — irrelevant to contract design
- Unrelated route/handler files — only those touching the impact map
- Test files — existing tests don't define interfaces

**What to record:**

After reading the interface surface, produce an **Interface Conventions Summary** before writing any Contract Specs:

```
## Interface Conventions (from existing code)

API style:
  - RESTful, path prefix: /api/v1/
  - Response envelope: { data: T, error?: { message: string, code: string } }
  - List responses: { data: T[], meta: { total: number, page: number } }
  - Auth header: Authorization: Bearer <JWT>
  - Error status codes: 400 validation, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict

Type conventions:
  - camelCase field names
  - Dates as ISO 8601 strings
  - Enums as string unions, not numeric

DB conventions:
  - snake_case table and column names
  - Plural table names
  - timestamptz for all timestamps
  - Foreign keys: {table}_id

Design system (if frontend):
  - CSS: Tailwind CSS v3
  - Component library: shadcn/ui (Radix primitives)
  - Icons: lucide-react
  - Reference page for style: src/pages/dashboard/index.tsx
```

If the project has no existing interface surface (truly greenfield), skip this step and set conventions in the Contract Specs themselves — but make them explicit, not implicit.

### Step 9: Identify Cross-Slice Interfaces (CSIs)

After the ownership map is complete, identify every interface boundary where two or more slices must interoperate. A CSI exists whenever a slice **produces** something another slice **consumes**.

Use the identification heuristics in `references/csi-guide.md`:

1. **Import reference analysis**: For each file in the impact map, check whether it imports from a file owned by a different slice. Every such import chain is a CSI.
2. **PRD keyword scan**: Scan the PRD for interface keywords (API, endpoint, event, message, schema, migration, type, auth, config) and map each to the affected slices.
3. **Shared directory heuristic**: Check whether directories like `types/`, `routes/`, `migrations/`, `events/`, `middleware/` span multiple slices.
4. **Cross-slice data flow**: Trace which slice creates data and which slice reads it. If different, a CSI exists at the data boundary.

List every identified CSI:

```
CSI-1: api-rest — SL-01 (provider) → SL-02 (consumer) — POST /api/v1/users
CSI-2: shared-type — SL-01 (provider) → SL-02, SL-03 (consumers) — User interface
CSI-3: db-schema — SL-01 (provider) → SL-02 (consumer) — users table
```

### Step 10: Produce Contract Specs for Every CSI

For each CSI identified in Step 8, produce a precise Contract Spec. Use the type-specific templates in `references/csi-guide.md`.

Each Contract Spec must be self-contained and precise enough that two independent Builders who only read the contract spec (and not each other's code) will produce compatible implementations.

Minimum precision requirements:
- **api-***: method, path, request body schema (every field with type and required/optional), response body schema for every status code, error response format
- **shared-type**: the exact type definition in the target language, not a prose description
- **db-schema**: every column with type, nullability, defaults, constraints; every index; migration file ownership
- **event**: topic/queue name, payload schema (every field), serialization format, partitioning key
- **behavioral**: token claims, header format, error response shape for every failure mode
- **operational**: every env var with type, default, and allowed values; every feature flag

If a CSI spans slices where you cannot determine the exact spec (e.g., the PRD is silent on error codes), record it under `Needs Orchestrator Decision` with a proposed default.

### Step 11: Self-validate before returning

Before returning the decomposition plan to the Orchestrator:

1. List every file from the impact map
2. Confirm each appears in exactly one slice
3. If any file appears in two slices: resolve the conflict, then re-check
4. If any file is missing: assign it to the most appropriate slice
5. Confirm every CSI has a Contract Spec and every bound Builder's Task Contract references it
6. Confirm no Builder has a `must_respect` reference to an undefined contract ID

Report any files you could not assign or contracts you could not specify under `Needs Orchestrator Decision`.

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
- `contracts`: list of Contract IDs this Builder must comply with (provider or consumer). Each entry references a Contract Spec produced in Step 9. Leave empty only if this slice has zero cross-slice interfaces.
- `must_respect`: reference any API contracts (by Contract ID), migration constraints, or coding standards
- `expected_deliverable`: Agent Return with changed files, verification notes, risks, and Contract Compliance table
- `stop_when`: "all files in `files_allowed` are implemented and verified"
- `escalate_if`: "any required change falls outside `files_allowed`"

## Frontend Design Constraints

When any Builder slice includes UI files (pages, components, views, templates, stylesheets), the Task Contract must include design constraints. A frontend Builder with no design constraints defaults to minimal, unstyled output that is inconsistent with the project.

### Design Context Discovery (during Step 8)

While reading the interface surface, if the project has UI code, also identify:

- **CSS framework**: Tailwind CSS, CSS Modules, styled-components, vanilla CSS, etc.
- **Component library**: Ant Design, Material UI, shadcn/ui, Bootstrap, or none
- **Icon library**: lucide-react, heroicons, @ant-design/icons, fontawesome, etc.
- **Reference pages**: 2-3 existing pages that exemplify the project's visual style
- **Layout pattern**: how pages are structured (sidebar+content, full-width, card-based, etc.)
- **Design tokens**: primary color, border radius, spacing scale, font family — extract from existing code, not memory

### Design Constraint Block (in Task Contract)

Every frontend Task Contract must include:

```
Design Constraints:
  - CSS: [framework and version]
  - Component library: [name and version]
  - Icons: [icon library]
  - Reference pages: [2-3 file paths to existing pages that model the desired style]
  - Layout: [page layout pattern]
  - Design tokens:
    - Primary: [color hex]
    - Border radius: [value]
    - Spacing: [scale]
    - Font: [family]
  - Must NOT: use inline styles, introduce new CSS frameworks, use emoji as icons
```

### Greenfield (no existing UI)

If the project has no existing UI code, PM must still set design constraints rather than leaving them blank. Default to a modern, clean style:

```
Design Constraints (greenfield):
  - CSS: Tailwind CSS v3
  - Component library: none (use Tailwind-styled native elements)
  - Icons: lucide-react
  - Layout: max-w-7xl mx-auto, responsive padding
  - Design tokens:
    - Primary: #2563eb (blue-600)
    - Border radius: 0.5rem (rounded-lg)
    - Spacing: Tailwind default scale
    - Font: system font stack (font-sans)
  - Must NOT: use Times New Roman, use excessive gradients, use emoji as icons, use inline styles
```

### Rationale

This is not cosmetic. A Builder that styles a page inconsistently creates real downstream cost: someone must rewrite the CSS later, the user sees a disjointed interface, and the inconsistency itself becomes a bug report. Design constraints in the Task Contract prevent this just as Contract Specs prevent API drift.

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
- Total CSIs identified: N

### Interface Conventions (brownfield only)
[API style, type conventions, DB conventions, design system — from Step 8]

### Ownership Map
SL-01 (builder): [files]
SL-02 (builder): [files]
...

### Contract Specs
C-1 (api-rest, provider: SL-01, consumers: [SL-02]):
  [full contract spec per csi-guide.md templates]
C-2 (shared-type, provider: SL-01, consumers: [SL-02, SL-03]):
  [full contract spec]

### Task Contracts
[one Task Contract block per Builder, each listing its bound contract IDs]
[frontend slices include Design Constraints block]

### Shared Files
[file]: owned by SL-XX, needed by SL-YY (change described in SL-YY's escalate_if)

### Needs Orchestrator Decision
[any unresolved assignments, contract ambiguities, or product decisions]
```
