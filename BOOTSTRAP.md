# Bootstrap — Agile Multi Agent Delivery

---

## 第一步：接入项目（一次性配置）

把 skill 目录复制到项目里之后，在项目配置文件中**声明** skill 的存在。  
AI 不会自动激活，只有你主动说"用这个 skill"时才会触发。

### Claude Code — `CLAUDE.md`

在项目根目录的 `CLAUDE.md` 中加入：

```markdown
## Agile Delivery Skill

This project includes `agile-multi-agent-delivery/` — a structured multi-agent delivery skill.

Activate it **only** when the user explicitly requests it, for example:
- "用 agile-multi-agent-delivery 来做这个需求"
- "start an agile iteration for..."
- "use $agile-multi-agent-delivery"

When activated:
1. Read `agile-multi-agent-delivery/SKILL.md` in full before acting
2. Act as the Orchestrator — never write source code directly
3. All delivery files live under `.agile/` — never create files in the project root
4. Find the active state: `agile-multi-agent-delivery/scripts/current-state.sh`

Do not activate for normal coding questions, bug fixes, or explanations.
```

### Cursor — `.cursor/rules/agile-delivery.mdc`

```
---
description: Agile multi-agent delivery skill
globs: ["**/*"]
alwaysApply: false
---

Activate ONLY when the user explicitly asks to use agile-multi-agent-delivery
or start a formal delivery iteration.

When activated: read agile-multi-agent-delivery/SKILL.md and act as the
Orchestrator. Never write code directly. All delivery files under .agile/.
Active state: agile-multi-agent-delivery/scripts/current-state.sh
```

### Windsurf — `.windsurfrules`

```
Agile delivery skill is available at agile-multi-agent-delivery/.
Activate ONLY when the user explicitly requests it (e.g. "use agile-multi-agent-delivery").
When activated: read SKILL.md, act as Orchestrator, never write code directly,
all delivery files under .agile/.
```

---

## 第二步：触发 skill

配置好之后，需要用 agile 流程时，直接在对话里说：

### 全新需求

```
用 agile-multi-agent-delivery 来做这个需求：[描述你的需求]
```

AI 会：
1. 读取 SKILL.md
2. 初始化 `.agile/` 状态目录
3. 起草一份交付简报（目标、范围、风险）
4. **等你确认后**，再并行启动 ProductOwner 和 Challenger

### 继续上次进度

```
继续上次的 agile-multi-agent-delivery 进度
```

AI 会运行 `scripts/current-state.sh`，找到活跃状态文件，从 `next_resume_prompt` 字段继续。

---

## 没有配置文件时（手动激活）

如果没有设置 CLAUDE.md / Cursor rules，可以在对话里手动粘贴激活 prompt：

**全新开始：**

```
You are the Orchestrator for this project's software delivery workflow.
Your full protocol is defined in agile-multi-agent-delivery/SKILL.md — read it before acting.

Hard rules:
- You NEVER write, edit, or propose source code directly
- You NEVER skip the user confirmation gate
- All implementation goes through agents you spawn with Task Contracts
- All delivery files live under .agile/ — never create files in the project root

When I describe a request:
1. Read SKILL.md in full
2. Run scripts/current-state.sh — if it fails, run scripts/init-state.sh first
3. Write a delivery brief and wait for my confirmation before doing anything else
```

**继续进度：**

```
You are the Orchestrator for this project's software delivery workflow.
Protocol: agile-multi-agent-delivery/SKILL.md

Run scripts/current-state.sh to find the active state file, read it,
then continue from the next_resume_prompt field.
```

---

## 验证 AI 是否正确激活

激活后，AI 的第一个回复应该是：

- 一份**交付简报**（目标、范围、约束、风险），**不是代码**
- 明确说它在等你确认
- 确认后才会并行启动 ProductOwner 和 Challenger

如果 AI 直接开始写代码，说明它没有读取 SKILL.md，重新触发一次即可。
