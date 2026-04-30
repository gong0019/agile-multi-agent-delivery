# Agile Multi Agent Delivery

中文 | [English](#english)

这是一个给 Codex 使用的技能，目标是把一次普通开发请求，转换成更像真实敏捷交付团队的执行流程。

它不是简单地让模型“多开几个 agent”，而是要求主代理像 `delivery lead` 一样工作：先澄清目标，再拆分切片，安全并行，持续集成，并把迭代状态写入仓库内的持久文件，便于在 `/clear` 或新线程后继续推进。

## 核心能力

- 将用户请求整理成可执行的交付 brief
- 在正式实施前提供一次简洁确认门
- 创建或更新 `.codex/agile/current-iteration.md`
- 将任务拆成边界清晰、可验证的切片
- 在安全前提下把非关键路径工作并行委派给子代理
- 由主代理保留集成、风险决策、状态维护和最终交付

## 适用场景

- 多文件或多模块功能开发
- 需要并行推进的实现任务
- 需要明确验收标准和范围控制的需求
- 需要在长对话、上下文压缩或新线程之间保持连续性的工作

## 不适用场景

- 单文件、小范围、一次性修改
- 只做头脑风暴，不进入执行
- 把关键路径完整外包给子代理

## 工作方式

技能默认采用一个紧凑的团队形态：

1. `delivery-lead`
   主代理。负责用户沟通、范围控制、集成决策和最终结论。
2. `scope-analyst`
   用于补足需求边界、影响范围和拆分点的分析角色。
3. `builder`
   负责独立写入范围内实现切片的工作角色。
4. `reviewer`
   负责独立审查、回归检查或验证的角色。

标准流程：

1. 读取仓库规则并理解请求
2. 产出交付 brief
3. 获得一次明确确认
4. 初始化或更新迭代状态文件
5. 规划切片并安全并行
6. 主代理完成关键路径集成
7. 记录验证结果、风险和下次续跑提示

## 状态文件

这个技能默认把迭代真相写到：

```text
.codex/agile/current-iteration.md
```

状态文件至少会记录：

- 产品版本和迭代版本
- 当前目标与已确认范围
- 验收标准
- 切片负责人和状态
- 完成度
- 变更文件
- 验证结果
- 风险、阻塞项和下一次恢复提示

## 仓库结构

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

## 使用示例

你可以直接让 Codex 使用这个技能，例如：

```text
Use $agile-multi-agent-delivery to turn this request into a confirmed iteration, delegate safe parallel work, and keep `.codex/agile/current-iteration.md` updated.
```

## 设计原则

- 主代理始终掌握仓库真相和关键路径
- 只并行委派边界清晰、低冲突的工作
- 先确认，再放大执行
- 状态文件优先于聊天上下文
- 验证和风险必须如实记录

## English

`Agile Multi Agent Delivery` is a Codex skill for running software work like a disciplined agile delivery team rather than a single linear coding pass.

It does not just encourage “more agents.” It makes the main agent behave like a delivery lead: clarify the target, confirm scope, split work into bounded slices, delegate safe sidecar tasks in parallel, integrate results locally, and keep a persistent iteration state file so work can survive `/clear` or a fresh thread.

## What It Does

- Turns a user request into a concrete delivery brief
- Adds a compact confirmation gate before broad implementation
- Creates or updates `.codex/agile/current-iteration.md`
- Breaks execution into reviewable and verifiable slices
- Delegates only safe, bounded parallel work to subagents
- Keeps integration, risk decisions, state ownership, and final synthesis in the main agent

## Good Fit

- Multi-file or multi-module implementation work
- Tasks that benefit from safe parallel execution
- Requests that need explicit scope and acceptance criteria
- Long-running work that must survive context resets or new threads

## Not a Good Fit

- Tiny one-off edits
- Pure brainstorming with no execution intent
- Delegating the full critical path away from the main agent

## Team Model

The skill uses a compact role set:

1. `delivery-lead`
   The main agent. Owns communication, scope, integration, and final truth.
2. `scope-analyst`
   Used for requirement edges, impact analysis, and split-point discovery.
3. `builder`
   Owns one isolated implementation slice with a disjoint write scope.
4. `reviewer`
   Performs independent review, regression checks, or focused verification.

## Workflow

1. Read repository rules and inspect only the necessary context
2. Build a delivery brief
3. Get one clear confirmation from the user
4. Initialize or update the iteration state file
5. Plan slices and delegate safe parallel work
6. Keep critical-path integration in the main agent
7. Record verification, risks, and the next resume prompt

## Persistent State

The default state file is:

```text
.codex/agile/current-iteration.md
```

It tracks:

- product and iteration versions
- current objective and accepted scope
- acceptance criteria
- slice ownership and status
- completion progress
- changed files
- verification status
- open risks, blockers, and the exact next resume prompt

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

## Example Prompt

```text
Use $agile-multi-agent-delivery to turn this request into a confirmed iteration, delegate safe parallel work, and keep `.codex/agile/current-iteration.md` updated.
```

## Design Principles

- The main agent owns repo truth and the critical path
- Only bounded, low-conflict work should be delegated
- Confirm before scaling execution
- The state file matters more than chat history
- Verification and residual risk must be recorded honestly
