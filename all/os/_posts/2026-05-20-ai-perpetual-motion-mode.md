---
layout: post
title: "我把开发搬到了手机上 —— AI 永动机模式的第一线笔记"
date: 2026-05-20
author: Max (Ma Wei)
location: Singapore
series: AI-Native Engineering
part: 1
categories: [AI-Native Engineering]
tags:
  - AI-Native Engineering
  - Claude Code
  - GitHub
  - Agent Workflow
  - Vibe Coding
  - MCP
description: 一个项目一台手机,几台 Claude Code session 并行跑,一台手机专门看 TestFlight —— 这不是炫技,是 AI 永动机模式下避免上下文切换的必然选择。本文记录我在新加坡探索 AI-native engineering 工程体系的第一线观察,以及 GitHub 把我的 Claude 限流之后,我重新设计的整套交互机制。
---

> 本文是 **AI-Native Engineering** 系列的第一篇。
> 系列目标：为正在用 AI agent 重构软件工程实践的开发者，沉淀一套底层方法论。

---

## 写在最前面

如果你只想看结论，先记住三句话：

1. **Vibe Coding 阶段的代码，是 stateless 的**。
2. **永动机的瓶颈，不在 AI，在它脚下踩的那一代工具栈**。
3. **AI 不取代程序员，AI 取代的是为程序员设计的工具栈**。

剩下的，是论证。

---

## 一、一个奇怪的开发画面

我现在的开发方式，可能你没见过。

**桌上摊着几台手机，每台跑一个项目的 Claude Code session。还有一台单独留着 —— 专门看 TestFlight。**

之前我重度用 ghostty + fish + Claude Code CLI，全在本地终端。

但当我开始同时跑多个项目、用 agent team 的方式并行开发之后，本地终端这套范式开始崩。

不是不能跑，是**人的注意力不够用**。

切换工程 = 切换上下文 = 切换 agent 的记忆 = 切换我自己的脑回路。

后来我换了一种方式：**一个工程，一台手机**。

每台手机上 Claude Code 常驻前台，永远在那里，我伸手就能交互。

像几个独立工位，每个工位上坐着一个 Claude，各干各的。

我在新加坡。目前主要的精力，放在一件事上：

> **AI 时代的开发新范式和工程体系，应该长什么样。**

这篇文章，是我的第一线观察笔记。

---

## 二、为什么是多台手机

这是被问得最多的问题，先回答。

### 2.1 核心原因：不想在 Claude Code 里来回切工程

如果一台设备跑多个 session，每次切换：

- Claude 的上下文要重新拉
- agent 要重新理解你刚才在做什么
- 你自己要在脑子里切语境

**人在切换、AI 也在切换。两边一起变笨。**

这是上下文切换在 AI 协作时代被放大的版本。

人类开发者切窗口已经够伤效率，何况现在每个"窗口"背后都有一个 agent 在加载它自己的工作记忆。

所以规则简单粗暴：**一个工程，一台手机**。

### 2.2 每台手机不是开发机，是遥控器

这一点要讲清楚 —— **手机本身没在做开发**。

Claude Code 跑在云端环境。代码、build、测试、deploy 全在云上。

**手机只负责：**

- 显示当前 session 的状态
- 接收我的指令、转给 Claude
- 把 Claude 的输出推回我眼前

云端在干活，手机在伸手指挥。

就这两件事。

### 2.3 那台特别的手机：产品验证窗口

桌上还有一台手机，**不跑 Claude，专门看 TestFlight**。

我们在 [NGMOB](https://ngmob.com) 做 AI 产品，比如 [Kolens](https://kolens.ai) 和 [GoGlow AI](https://goglowai.com)。

Claude 写完代码 → CI/CD 跑完 → 新版本自动推到 TestFlight。

那台手机一直挂着 TestFlight。

新版本一到，我点更新，**立刻看到 Claude 刚才那一小时干了什么**。

**写代码的手机在产、看产品的手机在验** —— 整个永动机的闭环，就在我这张桌子上跑通了。

---

## 三、第一性原理：state 和 stateless

讲完画面，回到底层逻辑。

### 3.1 一个反直觉的判断

> **Vibe Coding 阶段的代码，是 stateless 的。**

传统开发里，代码是 stateful 的。

每一行都"重要" —— 因为是人写的，凝结了思考。

所以我们 commit 它、review 它、保护它、为它写测试、用 Git 把它的每一次变更记录在案。

Vibe Coding 模式下不是这样。

**Claude 写出来的代码，在交付之前，随时可以被丢弃。**

它没有"作者权威"。它的存在意义只有一个 —— **能不能跑到 production，产生实际价值**。

跑不到的代码，无论写得多漂亮、注释多完整，**就是 stateless 的中间产物**。

### 3.2 工程体系的设计逻辑因此反转

这个认知一旦确立，整套工程体系的设计逻辑全部反过来：

| 维度 | 传统开发 | AI 永动机模式 |
|---|---|---|
| **核心资产** | 代码 | **交付通路** |
| **凭证** | commit | issue |
| **review 保护的是** | 代码质量 | **意图正确性** |
| **协作单元** | PR | **产品功能** |
| **节奏哲学** | 慢工出细活 | **永动 + 闭环验证** |
| **版本控制目标** | 还原历史 | **追溯意图** |

这张表，值得多看两遍。

它不是"传统开发不好"。

它是 —— **当代码的生产方式变了，围绕代码建立的整套秩序，都得重新对齐**。

### 3.3 "stateless 代码"如何被丢弃

举个例子。

我让 Claude 在一个 feature branch 上实现一个功能。它在云端 session 里改了 40 个文件，跑了 100 次测试，中间生成了 5 个版本的实现方案。

**这 5 个版本里，4 个会被它自己丢掉。**

只有最后一个能跑通、能通过验收的版本，才会被 push 出来。

中间那 4 个版本，既没进 GitHub，也不需要任何人记得它们存在过。

它们是真正的 stateless 中间态 —— **只在 Claude 的 session 内存里短暂存在**。

这种丢弃，在传统人类协作里是不可想象的。

你能想象一个程序员说"我今天写的代码大部分都不要了"吗？

但对 agent 来说，这是默认行为。

**这就是 Vibe Coding 和传统编程在数据语义上最深的分野。**

---

## 四、整套范式的样子

把所有东西放到云端，沿用现有工程体系，但重新分配每一层的角色。

### 4.1 第一层：GitHub 是基石，但 issue 比代码重要

GitHub 当然存代码。

但在我这套体系里，**GitHub 真正承担的是 issue**。

所有开发任务都和 issue 绑定：

- 任务描述
- AI 的思考过程
- 解决方案对比
- 实现笔记
- 测试验收记录
- 失败原因和重试策略

全部沉淀在 issue 里。

**issue 才是知识库。代码只是 issue 的一个输出物**。

这个反转很重要。

因为代码会随产品演化不断重写，但 issue 里"为什么这样做"的推理过程，**永远不会过期**。

未来新的 agent 接手项目时，它读的不是代码，**是 issue 历史**。

### 4.2 第二层：Claude Code session 全部用 cloud 环境

不在我本地。不在我手机上。

云端环境意味着：

- 不依赖任何一台设备
- 多个 session 真正并行
- 一组功能写完，**直接开新 session 保持智商在线**

最后这条特别重要。

长 session 会因为上下文堆积越来越笨 —— 这是当前 LLM 的本质限制。

所以**主动关掉旧 session、开新 session**，本身就是工程纪律的一部分。

每个 session 像一个一次性容器：

进来时干净，做完一件事，丢掉，下一个。

### 4.3 第三层：交付通路必须在第一天就闭环

这是整套范式最容易被忽略、但最致命的一环。

**Vibe Coding 跑得再快，代码不能 deliver 到 preview / production / TestFlight，就全是 stateless 垃圾。**

所以项目启动第一天就要把：

- GitHub Actions deploy 通路打通
- Cloudflare / Vercel / Railway / Fly.io 任选一个，让服务可发现、可到达
- 移动端项目把 TestFlight / Internal Testing 自动推送也打通
- 如果 API 还能同步暴露成 **MCP**，**永动机的第二个轮子就成立了**

最后一条解释一下。

**MCP 在这套体系里的角色，不是开发工具，是产品的运行时接口。**

当你的产品本身的服务能被 MCP 调用，Claude 就能**用 MCP 模拟 vibe coding 下用户和产品的交互** —— 自己测自己写的东西。

比如我们产品的图像生成 API、订阅校验 API、用户档案 API，如果都暴露成 MCP，Claude 在 cloud session 里写完代码，就能直接通过 MCP 模拟一个用户跑一遍流程。

写 → 验证 → 修 → 再验证，**不用我介入**。

这才是永动机的第二个轮子。

---

## 五、为什么叫"永动机"

把上面几层串起来，工作流是这样：

```
  issue (任务 + 验收标准)
       │
       ▼
  cloud Claude Code session (写代码)
       │
       ▼
  GitHub (push, PR)
       │
       ▼
  CI/CD (deploy 到 preview / TestFlight)
       │
       ▼
  ┌─────────────────────────────────┐
  │  MCP 调用 preview 服务 (自动验证) │
  │  或 我拿起 TestFlight 那台手机   │
  └─────────────────────────────────┘
       │
       ▼
  回 issue 汇报 → 关 issue or 开下一个
       │
       ▼
  新 session 开始下一个任务
       │
       └────────────► 循环
```

**整个循环里，人只在两个地方介入：**

1. **起点** —— 写 issue（定义意图）
2. **终点** —— 合并 PR / 验收 TestFlight 版本（确认价值）

中间全自动。

所以叫 "AI 驱动的开发永动机"。

我可以一边喝咖啡，一边在桌上的几台手机之间瞄一眼每个项目的进度。

写代码那几台，Claude 在敲。

看 TestFlight 那台，新版本一会儿就到。

**像盯着几条传送带，每条尽头摆着一个成品。**

---

## 六、然后我撞墙了

这就是这篇文章真正的触发点。

并行开发 + 快速迭代，触发了 **GitHub 的 rate limit**。

不是 commit 太多。

是**整个 API 调用模式被 GitHub 的 abuse detection 系统判定不像人**。

错误信息很简单粗暴：

> `API rate limit exceeded. You have triggered an abuse detection mechanism.`

那一刻我盯着屏幕，意识到一件事：

**GitHub 在保护自己，免受我的 AI 攻击。**

### 6.1 GitHub 的速率上限，是按"人"画的

GitHub 的 abuse detection 是基于 2008 年的假设设计的：

- 一个开发者一小时发多少 API 请求 = 有上限
- 一个账号在多个 repo 上并行操作 = 有上限
- 短时间大量自动化行为 = 触发反 abuse

这些上限，对人来说足够宽，**对 agent 来说瞬间撞墙**。

**GitHub 2008 年画的天花板，是给"全世界最勤奋的程序员"留的。**

**而这个天花板，今天一台手机上的一个 Claude session，一上午就能撞到。**

更荒诞的是 —— 没办法和 GitHub 申诉说"这是我的 AI"。

它根本没设计这个场景。

它假设了一个不存在的人。

### 6.2 这件事的真正含义

撞墙之后，我反复在想：

为什么是 GitHub 先崩，而不是 Claude？

Claude 没有变慢、没有变笨、没有报错。

**崩的是它脚下踩的工具栈。**

Git 是为人设计的。

GitHub 是为人设计的。

CI/CD 的触发逻辑是为人设计的。

甚至 abuse detection 都是为人设计的。

**AI 跑得越快，越早撞上这些 2005、2008 年留下来的假设。**

这才是 AI-Native Engineering 这个话题真正的起点 ——

不是"如何用 AI 写代码更快"，

而是 **"为人设计的工具栈，如何承载非人的协作者"**。

---

## 七、于是我重新设计了 AI 和 GitHub 的交互机制

撞墙之后，我把规则沉淀成了一份规范。

核心思路就一句话：

> **减少 API 调用频次，比减少提交数量重要 10 倍。**

（为什么是 10 倍？因为 GitHub 的限流是按 API 调用数算的，不是按 commit 数。
一个 commit 可能背后就是 3-5 次 API call；一次自动化 PR 检查可能是 20+ 次 API call。
优化 commit 数能省 30%，优化 API 调用模式能省 90%。）

下面这套规则，是我目前在用的核心条款。完整版下一篇会单独发，这里先列骨架。

### 7.1 修改和提交解耦

Claude 在 feature branch 里**随便改、随便跑、随便测试**，

但绝大多数操作**不打 GitHub API**。

只在功能完整时，**一次性 push + 一次性开 PR**。

具体做法：

- 关闭所有 auto-commit / auto-sync / auto-push 工具
- Claude 的 session 内部维持本地 working tree，只在 milestone 时同步到远端
- 如果用 cloud Claude Code，确认它的默认行为是"任务完成才 push"

### 7.2 PR 是"产品功能"单元，不是"任务"单元

不再是一个任务一个 PR。

而是 —— **一个产品功能一个 PR**。

把 PR 从"工作单元"还原成"协作单元"。

判断标准：这个 PR 合进 main 之后，**用户能感知到一个完整的价值变化吗**？

能 → 这是一个合理的 PR。

不能 → 还在做中间态，继续在 feature branch 上叠。

### 7.3 CI 不绑 push，也不绑每个 PR，绑"准备 merge"

PR 开着的时候，**不跑 CI**。

只有人类（或者另一个有 review 权限的 agent）点了"这个可以合"，CI 才开始跑。

GitHub Actions 配置上长这样：

```yaml
on:
  pull_request:
    types: [ready_for_review]
  workflow_dispatch:
```

**把 99% 的"中间状态 build"挡在账单之外。**

### 7.4 Production deploy 必须人工触发

main merge 不触发生产部署。

Production 部署用 `workflow_dispatch`，**必须有人按那个按钮**。

每天按一次，把 100 次部署批量合成 1 次。

```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true
```

理由：**生产环境的稳定性，不能由 AI 的迭代速度决定**。

### 7.5 issue 是 AI 思考的容器

issue 不是 todo list。

issue 是 agent 的**工作记忆持久化层**。

每个 issue 应该包含：

- **意图** —— 这件事为什么要做（用户价值 / 业务驱动）
- **验收标准** —— 怎么算做完（可被 MCP 自动验证 ✓）
- **方案对比** —— Claude 提出的几种实现路径
- **关键决策** —— 选了哪个、为什么
- **失败回放** —— 中途哪些方案试了不行、原因
- **链接** —— PR / preview URL / TestFlight build

这套 issue 写法，**让任何一个新 agent 接手都能从零理解上下文**。

这就是把 issue 当知识库的意思。

---

## 八、AI Agent 行为约束清单

这是我从踩坑里总结的、专门给 cloud Claude Code session 用的行为约束。完整版会在第二篇展开，这里给最重要的几条：

- [ ] **AI 不允许直接操作 main 分支**（`git checkout main` / `git push origin main` 一律禁止）
- [ ] **所有 AI 修改走 `ai/<feature-name>` feature branch**
- [ ] **强制 squash merge**（GitHub repo settings 里关掉 merge commit）
- [ ] **commit message 必须是 Conventional Commits 格式**（`feat:` / `fix:` / `refactor:` 等）
- [ ] **禁止生成 `update` / `fix` / `wip` / `asdf` 这类垃圾 message**
- [ ] **AI 修改前必须搜索已有实现**（避免重复 component / util / schema）
- [ ] **AI 不允许无限循环修复** —— 限制 retry 次数，失败必须输出原因 + 请求人工介入
- [ ] **禁止 polling 模式**，所有 agent 行为必须 event-driven / webhook-driven / queue-driven
- [ ] **数据库 migration 用 direct connection，运行时用 pooled connection**（Neon / Supabase 等）
- [ ] **AI 不允许频繁 migration** —— 聚合 schema 修改，统一执行

完整 16 章规范，下一篇见。

---

## 九、这只是兼容层

说实话，上面这套规则只是**临时方案**。

Git 和 GitHub 本身就不适合 agent。

未来真正的方向，我观察到的几个明显趋势：

### 9.1 Semantic Diff

不看代码差异，看**意图差异**。

两个版本之间真正变了什么 —— 不是 +12 行 -8 行，而是"加了支付功能"或"修复了订阅校验逻辑"。

### 9.2 AST Diff

结构变化，而不是文本变化。

`if (a) b()` 重构成 `a && b()` 在文本 diff 里是大改动，在 AST diff 里是零变化。

AI 写代码倾向于这类语义等价的重写，**文本 diff 在 AI 场景下信噪比极低**。

### 9.3 Intent-Driven Version Control

一个版本 = 一次产品意图，而不是一次代码修改。

版本号、changelog、回滚单元 —— 都按产品意图组织，不按 commit 组织。

### 9.4 Agent-Native Code Host

默认用户是 agent fleet，不是人。

- rate limit 按"任务"而不是"API call"算
- review 流程为 agent 协作设计
- PR description 默认结构化、可被另一个 agent 解析
- 限流的对话是"申明你的 agent"，而不是"被当成 abuse"

### 9.5 MCP-First 的产品架构

产品**天然能被 AI 调用、被 AI 测试、被 AI 演化**。

未来一个合格的 SaaS 产品，API + MCP server 是默认配置，**就像今天的 REST + OpenAPI 一样**。

---

**当 agent 写的代码占比超过 80%，我们需要的不是更好的 Git，而是不一样的版本控制范式。**

这个范式今天还没有人做出来。

但**谁先做出来，谁就是下一代 GitHub。**

---

## 十、最后

很多人在讨论：AI 会不会取代程序员。

我觉得这个问题问错了。

真正在发生的是：

> **AI 不取代程序员，AI 取代的是为程序员设计的工具栈。**

GitHub 把我的 Claude 限流的那一刻，我看到了这个未来。

接下来是 CI/CD。

然后是 IDE。

然后是 issue tracker。

然后是文档系统。

然后是 cloud console。

**一整代基础设施，都要重写。**

而我在新加坡，桌上摊着几台手机 —— 几台是 Claude 的工位，一台是产品的窗口 —— **正好站在分水岭上**。

我们撞墙，是因为我们走得最前。

---

## 系列预告

这是 **AI-Native Engineering** 系列的第一篇。

后续计划：

- **#2** 完整版《AI Agent Git / GitHub 开发规范》—— 16 章实操手册，可直接 fork 的 GitHub 设置模板
- **#3** 为什么传统软件工程不适合 AI Agent —— 从 stateful 到 stateless、从 request-driven 到 event-driven 的范式跃迁
- **#4** 未来的软件不是 App，而是 Intent System —— 从 UI 设计到 intent 设计的认知升级
- **#5** AI-Native Engineering 总纲 —— 把这套方法论收口成一个完整的工程哲学

---

## 关于作者

Max（@maweis1981），独立开发者，[NGMOB](https://ngmob.com) 的 founder（旗下产品包括 [Kolens](https://kolens.ai) 和 [GoGlow AI](https://goglowai.com)）。

目前在新加坡，在 NGMOB 用 AI 永动机模式做 AI 产品，同时研究 **AI-Native Engineering** 的工程体系演化。

- 个人站：[maweis.com](https://maweis.com)
- GitHub：[github.com/maweis1981](https://github.com/maweis1981)

> 如果这篇内容对你有启发，欢迎在 GitHub Star 系列文档、转给同样在前线探索的朋友。
> 文章会同步发布到微信公众号 和 [Medium](https://maweis.com)。

---

*Copyright © 2026 Ma Wei. Licensed under CC BY 4.0.*
*Feel free to quote, translate, and reference — please link back.*
