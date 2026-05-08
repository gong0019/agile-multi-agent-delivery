# Agile Multi-Agent Delivery

中文 | [English](#english)

把 AI 的"直接写代码"升级成一条**纪律严明的多 Agent 交付流水线**。  
主 Agent（Orchestrator）**永不写代码**，只负责编排；所有实现工作由独立子 Agent 分工完成。

---

## 快速接入

**第一步：把 skill 放进项目**

```bash
# 方式 A：直接复制
cp -r /path/to/agile-multi-agent-delivery /your-project/

# 方式 B：git submodule
git submodule add <skill-repo-url> agile-multi-agent-delivery
```

**第二步：声明 skill**（一次性，之后无需任何额外操作）

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
    │   ┌──────────────────┐      ┌──────────────────┐        │
    │   │   ProductOwner   │      │    Challenger     │        │
    │   │  起草 PRD 文档   │      │   逐条挑战需求    │        │
    │   └────────┬─────────┘      └────────┬──────────┘        │
    │            └──────────┬─────────────┘                   │
    │                  各自独立返回                             │
    └───────────────────────┼──────────────────────────────────┘
                            │
    ┌───────────────────────▼──────────────────────────────────┐
    │  REQUIREMENTS_REVIEW                                      │
    │  Orchestrator 汇总分歧 → 生成"异议 vs 立场"对比表         │
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
    │   │  分析文件影响 → 拆分切片 → 生成 Task Contracts    │   │
    │   └──────────────────────────────────────────────────┘   │
    └───────────────────────┬──────────────────────────────────┘
                            │ check-constraints.sh 校验无文件冲突
    ┌───────────────────────▼──────────────────────────────────┐
    │  BUILDING                                                 │
    │                                                           │
    │   ┌──────────┐    ┌──────────┐    ┌──────────┐          │
    │   │ Builder1 │    │ Builder2 │    │ Builder3 │          │
    │   │  SL-01   │    │  SL-02   │    │  SL-03   │          │
    │   └──────────┘    └──────────┘    └──────────┘          │
    │         文件所有权严格互斥，可安全并行执行                  │
    └───────────────────────┬──────────────────────────────────┘
                            │
    ┌───────────────────────▼──────────────────────────────────┐
    │  INTEGRATION_CHECK                                        │
    │  Orchestrator 校验所有 Builder 返回，检测意外冲突          │
    │  有冲突 → 可选派 Integrator Agent 解决                    │
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
│ Tester-N        │ worker         │ 测试分配的切片 / 绝不改非测试文件           │
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

## English

`Agile Multi-Agent Delivery` upgrades AI code generation into a **disciplined, phase-gated multi-agent pipeline**.  
The main agent (**Orchestrator**) never writes code — it only orchestrates. All implementation is done by independent sub-agents.

---

### Setup

**Step 1: Add the skill to your project**

```bash
# Option A: copy
cp -r /path/to/agile-multi-agent-delivery /your-project/

# Option B: git submodule
git submodule add <skill-repo-url> agile-multi-agent-delivery
```

**Step 2: Declare the skill** (once — no action needed afterwards)

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
    │   ┌─────────────────┐      ┌─────────────────┐      │
    │   │  ProductOwner   │      │   Challenger     │      │
    │   │  drafts PRD     │      │  challenges PRD  │      │
    │   └────────┬────────┘      └────────┬─────────┘      │
    │            └──────────┬────────────┘                 │
    │                 return independently                  │
    └──────────────────────┼───────────────────────────────┘
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  REQUIREMENTS_REVIEW                                  │
    │  Orchestrator synthesizes divergence → presents table │
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
    │   │  file impact map → slices → Task Contracts     │  │
    │   └───────────────────────────────────────────────┘  │
    └──────────────────────┬───────────────────────────────┘
                           │ check-constraints.sh validates no overlap
    ┌──────────────────────▼───────────────────────────────┐
    │  BUILDING                                             │
    │   ┌──────────┐   ┌──────────┐   ┌──────────┐        │
    │   │ Builder1 │   │ Builder2 │   │ Builder3 │        │
    │   │  SL-01   │   │  SL-02   │   │  SL-03   │        │
    │   └──────────┘   └──────────┘   └──────────┘        │
    │       disjoint file ownership → safe parallel work    │
    └──────────────────────┬───────────────────────────────┘
                           │
    ┌──────────────────────▼───────────────────────────────┐
    │  INTEGRATION_CHECK                                    │
    │  Orchestrator checks all Builder returns for conflict │
    │  conflicts → optional Integrator agent                │
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
| Tester-N | worker | test files for assigned slices | modifies non-test source files |
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
