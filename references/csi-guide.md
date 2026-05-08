# Cross-Slice Interface (CSI) Guide

This guide defines how the **ProjectManager** identifies cross-slice interfaces during decomposition and produces precise Contract Specs that bind Builder agents to a shared specification.

## What is a CSI

A Cross-Slice Interface is any boundary where two or more independently-built slices must interoperate. When PM decomposes work into parallel Builder slices, any interaction point between those slices is a CSI. Without a shared, precise spec for each CSI, Builders independently interpret the PRD and produce incompatible implementations.

**Core rule**: Every CSI must have a Contract Spec before any Builder starts. No Builder receives a Task Contract that references an undefined contract.

---

## CSI Type Catalog

### P0 — Must Identify Every Time

#### 1. API Contract (`api-rest`, `api-rpc`, `api-graphql`)

Any HTTP/RPC/GraphQL endpoint where one slice is the provider (server) and another is the consumer (client/frontend).

**Triggers**:
- PRD mentions "API", "endpoint", "接口", "route", "handler", "controller", "fetch", "request"
- Two slices have an import chain where one defines a route handler and another calls it
- Files in `routes/`, `handlers/`, `controllers/`, `api/` are in one slice and files with `fetch`/`axios`/`http` calls are in another

**Inconsistency symptoms**: method/path mismatch, field name/type divergence, missing required fields, different error response format, different auth header expectations.

#### 2. Shared Type Contract (`shared-type`)

Any type, interface, enum, or constant definition that is consumed by two or more slices.

**Triggers**:
- A file in `types/`, `interfaces/`, `models/`, `proto/`, `schemas/` exists and is referenced by files in different slices
- PRD mentions the same data entity (e.g. "User", "Order") in multiple functional requirements that map to different slices

**Inconsistency symptoms**: same type name with different fields across files, enum values diverge, optionality differs.

#### 3. Data Schema Contract (`db-schema`)

Any database table, collection, index, or migration that is created by one slice and read/written by another.

**Triggers**:
- Migration files exist and span feature boundaries
- One slice defines a model/entity that another slice queries
- PRD mentions data persistence that crosses feature boundaries

**Inconsistency symptoms**: column name/type mismatch, missing foreign keys, migration ordering conflicts, constraint divergence.

### P1 — Identify for Multi-Process / Event-Driven Systems

#### 4. Event/Message Contract (`event`)

Any event, message, or signal published by one slice and consumed by another.

**Triggers**:
- PRD mentions "event", "message", "queue", "pub/sub", "通知", "消息", "webhook", "callback"
- Files referencing message brokers (Kafka, RabbitMQ, Redis pub/sub, SNS/SQS)
- One slice writes to a topic/queue and another reads from it

**Inconsistency symptoms**: topic/queue name mismatch, payload schema divergence, partitioning key disagreement, different serialization format.

#### 5. Behavioral Contract (`behavioral`)

Any cross-cutting behavior that spans slices: auth flows, navigation/routing, state machine transitions, error handling conventions.

**Triggers**:
- PRD mentions "auth", "login", "permission", "role", "登录", "权限"
- PRD mentions "redirect", "navigate", "routing", "跳转"
- Multiple slices touch middleware, guards, interceptors
- Error handling strategy that must be consistent across slices

**Inconsistency symptoms**: different token claims/format, conflicting routes, inconsistent state transitions, incompatible error response shapes.

### P2 — Identify When Infrastructure is Touched

#### 6. Operational Contract (`operational`)

Configuration keys, environment variables, log formats, feature flags that span slices.

**Triggers**:
- New config/env vars introduced across multiple slices
- Logging/metrics instrumentation in multiple slices
- Feature flags that gate behavior across slices

**Inconsistency symptoms**: same config with different key names, incompatible env var defaults, diverging log field names.

---

## CSI Identification Heuristics (for PM)

Run these checks during decomposition, after the ownership map is drafted:

### Check 1: Import Reference Analysis

For each file in the impact map, check which slice owns its imports. If file A in SL-01 imports from file B in SL-02, file B's public API is a CSI.

### Check 2: PRD Keyword Scan

Scan the PRD for these keywords and map each to affected slices:

| Keywords | CSI Type |
|----------|-----------|
| API, endpoint, route, handler, controller, fetch, request, response | `api-*` |
| type, interface, enum, model, schema, DTO, entity | `shared-type` |
| migration, table, column, index, collection, document | `db-schema` |
| event, message, queue, pub/sub, webhook, callback, notify | `event` |
| auth, login, permission, role, middleware, redirect, navigate | `behavioral` |
| config, env, environment, feature flag, log, metric | `operational` |

### Check 3: Shared Directory Heuristic

| Directory Pattern | Likely CSI Type |
|-------------------|-----------------|
| `types/`, `interfaces/`, `models/`, `proto/`, `schemas/` | `shared-type` |
| `routes/`, `handlers/`, `controllers/`, `api/` | `api-*` |
| `migrations/`, `schema/`, `ddl/` | `db-schema` |
| `events/`, `messages/`, `queues/` | `event` |
| `middleware/`, `guards/`, `interceptors/`, `hooks/` | `behavioral` |
| `config/`, `.env`, `constants/` | `operational` |

### Check 4: Cross-Slice Data Flow

Trace data flow through the system:
1. Which slice **creates** data? (write path)
2. Which slice **reads** that data? (read path)
3. If writer and reader are different slices → CSI exists at the data boundary.

---

## Contract Spec Templates

Every Contract Spec has this common header:

```yaml
contract_id: "C-N"
type: "<csi-type>"
provider: "SL-XX"
consumers: ["SL-YY"]
description: "<one-line summary of what this contract governs>"
```

The `spec` block is type-specific:

### api-rest

```yaml
contract_id: "C-1"
type: "api-rest"
provider: "SL-01"
consumers: ["SL-02"]
description: "User registration endpoint"
spec:
  method: POST
  path: "/api/v1/users"
  headers:
    Content-Type: "application/json"
    Authorization: "Bearer <token>"   # if auth required
  request_body:
    username: { type: "string", required: true, minLength: 3, maxLength: 64 }
    email:    { type: "string", required: true, format: "email" }
    password: { type: "string", required: true, minLength: 8 }
  responses:
    "201":
      body:
        id:       { type: "string" }
        username: { type: "string" }
        email:    { type: "string" }
    "409":
      body:
        error: { type: "string" }
        code:  { type: "string", enum: ["USER_EXISTS", "EMAIL_EXISTS"] }
    "422":
      body:
        error:   { type: "string" }
        details: { type: "array", items: { field: "string", message: "string" } }
```

### api-rpc / grpc

```yaml
contract_id: "C-2"
type: "api-rpc"
provider: "SL-01"
consumers: ["SL-03"]
description: "User service GetUser RPC"
spec:
  service: "UserService"
  method: "GetUser"
  request:
    user_id: { type: "string", required: true }
  response:
    user:
      id:       { type: "string" }
      username: { type: "string" }
      email:    { type: "string" }
```

### shared-type

```yaml
contract_id: "C-3"
type: "shared-type"
provider: "SL-01"
consumers: ["SL-02", "SL-03"]
description: "User type shared across frontend and backend"
spec:
  language: "typescript"   # or "python", "go", "rust", "java"
  definition: |
    interface User {
      id: string;
      username: string;
      email: string;
      createdAt: string;  // ISO 8601
    }
```

For shared types, the `spec.definition` is the canonical source. The provider slice owns the definition file. Consumers import it — they must not redefine it.

### db-schema

```yaml
contract_id: "C-4"
type: "db-schema"
provider: "SL-01"
consumers: ["SL-02"]
description: "Users table schema"
spec:
  table: "users"
  columns:
    - name: "id"
      type: "uuid"
      primary_key: true
      default: "gen_random_uuid()"
    - name: "username"
      type: "varchar(64)"
      nullable: false
      unique: true
    - name: "email"
      type: "varchar(255)"
      nullable: false
      unique: true
    - name: "password_hash"
      type: "varchar(255)"
      nullable: false
    - name: "created_at"
      type: "timestamptz"
      nullable: false
      default: "now()"
  indexes:
    - name: "idx_users_email"
      columns: ["email"]
      unique: true
  migrations:
    - file: "migrations/001_create_users.sql"
      order: 1
      owned_by: "SL-01"
```

### event

```yaml
contract_id: "C-5"
type: "event"
provider: "SL-01"
consumers: ["SL-02"]
description: "UserRegistered event published after registration"
spec:
  topic: "user.registered"
  serialization: "json"
  partitioning_key: "user_id"
  payload:
    user_id:  { type: "string", required: true }
    username: { type: "string", required: true }
    email:    { type: "string", required: true }
    timestamp:{ type: "string", required: true, format: "ISO 8601" }
  schema_version: "1.0.0"
```

### behavioral

```yaml
contract_id: "C-6"
type: "behavioral"
provider: "SL-01"
consumers: ["SL-02", "SL-03"]
description: "Auth token format and middleware contract"
spec:
  domain: "authentication"
  token_format: "JWT"
  claims:
    sub:   { type: "string", description: "user ID" }
    role:  { type: "string", enum: ["admin", "user", "viewer"] }
    exp:   { type: "number", description: "expiration timestamp (unix)" }
  header_name: "Authorization"
  header_format: "Bearer <token>"
  middleware_behavior:
    on_invalid: "return 401 with { error: string }"
    on_expired: "return 401 with { error: string, code: 'TOKEN_EXPIRED' }"
    on_forbidden: "return 403 with { error: string }"
  route_guards:
    - path: "/api/admin/*"
      required_role: "admin"
    - path: "/api/users/*"
      required_role: "user"
```

### operational

```yaml
contract_id: "C-7"
type: "operational"
provider: "SL-01"
consumers: ["SL-02"]
description: "Shared configuration keys for the feature"
spec:
  env_vars:
    DATABASE_URL:  { type: "string", required: true, description: "Postgres connection string" }
    REDIS_URL:     { type: "string", required: true, description: "Redis connection string" }
    JWT_SECRET:    { type: "string", required: true, description: "Signing key for JWT tokens" }
    LOG_LEVEL:     { type: "string", default: "info", enum: ["debug", "info", "warn", "error"] }
  feature_flags:
    ENABLE_NEW_AUTH: { type: "boolean", default: false }
```

---

## Builder Contract Compliance

Each Builder whose Task Contract references one or more CSIs must include in their Agent Return:

```markdown
## Contract Compliance

| Contract ID | Status | Evidence |
|-------------|--------|----------|
| C-1         | compliant | POST /api/v1/users accepts {username, email, password}, returns 201 with {id, username, email}, returns 409 for duplicates |
| C-3         | compliant | User type in types/user.ts matches spec definition exactly |
```

Status values: `compliant` / `partial` / `blocked` / `not-applicable`

If `partial` or `blocked`: must explain under `Needs Orchestrator Decision`.

---

## Integration Check — Contract Validation

During integration check, the Orchestrator validates contracts by:

1. **Completeness check**: Every contract listed in the decomposition plan has a compliance report from every Builder bound to it (both provider and all consumers).
2. **Consistency check**: Provider and consumer(s) report the same contract ID with the same understanding. If provider says C-1 is compliant and consumer says C-1 is partial, flag as `RISK-N: contract-drift-C-1`.
3. **Unreported contracts**: If any contract has no compliance report from a bound Builder, mark that slice as `blocked` and do not proceed to TESTING.

The Orchestrator does not read source code to verify. Compliance is based on agent self-reports, cross-checked by Testers in the next phase.

---

## Tester Contract Verification

Testers must verify cross-slice contract compliance as part of their acceptance criteria testing. For each contract in their assigned slices:

1. **api-rest / api-rpc**: Make actual requests and assert response shape matches the contract spec.
2. **shared-type**: Run the type checker on the full project to detect type divergence.
3. **db-schema**: Compare actual DB schema (via introspection) against the contract spec.
4. **event**: Verify published event payloads match the contract spec.
5. **behavioral**: Test auth flow end-to-end, verify redirects and error responses match.
6. **operational**: Verify config keys are read with the expected names.

Testers report contract test results alongside AC-N results.
