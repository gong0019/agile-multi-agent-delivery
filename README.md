# Agile Multi Agent Delivery

中文 | [English](#english)

这是一个面向 Codex 的交付型技能，用来把“直接写代码”升级成“像一个小型敏捷团队一样交付软件任务”。

它的重点不是机械地增加子代理数量，而是要求主代理像 `delivery-lead` 一样工作：先整理需求，再做一次确认，然后维护仓库内的迭代状态文件，拆分出可验证的切片，并且只把低冲突、边界明确的工作并行委派出去。

## 技能目标

- 把用户请求整理成明确的 `delivery brief`
- 在大规模实施前建立一次简洁的确认门
- 在仓库根目录创建或更新 `current-iteration.md`
- 将工作拆成可审查、可验证、可独立记录的切片
- 让主代理保留关键路径、集成决策和最终结论
- 让任务在 `/clear` 或新线程后仍可恢复

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

这个文件至少记录：

- `product_version`
- `iteration_version`
- `overall_completion`
- `current_slice_completion`
- 当前目标和已确认范围
- 验收标准
- 切片负责人、状态和受影响文件
- 验证日志
- 风险、阻塞项和下一次恢复提示

这个文件是跨 `/clear`、新线程和上下文压缩的单一事实来源。

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

## 配套文件

```text
.
├── SKILL.md
├── README.md
├── agents/
│   └── openai.yaml
└── references/
    ├── iteration-state-template.md
    └── team-operating-model.md
```

- `SKILL.md`
  技能主体说明，定义触发条件、流程、角色和规则。
- `references/iteration-state-template.md`
  `current-iteration.md` 的模板。
- `references/team-operating-model.md`
  多代理角色边界、压缩方式和委派规则参考。
- `agents/openai.yaml`
  UI 元数据和默认提示。

## 使用示例

```text
Use $agile-multi-agent-delivery to turn this request into a confirmed iteration, delegate safe parallel work, and keep current-iteration.md updated.
```

## English

`Agile Multi Agent Delivery` is a Codex skill for running software work like a compact, disciplined agile delivery team instead of a single linear coding pass.

Its purpose is not to maximize the number of subagents. Its purpose is to make the main agent operate like a `delivery-lead`: clarify the request, get one confirmation gate, maintain a repository-local iteration state file, split work into verifiable slices, and delegate only bounded low-conflict tasks in parallel.

## What The Skill Does

- Converts a user request into a concrete `delivery brief`
- Establishes one compact confirmation gate before broad implementation
- Creates or updates `current-iteration.md` in the repository root
- Breaks work into reviewable and independently recordable slices
- Keeps the main agent responsible for critical-path progress and final integration
- Preserves continuity across `/clear`, new threads, and context compression

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

At minimum it should track:

- `product_version`
- `iteration_version`
- `overall_completion`
- `current_slice_completion`
- current objective and accepted scope
- acceptance criteria
- slice ownership, status, and affected files
- verification log
- risks, blockers, and the exact next resume prompt

This file is the single source of truth across `/clear`, new threads, and context compression.

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

## Repository Layout

```text
.
├── SKILL.md
├── README.md
├── agents/
│   └── openai.yaml
└── references/
    ├── iteration-state-template.md
    └── team-operating-model.md
```

- `SKILL.md`
  Defines trigger conditions, workflow, roles, and execution rules.
- `references/iteration-state-template.md`
  Template for `current-iteration.md`.
- `references/team-operating-model.md`
  Reference for role boundaries, state compression, and delegation behavior.
- `agents/openai.yaml`
  UI metadata and the default prompt.

## Example Prompt

```text
Use $agile-multi-agent-delivery to turn this request into a confirmed iteration, delegate safe parallel work, and keep current-iteration.md updated.
```
