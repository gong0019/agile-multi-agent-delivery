# Agile Multi-Agent Delivery

中文 | [English](#english)

把 AI 的"直接写代码"升级成一条**纪律严明的多 Agent 交付流水线**。  
主 Agent（Orchestrator）**永不写代码**，只负责编排；所有实现工作由独立子 Agent 分工完成。

---

## 快速接入

**声明 skill**（一次性，之后无需任何额外操作）

```bash
bash agile-multi-agent-delivery/scripts/setup-project.sh
```

自动检测并写入 `CLAUDE.md`（Claude Code）、`AGENTS.md`（Codex）、`.cursor/rules/agile-delivery.md`（Cursor）或 `.windsurfrules`（Windsurf）。已配置过则跳过，幂等安全。

> 需要指定文件或手动配置，见 [BOOTSTRAP.md](BOOTSTRAP.md)。

---

## 你需要做什么

配置好之后，想用 agile 流程时直接说，其余全部由 AI 自动完成：

| 你做 | AI 自动做 |
| --- | --- |
| 说"用 agile-multi-agent-delivery 来做这个需求：[需求描述]" | 读取 SKILL.md，初始化 `.agile/` 状态目录 |
| （等待）| 起草交付简报，等待你确认 |
| **确认 PRD**（唯一需要回复的节点）| 拆分任务、并行开发、集成检查、并行测试 |
| （等待完成）| 维护状态文件，输出交付总结 |

普通的问题、bug 修复、代码解释——直接问就好，不会触发 agile 流程。

---

## 流水线图

```
  你描述需求
       │
       ▼
  ┌────────────────────────────────────────────────────────────┐
  │                       Orchestrator                          │
  │                  (永不写代码 · 只做编排)                     │
  └──────────────────────────┬─────────────────────────────────┘
                             │ 读 SKILL.md，初始化状态
                             │
    ┌────────────────────────▼────────────────────────────────┐
    │  REQUIREMENTS_DRAFTING                                   │
    │                                                          │
    │   ┌─────────────────────────────────────────────────┐   │
    │   │                  ProductOwner                    │   │
    │   │  审计现有功能 → 起草完整状态 PRD（含 EF 清单）   │   │
    │   └──────────────────────┬──────────────────────────┘   │
    │                          │ prd.md 写完后                  │
    │   ┌──────────────────────▼──────────────────────────┐   │
    │   │                   Challenger                     │   │
    │   │   审查完整 PRD · 验证 EF 覆盖 · 对抗性挑战       │   │
    │   └─────────────────────────────────────────────────┘   │
    └───────────────────────┬──────────────────────────────────┘
                            │
    ┌───────────────────────▼──────────────────────────────────┐
    │  REQUIREMENTS_REVIEW                                      │
    │  Orchestrator 汇总分歧 → 展示完整功能状态表供用户核查     │
    └───────────────────────┬──────────────────────────────────┘
                            │
              ╔═════════════▼═════════════╗
              ║      👤 你确认 PRD        ║  ← 唯一需要你回复的节点
              ╚═════════════╤═════════════╝
                            │
    ┌───────────────────────▼──────────────────────────────────┐
    │  PM_DECOMPOSITION                                         │
    │   ┌──────────────────────────────────────────────────┐   │
    │   │                 ProjectManager                    │   │
    │   │  PRD 完整性验证 → 拆分切片 → 分配 EF 保留职责    │   │
    │   └──────────────────────────────────────────────────┘   │
    └───────────────────────┬──────────────────────────────────┘
                            │ check-constraints.sh 校验无文件冲突 + EF 全覆盖
    ┌───────────────────────▼──────────────────────────────────┐
    │  BUILDING                                                 │
    │                                                           │
    │   ┌──────────┐    ┌──────────┐    ┌──────────┐          │
    │   │ Builder1 │    │ Builder2 │    │ Builder3 │          │
    │   │  SL-01   │    │  SL-02   │    │  SL-03   │          │
    │   └──────────┘    └──────────┘    └──────────┘          │
    │    文件所有权严格互斥 · 修改前审计现有行为 · 报告 EF 保留  │
    └───────────────────┬──────────────────────────────────────┘
                        │
    ┌───────────────────▼──────────────────────────────────────┐
    │  INTEGRATION_CHECK                                        │
    │  合约合规交叉验证 + 行为回归检查（EF preserve 全覆盖）     │
    │  有冲突或回归 → 可选派 Integrator Agent 解决              │
    └───────────────────────┬──────────────────────────────────┘
                            │
    ┌───────────────────────▼──────────────────────────────────┐
    │  TESTING                                                  │
    │                                                           │
    │          ┌──────────┐    ┌──────────┐                   │
    │          │ Tester-1 │    │ Tester-2 │                   │
    │          └──────────┘    └──────────┘                   │
    │              数量 = ⌈Builder 数 ÷ 2⌉，最少 1 个          │
    └───────────────────────┬──────────────────────────────────┘
                            │
                     ┌──────▼──────┐
                     │  COMPLETE   │
                     └─────────────┘
```

---

## 文件隔离：`.agile/` 目录

所有 skill 生成的文件都放在 `.agile/` 下，**不会污染项目根目录**。

```
your-project/
├── .agile/
│   ├── CURRENT                      ← 一行文本，指向当前活跃迭代 ID
│   ├── iter-20260508-01/            ← 需求 A（已归档）
│   │   ├── state.md                 ← 机器可读状态文件（YAML frontmatter）
│   │   └── prd.md                   ← PRD 文档
│   └── iter-20260508-02/            ← 需求 B（进行中）
│       ├── state.md
│       └── prd.md
│
├── src/                             ← 你的项目文件（skill 从不碰这里）
├── agile-multi-agent-delivery/      ← skill 本身（可以是 submodule）
└── ...
```

建议把 `.agile/` 提交到 git，保留完整的交付历史。

---

## 多需求管理

每个需求对应一个独立的迭代目录，互不干扰：

```
# 查看当前活跃的状态文件
scripts/current-state.sh

# 列出所有迭代及状态
scripts/list-iterations.sh

# 手动初始化一个新迭代（Orchestrator 会自动调用，通常不需要手动执行）
scripts/init-state.sh
```

`list-iterations.sh` 输出示例：

```
Iteration ID               Phase                    Completion
------------------------------------------------------------------------
iter-20260508-02           BUILDING                 40%          ← CURRENT
iter-20260508-01           COMPLETE                 100%
```

---

## 角色一览

```
┌─────────────────┬────────────────┬──────────────────────────────────────────┐
│ 角色             │ 类型           │ 职责 / 绝不做                             │
├─────────────────┼────────────────┼──────────────────────────────────────────┤
│ Orchestrator    │ 主 Agent       │ 编排 + 状态文件 / 绝不写代码               │
│ ProductOwner    │ explorer       │ 起草 PRD / 绝不写代码                      │
│ Challenger      │ explorer       │ 对抗性需求审查 / 绝不直接修改 PRD          │
│ ProjectManager  │ explorer       │ 拆分切片 + Task Contracts / 绝不写代码     │
│ Builder-N       │ worker         │ 一个边界明确的实现切片 / 绝不碰合同外文件   │
│ Tester-N        │ worker         │ 7 维度质量评估 / 绝不改非测试文件           │
│ Integrator      │ worker（可选） │ 跨切片集成冲突 / 绝不重新实现已完成切片     │
└─────────────────┴────────────────┴──────────────────────────────────────────┘
```

**Builder 数量规则：**

| 预估改动文件数 | Builder 数量 |
| --- | --- |
| 1–3 | 1 |
| 4–10 | 2–3 |
| 11–20 | 3–4 |
| 21+ | 4–6（上限） |

---

## 脚本参考（Orchestrator 自动调用，用户无需手动执行）

| 脚本 | 调用时机 |
| --- | --- |
| `scripts/init-state.sh` | 首次运行，状态文件不存在时 |
| `scripts/current-state.sh` | 每次需要定位活跃状态文件时 |
| `scripts/list-iterations.sh` | 列出迭代历史时 |
| `scripts/validate-state.sh` | 每次阶段切换前 |
| `scripts/validate-prd.sh` | PRD 生成后及确认后 |
| `scripts/check-constraints.sh` | 派生 Builder agents 前 |

完整协议见 [SKILL.md](SKILL.md)。

---

## v2.3 关键升级：可执行规格系统

### Project Constitution（项目宪法）

在项目根目录放 `.agile/constitution.md` 或 `CONSTITUTION.md`，定义整个项目不可侵犯的工程原则：

```markdown
## Article I: API 规范
- 所有 HTTP 响应使用标准 envelope：{ data, error }
- 错误码为 SCREAMING_SNAKE_CASE 字符串，不用数字

## Article II: 数据层
- 所有时间戳用 timestamptz，不用 timestamp
- 不得硬删除用户数据

## Article III: 测试要求
- 实现代码之前必须先写会 FAIL 的单元测试
- 禁止 mock 数据库，必须用真实测试数据库
```

Orchestrator 在 INIT 时读取宪法，将规则注入所有 Task Contract 的 `must_respect` 字段——**一次定义，全局生效，所有 Agent 自动遵守**。

完整模板见 `references/constitution-guide.md`。

### `[NEEDS CLARIFICATION]` 强制澄清机制

PRD 中任何不确定的需求，PO 必须标注 `[NEEDS CLARIFICATION: <问题>]` 而不是自行猜测：

```
| FR-2 | [NEEDS CLARIFICATION: 这个限制是否也适用于管理员？] | AC-2 | Must |
```

Orchestrator 在用户确认门会列出所有未解决的标记，**确认包不得在有未解决标记时呈现**。用户决策后，PO 替换为具体规格。

### Given/When/Then 验收标准

所有 AC-N 和 RAC-N 改用精确的三段式格式：

```
AC-1 — 头像上传
Given  用户在设置页且已登录
When   用户点击"上传头像"并选择一个 5MB 以内的 JPEG 文件
Then   头像立即更新，旧头像被替换，显示"上传成功"提示

Edge cases:
- 文件 > 5MB: 显示"文件过大，最大 5MB"
- 非 JPEG/PNG: 显示"仅支持 JPEG 和 PNG 格式"
```

"Then" 子句是 Tester 的直接测试断言，Edge cases 是额外测试用例——不再需要猜"这个 AC 到底测什么"。

---

## v2.2 关键升级：Brownfield 完整性保护 + 深度测试

### Brownfield 完整性保护

修改现有模块时，原有功能不再会被悄悄丢弃：

| 流水线节点 | 新增保护 |
| --- | --- |
| Orchestrator INIT | 区分 greenfield / brownfield；brownfield 先列出**现有功能清单**（EF-N 表） |
| ProductOwner | PRD 写**完整最终状态**，不是变更描述；每个 EF 项标注 preserve / modify / remove |
| 用户确认门 | 展示**完整功能状态表**，remove 项需逐条明确确认 |
| ProjectManager | 新增 Step 0.5：PRD 完整性验证，发现漏洞先返回 Gap Report |
| Builder | Task Contract 含 `preserve_behaviors`；修改前先审计现有行为；Agent Return 含 Behaviors Preserved |
| Integration Check | 新增第 5 项：行为回归检查，EF preserve 项必须全部出现在 Builder 报告中 |

### 深度测试协议（Tester）

Tester 从"验收核对员"升级为"质量工程师"，执行 7 个维度：

| 维度 | 核心问题 |
| --- | --- |
| 1. 影响范围分析 | 改动波及了哪些没有直接修改但依赖它的代码？ |
| 2. 全量回归扫描 | 完整测试套件有无意外失败？相邻功能烟雾测试正常吗？ |
| 3. 逻辑自洽性 | 新功能所有状态可达吗？操作在所有上下文中都闭合吗？ |
| 4. 上下文融合性 | 改动是否符合周围代码的模式？调用方的隐式假设还成立吗？ |
| 5. 前端–后端数据流 | 接口参数字段名/类型正确吗？响应处理路径对吗？流程符合 PRD 意图吗？ |
| 6. UX 质量评估 | 空态/错误态/加载态是否清晰？视觉一致吗？交互符合直觉吗？ |
| 7. 探索性测试 | 边界输入、意外操作顺序、中断恢复能发现什么？ |

---

## English

`Agile Multi-Agent Delivery` upgrades AI code generation into a **disciplined, phase-gated multi-agent pipeline**.  
The main agent (**Orchestrator**) never writes code — it only orchestrates. All implementation is done by independent sub-agents.

---

### Setup

**Declare the skill** (once — no action needed afterwards)

```bash
bash agile-multi-agent-delivery/scripts/setup-project.sh
```

Auto-detects and writes to `CLAUDE.md` (Claude Code), `AGENTS.md` (Codex), `.cursor/rules/agile-delivery.md` (Cursor), or `.windsurfrules` (Windsurf). Idempotent — skips silently if already configured.

> To specify a custom file or configure manually, see [BOOTSTRAP.md](BOOTSTRAP.md).

---

### What You Do vs. What the AI Does

| You do | AI does automatically |
| --- | --- |
| Say "use $agile-multi-agent-delivery for: [your request]" | Read SKILL.md, initialize `.agile/` directory |
| (wait) | Draft a delivery brief, wait for your approval |
| **Confirm the PRD** (the only reply needed) | Decompose, build in parallel, integrate, test |
| (wait) | Maintain state file, deliver summary |

Normal questions, bug fixes, and code explanations work as usual — the agile pipeline is not triggered.

---

### Pipeline

```
  You describe a request
         │
         ▼
  ┌──────────────────────────────────────────────────────────┐
  │                     Orchestrator                          │
  │              (never writes code · orchestrates only)      │
  └────────────────────────┬─────────────────────────────────┘
                           │ reads SKILL.md, initializes state
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  REQUIREMENTS_DRAFTING                                │
    │   ┌─────────────────────────────────────────────┐   │
    │   │               ProductOwner                   │   │
    │   │  audits existing features → drafts complete- │   │
    │   │  state PRD with Existing Feature Inventory   │   │
    │   └───────────────────┬─────────────────────────┘   │
    │                       │ prd.md written                │
    │   ┌───────────────────▼─────────────────────────┐   │
    │   │               Challenger                     │   │
    │   │  reviews full PRD · checks EF coverage ·     │   │
    │   │  adversarial challenge                        │   │
    │   └─────────────────────────────────────────────┘   │
    └──────────────────────┬───────────────────────────────┘
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  REQUIREMENTS_REVIEW                                  │
    │  Orchestrator synthesizes divergence →                │
    │  shows Complete Feature State Table for user review   │
    └──────────────────────┬───────────────────────────────┘
                           │
            ╔══════════════▼══════════════╗
            ║    👤 You confirm the PRD   ║  ← only user action needed
            ╚══════════════╤══════════════╝
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  PM_DECOMPOSITION                                     │
    │   ┌───────────────────────────────────────────────┐  │
    │   │              ProjectManager                    │  │
    │   │  PRD completeness check → slices →             │  │
    │   │  Task Contracts with preserve_behaviors        │  │
    │   └───────────────────────────────────────────────┘  │
    └──────────────────────┬───────────────────────────────┘
                           │ validates no overlap + EF fully assigned
    ┌──────────────────────▼───────────────────────────────┐
    │  BUILDING                                             │
    │   ┌──────────┐   ┌──────────┐   ┌──────────┐        │
    │   │ Builder1 │   │ Builder2 │   │ Builder3 │        │
    │   │  SL-01   │   │  SL-02   │   │  SL-03   │        │
    │   └──────────┘   └──────────┘   └──────────┘        │
    │  disjoint ownership · audit before modify ·           │
    │  report Behaviors Preserved per EF item               │
    └──────────────────────┬───────────────────────────────┘
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  INTEGRATION_CHECK                                    │
    │  contract compliance + behavioral regression check    │
    │  (every preserve EF item must appear in returns)      │
    │  failures → optional Integrator agent                 │
    └──────────────────────┬───────────────────────────────┘
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  TESTING                                              │
    │          ┌──────────┐   ┌──────────┐                 │
    │          │ Tester-1 │   │ Tester-2 │                 │
    │          └──────────┘   └──────────┘                 │
    │              count = ⌈builders ÷ 2⌉, min 1            │
    └──────────────────────┬───────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  COMPLETE   │
                    └─────────────┘
```

---

### File Isolation: `.agile/` Directory

All skill-generated files live under `.agile/` — **your project files are never touched**.

```
your-project/
├── .agile/
│   ├── CURRENT                    ← one-line file: active iteration ID
│   ├── iter-20260508-01/          ← requirement A (archived)
│   │   ├── state.md               ← machine-readable state (YAML frontmatter)
│   │   └── prd.md                 ← PRD document
│   └── iter-20260508-02/          ← requirement B (in progress)
│       ├── state.md
│       └── prd.md
│
├── src/                           ← your project (skill never touches this)
├── agile-multi-agent-delivery/    ← the skill (can be a submodule)
└── ...
```

Commit `.agile/` to git to preserve your full delivery history.

---

### Roles

| Role | Type | Owns | Never Does |
| --- | --- | --- | --- |
| Orchestrator | main agent | state file, phase transitions, user comms | writes code, reads large files |
| ProductOwner | explorer | PRD document | writes code |
| Challenger | explorer | adversarial PRD review | writes code, modifies PRD directly |
| ProjectManager | explorer | decomposition plan, Task Contracts | writes code, makes product decisions |
| Builder-N | worker | one bounded implementation slice | touches files outside its Task Contract |
| Tester-N | worker | 7-dimension quality audit (impact radius, regression sweep, logic consistency, contextual coherence, frontend–backend flow, UX quality, exploratory) | modifies non-test source files |
| Integrator | worker (optional) | cross-slice integration conflicts | re-implements already-done slices |

**Builder count rules:**

| Estimated file changes | Builder count |
| --- | --- |
| 1–3 | 1 |
| 4–10 | 2–3 |
| 11–20 | 3–4 |
| 21+ | 4–6 (hard max) |

---

### Scripts Reference (run by Orchestrator, not the user)

| Script | When |
| --- | --- |
| `scripts/init-state.sh` | First run, no state file exists |
| `scripts/current-state.sh` | Any time the active state file is needed |
| `scripts/list-iterations.sh` | Listing iteration history |
| `scripts/validate-state.sh` | Before each phase transition |
| `scripts/validate-prd.sh` | After PRD is created and after confirmation |
| `scripts/check-constraints.sh` | Before spawning Builder agents |

Full protocol: [SKILL.md](SKILL.md)

---

## v2.3 Highlights: Executable Specification System

### Project Constitution

Place `.agile/constitution.md` or `CONSTITUTION.md` in the project root. Define inviolable engineering principles for the entire project:

```markdown
## Article I: API Conventions
- All HTTP responses use standard envelope: { data, error }
- Error codes are SCREAMING_SNAKE_CASE strings, never numeric

## Article III: Testing Mandate
- No implementation before failing tests
- No database mocks — use a real test database
```

The Orchestrator reads the constitution at INIT and injects every rule into all Task Contracts' `must_respect` field. **Define once, enforced everywhere, by every agent automatically.**

Full template: `references/constitution-guide.md`

### `[NEEDS CLARIFICATION]` Mandatory Uncertainty Markers

When a requirement cannot be specified without a user decision, the ProductOwner must write `[NEEDS CLARIFICATION: <question>]` — never guess:

```
| FR-2 | [NEEDS CLARIFICATION: does this restriction also apply to admin users?] | AC-2 | Must |
```

The Orchestrator scans the PRD at the confirmation gate and lists every unresolved marker. **The confirmation package is not presented until all markers are resolved.**

### Given/When/Then Acceptance Criteria

All AC-N and RAC-N items use the precise three-part format:

```
AC-1 — Avatar Upload
Given  the user is on the settings page and logged in
When   the user clicks "Upload Avatar" and selects a JPEG under 5MB
Then   the avatar updates immediately; the old avatar is replaced; a success toast appears

Edge cases:
- file > 5MB: show "File too large. Maximum 5MB."
- non-JPEG/PNG: show "Only JPEG and PNG are supported."
```

The "Then" clause is the Tester's direct assertion. Edge cases are additional test cases. No more guessing what an AC means to test.

---

## v2.2 Highlights: Brownfield Protection + Deep Testing

### Brownfield Completeness Protection

When modifying existing modules, existing features can no longer silently disappear:

| Pipeline node | New protection |
| --- | --- |
| Orchestrator INIT | Classifies greenfield vs brownfield; brownfield produces **Existing Feature Inventory** (EF-N table) |
| ProductOwner | PRD describes **complete final state**, not a delta; every EF item tagged preserve / modify / remove |
| Confirmation gate | Shows **Complete Feature State Table**; `remove` items require explicit per-item user approval |
| ProjectManager | New Step 0.5: PRD completeness check against codebase; returns Gap Report if behaviors are missing |
| Builder | Task Contract includes `preserve_behaviors`; must audit full file before editing; reports Behaviors Preserved |
| Integration Check | New 5th check: behavioral regression — every EF `preserve` item must appear in Builder returns |

### Deep Testing Protocol (Tester)

Tester upgraded from confirmatory auditor to quality engineer — 7 mandatory dimensions:

| Dimension | Core question |
| --- | --- |
| 1. Impact Radius | What code outside the slice depends on what was changed? |
| 2. Regression Sweep | Any unexpected failures in the full test suite? Adjacent features still work? |
| 3. Logic Consistency | All states reachable? All operations closed across all contexts? |
| 4. Contextual Coherence | Does the change fit surrounding code patterns? Caller assumptions still valid? |
| 5. Frontend–Backend Flow | Field names/types correct? Response paths right? Full flow matches PRD intent? |
| 6. UX Quality | Empty/error/loading states clear? Visually consistent? Interactions intuitive? |
| 7. Exploratory | Boundary inputs, unexpected sequences, interruption recovery — what surfaces? |
