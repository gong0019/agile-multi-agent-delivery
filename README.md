# Agile Multi Agent Delivery

中文 | [English](#english)

这是一个面向 AI 编码代理的通用工程化技能，用来把"直接写代码"升级成"像一个小型敏捷团队一样交付软件任务"。它不依赖任何特定的 AI 编码工具，适用于 Claude Code、Cursor、Codex 等。

它的重点不是机械地增加子代理数量，而是要求主代理像 `delivery-lead` 一样工作：先整理需求，再做一次确认，然后维护仓库内的迭代状态文件，拆分出可验证的切片，并且只把低冲突、边界明确的工作并行委派出去。

## 技能目标

- 把用户请求整理成明确的 `delivery brief`
- 在大规模实施前建立一次简洁的确认门
- 在仓库根目录创建或更新 `current-iteration.md`
- 将工作拆成可审查、可验证、可独立记录的切片
- 让主代理保留关键路径、集成决策和最终结论
- 让任务在上下文重置或新线程后仍可恢复
- 状态文件通过 JSON Schema 校验，确保一致性

## 适用场景

- 多模块或多文件功能开发
- 需要边做边记录状态的连续交付
- 适合安全并行拆分的开发任务
- 需要明确范围、验收标准和风险记录的请求

## 不适用场景

- 很小的一次性修改
- 仅做头脑风暴、不进入执行
- 把关键路径直接整体外包给子代理

## 默认团队形态

这个 skill 使用一个紧凑角色集，而不是模拟大组织：

1. `delivery-lead`
   主代理。负责用户沟通、范围控制、集成、风险判断和最终事实。
2. `scope-analyst`
   用于需求边界、影响分析和并行拆分点澄清的 `explorer`。
3. `builder`
   负责一个独立实现切片的 `worker`。
4. `reviewer`
   负责独立审查、回归检查或验证的 `explorer`/`worker`。

在确有必要时，可以额外使用 `technical architect` 做结构或兼容性分析，但不是默认常驻角色。

## 标准工作流

1. 读取仓库规则和最小必要上下文
2. 将请求改写成具体交付 brief
3. 向用户提供一次紧凑确认包
4. 在仓库根目录初始化或更新 `current-iteration.md`
5. 规划切片并识别哪些工作可安全并行
6. 主代理保持关键路径推进，本地完成集成
7. 记录验证结果、已知风险和下一次恢复提示

## 持久状态文件

当前 skill 的默认状态文件是仓库根目录：

```text
current-iteration.md
```

如果仓库已经有等价的敏捷状态文件，可以复用，不强制改名。

状态文件包含 YAML frontmatter（机器可校验）和 Markdown 正文（人类可读）。frontmatter 通过 `schema/state-file.json` 校验。

这个文件至少记录：

- `skill_version` — 生成此状态文件的技能版本
- `product_version`
- `iteration_version`
- `overall_completion`
- `current_slice_completion`
- 当前目标和已确认范围
- 验收标准
- 切片负责人、状态和受影响文件
- 验证日志
- 风险、阻塞项和下一次恢复提示

这个文件是跨上下文重置、新线程和上下文压缩的单一事实来源。

## 关键约束

以下高风险区域原则上由主代理保留最终集成责任：

- 认证和授权流程
- 路由、导航和入口控制流
- 共享 API / RPC 请求响应契约
- 时区、地区、货币、日期等敏感业务逻辑
- schema migration 和跨服务兼容性
- 会真实创建、修改或删除数据的测试与脚本

子代理可以分析或提出改动，但最终集成判断应由 `delivery-lead` 完成。

## 委派原则

好的并行委派应当：

- 有清晰边界
- 有明确文件范围
- 不覆盖关键路径
- 不依赖未解决的产品决策
- 有明确交付物和停止条件

每个子任务应从当前 `State Ledger` 派生，并包装成一个简洁的 `Task Contract`。推荐字段包括：

- `Task ID`
- `Round Version`
- `Objective`
- `In Scope`
- `Out of Scope`
- `Files/Paths Allowed`
- `Files/Paths Avoid`
- `Must Respect`
- `Expected Deliverable`
- `Stop When`
- `Escalate If`

## 工程化能力

本项目不仅是一份操作手册，还提供了可执行的工程化工具：

| 工具 | 用途 |
|---|---|
| `scripts/validate-state.sh` | 校验状态文件的 YAML frontmatter 是否符合 schema |
| `scripts/init-state.sh` | 从模板初始化新的状态文件 |
| `scripts/check-constraints.sh` | 检查关键 harness 不变量 |
| `schema/state-file.json` | 状态文件的 JSON Schema 定义 |
| `schema/task-contract.json` | 任务契约的 JSON Schema 定义 |
| `references/error-recovery.md` | 错误场景与恢复流程 |
| `hooks/settings.json.example` | hook 配置示例 |
| `tests/test-validate-state.sh` | 验证脚本的冒烟测试 |

快速开始：

```bash
# 初始化状态文件
./scripts/init-state.sh

# 校验状态文件
./scripts/validate-state.sh

# 检查 harness 不变量
./scripts/check-constraints.sh

# 运行测试
./tests/test-validate-state.sh
```

## 配套文件

```text
.
├── SKILL.md
├── README.md
├── CHANGELOG.md
├── schema/
│   ├── state-file.json
│   └── task-contract.json
├── scripts/
│   ├── validate-state.sh
│   ├── init-state.sh
│   └── check-constraints.sh
├── tests/
│   ├── test-validate-state.sh
│   └── fixtures/
├── hooks/
│   └── settings.json.example
├── references/
│   ├── iteration-state-template.md
│   ├── team-operating-model.md
│   └── error-recovery.md
├── agents/
│   └── openai.yaml
└── .github/
    └── workflows/
        └── validate.yml
```

## 使用示例

```text
Use $agile-multi-agent-delivery to turn this request into a confirmed iteration, delegate safe parallel work, and keep current-iteration.md updated.
```

## English

`Agile Multi Agent Delivery` is a general-purpose skill for AI coding agents (Claude Code, Cursor, Codex, etc.) that runs software work like a compact, disciplined agile delivery team instead of a single linear coding pass.

Its purpose is not to maximize the number of subagents. Its purpose is to make the main agent operate like a `delivery-lead`: clarify the request, get one confirmation gate, maintain a repository-local iteration state file with machine-validatable frontmatter, split work into verifiable slices, and delegate only bounded low-conflict tasks in parallel.

## What The Skill Does

- Converts a user request into a concrete `delivery brief`
- Establishes one compact confirmation gate before broad implementation
- Creates or updates `current-iteration.md` with YAML frontmatter validated by JSON Schema
- Breaks work into reviewable and independently recordable slices
- Keeps the main agent responsible for critical-path progress and final integration
- Preserves continuity across context resets, new threads, and context compression
- Provides executable validation scripts for state file integrity

## Good Fit

- Multi-file or multi-module feature work
- Iterative delivery that needs persistent state tracking
- Implementation tasks that can be split into safe parallel slices
- Requests that need explicit scope, acceptance criteria, and risk tracking

## Not A Good Fit

- Tiny one-off edits
- Brainstorming with no execution intent
- Handing the whole critical path to subagents

## Default Team Shape

The skill uses a compact role set rather than a large org chart:

1. `delivery-lead`
   The main agent. Owns communication, scope, integration, risk decisions, and final truth.
2. `scope-analyst`
   An `explorer` for requirement edges, impact analysis, and split-point clarification.
3. `builder`
   A `worker` that owns one isolated implementation slice.
4. `reviewer`
   An `explorer` or `worker` for independent review, regression checks, or verification.

When needed, a `technical architect` can be used for architecture or compatibility discovery, but it is optional rather than a default always-on role.

## Standard Workflow

1. Read repository rules and the minimum necessary context
2. Rewrite the request into a concrete delivery brief
3. Present one compact confirmation package
4. Initialize or update `current-iteration.md` in the repository root
5. Plan slices and identify safe parallel work
6. Keep the critical path local to the main agent and integrate results there
7. Record verification, residual risks, and the next resume prompt

## Persistent State File

The default state file is:

```text
current-iteration.md
```

If the repository already has an equivalent agile state file, reuse it instead of forcing a rename.

The state file contains a YAML frontmatter (machine-validated via `schema/state-file.json`) followed by a human-readable Markdown body.

At minimum the frontmatter must track:

- `skill_version`
- `product_version`
- `iteration_version`
- `overall_completion`
- `current_slice_completion`
- `last_updated`
- `active_objective`
- `acceptance_criteria`
- `slice_board`
- `next_resume_prompt`

This file is the single source of truth across context resets, new threads, and context compression.

## High-Risk Areas

These areas should normally remain under main-agent integration control:

- authentication and authorization flows
- routing, navigation, and app-entry control flow
- shared API / RPC contracts
- time zone, locale, currency, and date-sensitive business logic
- schema migrations and cross-service compatibility
- tests or scripts that create, mutate, or delete real data

Subagents may inspect or propose changes here, but the `delivery-lead` should make the final integration decision.

## Delegation Rules

Good parallel delegation should have:

- clear boundaries
- explicit file ownership
- no critical-path ambiguity
- no dependence on unresolved product choices
- a defined deliverable and stopping condition

Each delegated task should come from the current `State Ledger` and be wrapped in a compact `Task Contract`, typically including:

- `Task ID`
- `Round Version`
- `Objective`
- `In Scope`
- `Out of Scope`
- `Files/Paths Allowed`
- `Files/Paths Avoid`
- `Must Respect`
- `Expected Deliverable`
- `Stop When`
- `Escalate If`

## Engineering Tooling

This project ships with executable tooling beyond documentation:

| Tool | Purpose |
|---|---|
| `scripts/validate-state.sh` | Validate state file frontmatter against JSON Schema |
| `scripts/init-state.sh` | Initialize a new state file from template |
| `scripts/check-constraints.sh` | Check key harness invariants |
| `schema/state-file.json` | JSON Schema for state file frontmatter |
| `schema/task-contract.json` | JSON Schema for task contracts |
| `references/error-recovery.md` | Error scenarios and recovery procedures |
| `hooks/settings.json.example` | Example hook configuration |
| `tests/test-validate-state.sh` | Smoke tests for validation scripts |

Quick start:

```bash
# Initialize state file
./scripts/init-state.sh

# Validate state file
./scripts/validate-state.sh

# Check harness invariants
./scripts/check-constraints.sh

# Run tests
./tests/test-validate-state.sh
```

## Repository Layout

```text
.
├── SKILL.md
├── README.md
├── CHANGELOG.md
├── schema/
│   ├── state-file.json
│   └── task-contract.json
├── scripts/
│   ├── validate-state.sh
│   ├── init-state.sh
│   └── check-constraints.sh
├── tests/
│   ├── test-validate-state.sh
│   └── fixtures/
├── hooks/
│   └── settings.json.example
├── references/
│   ├── iteration-state-template.md
│   ├── team-operating-model.md
│   └── error-recovery.md
├── agents/
│   └── openai.yaml
└── .github/
    └── workflows/
        └── validate.yml
```

## Example Prompt

```text
Use $agile-multi-agent-delivery to turn this request into a confirmed iteration, delegate safe parallel work, and keep current-iteration.md updated.
```
