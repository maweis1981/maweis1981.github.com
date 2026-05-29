---
title: "Agentic AI 还是 Agentic Workflow？"
date: 2026-05-22 10:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: AI-Native Engineering Notes
categories: [AI-Native Engineering, Notes]
tags:
  - AI-Native Engineering
  - Agentic AI
  - Agent SDK
  - LangChain
  - OpenAI
  - Vendor Lock-in
  - GovTech Singapore
description: >-
  GovTech Singapore 一篇 27 分钟 Agent SDK 评测：
  OpenAI / Google / AWS / Microsoft / LangChain 五家横向对比，
  从设计模式、HITL、互通性到 vendor lock-in 五维度。
  读完最关键的两个判断：Agentic AI 不是二选一的标签、是每一个决策点的属性；
  真正的 lock-in 不在 LLM 层，在运维、数据、评估三层。
media_subpath: /assets/img/posts/agentic-ai-vs-workflow
image:
  path: cover.png
  alt: "Agentic AI 或者 Agentic Workflow？一字之差，工程难度差几个数量级"
---

> 在做编排框架之前，我读了一篇新加坡政府发的文章。

> **TL;DR**：**Agentic AI**（运行时由 LLM 自主决策）和 **Agentic Workflow**（预先 if-else）是两件事，工程难度差几个数量级；很多团队在做 Workflow 却自称在做 Agentic AI。原文拆了 **6 种 agent 工作流**（Sequential / Planner-Decider / DAG / Supervisor-Worker / Broadcast / Agent-as-Tool）和 **4 种 HITL 模式**，并提醒一件事：**SDK 真正的 vendor lock-in 不在 LLM 层，在运维、数据、评估三层 —— 而这恰恰是你最后才会想到要换的层**。
{: .prompt-info }

⸻

最近因为在做一个 orchestration framework(一个调度多个 AI agent 协同工作的系统),开始严肃看市面上的 Agent SDK 选型。

我在新加坡。前一阵刷 Medium 的时候,刷到一篇 2025 年 9 月发布的评测文章 ——

[**Building for Agentic AI — Agent SDKs & Design Patterns**](https://medium.com/dsaid-govtech/building-for-agentic-ai-agent-sdks-design-patterns-ef6e6bd4a029)

作者是 **GovTech Singapore**(新加坡政府科技局)AI Practice 团队的 Ryan LIN。一共 27 分钟阅读时长,把 OpenAI、Google、AWS、Microsoft、LangChain 五家的主流 Agent SDK 横向对比了一遍 —— 从设计模式、Human-in-the-Loop、互通性、可观测性、生态锁定五个维度,毫无保留。

读完之后我做了两件事。

**第一,**写一份读书笔记,把对 orchestration framework 选型最关键的几个判断提炼出来分享给中文圈做相关工作的人。这就是这篇文章。

**第二,**我想专门说一下 —— **政府部门做出这种深度技术评测,并公开发布,本身就是一件值得致敬的事**。

⸻

## 先说说为什么这件事值得说

我自己在新加坡生活和做事这几年,慢慢观察到一个特点 ——

**新加坡政府对待"工程实践"的态度,和大多数国家不一样**。它把工程方法论、技术评测、架构选型这些东西,当成**可以、应该、值得公开分享的公共资产**。

具体到这篇文章 ——

- 它不是 marketing。没有推销任何一家厂商,反而把每一家的 vendor lock-in 风险都直接列出来
- 它不是学术论文。文笔朴实、表格清晰、例子具体,任何工程师都能直接拿来用
- 它不是个人 blog。挂在 GovTech 官方 publication 下,代表的是一个**国家级技术机构**的判断
- 它没有任何"高高在上"的说教味。每一个观点都有出处、有引用、有对比

**让我感慨的是 —— 一个政府部门,愿意花时间把内部团队踩坑总结出来的经验,认真整理、公开发布、不收钱、不藏私**。

这种做法在大多数国家是稀缺的。

公共部门通常被认为"封闭"、"慢"、"不接地气"。但你读这篇文章,会清楚地感觉到:**它的作者就是在第一线写代码的人**,文章里的每一个 SDK 都真的部署过、每一个 workflow 模式都真的用过。

更重要的是 —— **它把"我们怎么选 SDK"这件事,做成了一份给整个开发者社区的公共资产**。

任何人 —— 不管在新加坡、中国、印度、还是非洲 —— 都可以读到这份评测,带走里面的判断,省掉自己几个月的踩坑。

⸻

这种"政府把工程方法论作为公共资产输出"的姿态,在我看来是新加坡数字化转型最值得学习的部分之一。

不是有多少预算、不是建了多少系统。**是一种"工程实践应该被分享、被讨论、被改进"的开放文化**。

致敬这位作者 Ryan LIN,致敬 GovTech Singapore 的 AI Practice 团队。

⸻

回到这篇文章本身的内容。下面是我读完之后,觉得最关键的几个判断 ——

⸻

## 一个被忽略的问题:你做的到底是 Agentic AI,还是 Agentic Workflow?

这是整篇评测里最有意思的区分。

很多人混着用这两个词,但它们其实**指向不同的东西**:

- **Agentic Workflow** = 工作流,每一步要走哪个分支、调用哪个 agent,是**预先定义好的**。决策路径是 if-else,是固定的图。
- **Agentic AI** = 自主决策的 agent 系统,它**动态决定**接下来要做什么、调用谁、走哪条路径。决策是运行时由 LLM 自己生成的,不是预先写死的。

这个区别非常关键,因为**它直接决定了你需要什么样的 SDK 能力、什么样的可观测性、什么样的安全边界**。

举个例子:

- 一个「PDF 处理流水线」:扫描 → OCR → 摘要 → 分类 → 归档。每一步都固定。**这是 Agentic Workflow。**
- 一个「客服处理系统」:根据用户问题,自己判断是查订单、还是退款、还是升级到人工。每次的路径都不一样。**这是 Agentic AI。**

这两种东西的工程难度差几个数量级。

**Agentic Workflow** 本质上是带 LLM 的传统工作流引擎。难度可控,结果可预测,调试相对简单。

**Agentic AI** 是真正的"自主决策系统"。难度大,结果不可预测,调试是噩梦 —— 因为你不知道它下一次会做什么决定。

⸻

很多团队声称自己在做 Agentic AI,**其实只是在做 Agentic Workflow**。

这不是贬义。Agentic Workflow 完全可以满足绝大多数业务需求,而且大概率比真正的 Agentic AI 更靠谱。

但**一开始就把自己定位错**,会导致:

- 选错 SDK(用了为 Agentic AI 设计的复杂 SDK 做简单流程)
- 设计错架构(给本该固定的流程加了不必要的"自主决策",反而引入不稳定)
- 评估错效果(用 Agentic AI 的指标评估一个本质上是工作流的系统)

**所以做编排框架的第一个问题,应该是 ——**

> **我要做的,是 Agentic AI,还是 Agentic Workflow?**

这个问题想清楚了,后面所有的选型都有依据。

⸻

## 六种 Agent 工作流的设计模式

原文整理了六种最常见的 agent 协同模式。我用最简化的方式讲一遍,方便你以后做架构设计时直接拿来用。

⸻

**1. Sequential Pipeline(顺序流水线)**

agent 排成一条线,前一个的输出是后一个的输入。

> 例子:PDF → 摘要 agent → 实体提取 agent → 分类 agent → 归档 agent。每一步建立在上一步基础上。

特点:简单、可预测、调试容易。
适用场景:步骤明确、不需要分支的固定流程。

⸻

**2. Planner-Decider(规划-决策模式)**

一个"协调员 agent"看到任务后,自己决定调用哪些 agent、按什么顺序。其他 agent 不互相调用,只听协调员的。

> 例子:用户上传一个文件,协调员先判断是图片(先 OCR)还是 PDF(直接读),再判断是合同(要走合规检查)还是发票(要走金额提取),最后归档。**同一个协调员可以处理完全不同的输入类型**。

特点:灵活、可处理多种输入。
适用场景:输入多变、需要动态判断的场景。

**这是 Agentic Workflow 和 Agentic AI 的分水岭** —— 如果协调员的"判断"是 if-else 写死的,就是 workflow;如果是 LLM 自己推理出来的,就是 Agentic AI。

⸻

**3. Graph / DAG(非线性图工作流)**

允许并行和合并。两个 agent 可以同时处理同一份输入,结果再汇总到下一个 agent。

> 例子:一份文档同时进入摘要 agent 和实体提取 agent(并行处理),它们的输出一起交给分类 agent。

特点:能并行、效率高。
适用场景:有些步骤可以并行的复杂任务。

⸻

**4. Supervisor-Worker(监督者-工人模式)**

一个"主管 agent"管着几个"工人 agent"。主管不只是分配任务,还会**审查工人的结果,不满意就让重做**。

> 例子:客服系统里,主管 agent 调用"意图分类"、"账户查询"、"知识库搜索"、"草拟回复"等工人 agent,最后还要让"质检 agent"审查回复,不合格就让"草拟回复 agent"重写。

特点:有质量控制、可以反复迭代。
适用场景:需要质量保障、可能要返工的任务。

⸻

**5. Broadcast / Federated(广播-联合模式)**

同一个请求**同时**发给多个对等的 agent,它们独立工作,最后由一个"聚合器"挑选最好的结果。

> 例子:你要订外卖,「协调员 agent」把同一个订单同时发给「美团 agent」、「饿了么 agent」、「商家直送 agent」,它们各自查菜单、报价、给出预计送达时间。协调员再挑最便宜或最快的。

特点:用并行换最优结果。
适用场景:需要"货比三家"、冗余、或速度优先的场景。

⸻

**6. Agent-as-Tool(agent 当工具调)**

一个主 agent 把另一个 agent **当成一个工具来调**。就像调用一个 API 一样 —— 输入参数、等结果、继续推理。

> 例子:聊天 agent 处理用户的"帮我订一个生日餐厅"请求。它把"找餐厅"这件事**当成一个工具**,调用一个专门的"餐厅查找 agent",拿到结果后继续主对话。**主 agent 始终保持对话上下文**。

特点:保持单线对话,但能调用多个专业能力。
适用场景:用户面对的是一个"主聊天界面",但背后有多个 agent 协作。

⸻

## 这六种模式对你的项目意味着什么

我看完之后的判断是:

**真实世界的 agent 系统,几乎都是混用这六种模式的。**

简单系统是一两种模式的组合。复杂系统会同时用上四五种。

但更关键的是 ——

**这六种模式里,只有少数几种是"真 Agentic AI"。** 大多数是 Agentic Workflow 加了 LLM 调用。

具体来说:

- **Sequential Pipeline** —— 通常是 Agentic Workflow(路径固定)
- **Planner-Decider** —— 看 planner 是不是 LLM 自主决策。如果是 if-else,是 workflow;如果是 LLM 推理,是 Agentic AI
- **Graph / DAG** —— 如果路径预先定义好,是 workflow;如果运行时动态生成,是 Agentic AI
- **Supervisor-Worker** —— 通常是 Agentic AI(主管的判断由 LLM 给出)
- **Broadcast / Federated** —— 如果"挑最优"是规则匹配,是 workflow;如果是 LLM 综合判断,是 Agentic AI
- **Agent-as-Tool** —— 主 agent 决定调用哪个工具 agent 时,如果是 LLM 推理,就是 Agentic AI

**所以「Agentic AI vs Workflow」不是一个二选一的标签,是每一处决策点的属性**。

一个真实系统里,可能 90% 的决策点是 workflow(写死规则),只有 10% 是真正的 Agentic AI(LLM 决策)。

**这恰恰是工程上比较健康的状态** —— 把 LLM 的不确定性,限制在真正需要它的地方。

⸻

## HITL(人在回路)的四种模式

agent 自动跑得越欢,「人什么时候介入」就越关键。原文整理了四种典型模式:

**1. Approve / Reject(审批模式)**:agent 在关键动作前停下,等人批准或拒绝。
*例子:分类 agent 决定把文件存到「合同/2025/Acme_MSA_2025.pdf」,让你确认路径再保存。*

**2. Review and Edit(审核和编辑)**:agent 出一个草稿,人来修改,修改后的版本继续向下传。
*例子:摘要 agent 写完一份摘要,人在上面加几个关键点,再交给下一个 agent。*

**3. Review Before Tool Call(工具调用前审核)**:agent 要调用敏感工具时,人来确认。
*例子:订餐 agent 要调用「下单」接口前,人确认一下「是这家餐厅吗」。*

**4. Multi-turn Conversation(多轮对话)**:人不是一次性批准,而是和 agent 持续对话调整需求。
*例子:订餐过程中,用户说「再帮我看看安静一点的」、「价格再低一点的」,agent 持续修正搜索条件。*

⸻

这四种模式合起来定义了一件事:

**你愿意让 agent 自动做多少?人在哪些环节必须介入?**

这是个产品设计问题,不是技术问题。但它决定了你的 SDK 选型 —— **不是所有 SDK 对 HITL 的四种模式都支持得一样好**。

⸻

## 一个被低估的维度:Vendor Lock-in(厂商锁定)

原文里有一段我反复看了几遍,是关于"vendor lock-in"的判断。

简单概括 ——

**每个 SDK 表面上都说自己「模型无关、平台无关」**。OpenAI Agents SDK 说自己支持 100 多种 LLM,Google ADK 说自己支持任何模型,AWS Strands 说自己能在 AWS 外部运行。

但 **lock-in 不是发生在「用哪个模型」这件事上,而是发生在你不知不觉用了它的整套生态**:

- 你用了 OpenAI 自带的 Traces 仪表盘做可观测性 → 你的运维就锁定了 OpenAI
- 你用了 AWS Bedrock 的 Knowledge Base 做 RAG → 你的数据层就锁定了 AWS
- 你用了 Google 的 Vertex AI Search 做 grounding → 你的检索层就锁定了 GCP
- 你用了 LangSmith 做评测 → 你的评估流程就锁定了 LangChain

**真正的 lock-in 不在 LLM 层,在运维、数据、评估这三层**。

而这三层,恰恰是**你最后才会想到要换的层**。

⸻

这件事让我想到一个更普适的判断 ——

**选择 SDK 的真实成本,不是它现在能做什么,而是你将来想离开它的时候有多痛**。

每一个 SDK 都让你免费用它的开源核心。但当你真的把业务跑起来,**自然就会用上它生态里的 5-10 个配套服务**。

每个配套服务都解决了你一个具体问题,省了你的时间。
每个配套服务都在悄悄增加你切换的成本。

这不是 SDK 的"阴谋"。这是**所有平台经济的自然结构**。

⸻

## 那到底该选哪个 SDK?

原文最后一节专门给了选型建议,我把它简化成一张表:

| 你的角色 / 场景 | 推荐 |
|---|---|
| **必须在 Microsoft 365 / Teams / Copilot 里跑** | Microsoft 365 Agent SDK |
| **AWS 重度用户,想用 Bedrock + Lambda** | AWS Strands SDK |
| **GCP 重度用户,想用 Vertex AI** | Google ADK |
| **想要原生支持 A2A 协议(agent 之间互通)** | Google ADK 或 AWS Strands |
| **要做实时语音、低延迟流式对话** | OpenAI Agents SDK |
| **要做可视化的复杂工作流图、TypeScript 支持** | LangGraph |
| **不在任何特定云生态里,想保持灵活** | 任意一个都行,主要看团队习惯 |

⸻

## 我自己的结论

我在做的 orchestration framework,本质上是一个比 SDK 高一层的东西 —— **不是替代某个 SDK,而是在 SDK 之上抽象一层,让我可以根据任务类型动态选择用哪个 SDK 的能力**。

读完原文,我对自己工作的判断更清晰了:

**第一,不要押注单一 SDK。** 每个 SDK 都有它的强项,也都有它的锁定风险。
**第二,把 Agentic Workflow 和 Agentic AI 在系统里清晰分开。** 不要在 workflow 的地方用 Agentic AI 的复杂度,也不要在 Agentic AI 的地方用 workflow 的死板。
**第三,HITL 不是技术问题,是产品问题。** 但产品决定要先于 SDK 选型。
**第四,最贵的不是 SDK 本身,是绑在 SDK 周边的生态。** 选型时把"如何离开"作为评估维度的一部分。

⸻

## 最后

再说一遍 —— 这份评测能存在,本身就是一件值得感谢的事。

不是每个国家的政府部门,都会把内部工程团队的踩坑经验,认真整理出来,公开发给全世界的开发者免费使用。

新加坡 GovTech 的这种姿态,是我在新加坡做事这几年最欣赏的一面。

把原文链接再贴一次,强烈建议做 agent 相关工作的人,自己也去读一遍:

**[Building for Agentic AI — Agent SDKs & Design Patterns](https://medium.com/dsaid-govtech/building-for-agentic-ai-agent-sdks-design-patterns-ef6e6bd4a029)** *by Ryan LIN, GovTech Singapore*

我自己读完之后做的事是 ——

**把这六种工作流模式、四种 HITL 模式,画成了一张图贴在我的工作日志里**。每次设计新功能,都会先对照一下:「我这个新功能,对应哪种模式?决策点是不是真的需要 Agentic AI?人介入的方式是哪一种?」

这套问题清单,比任何 SDK 的具体能力都更值得花时间想清楚。

⸻

*这一篇不在 AI-Native Engineering 主线里,算是一篇「读书笔记」番外。下一篇我会回到主线,写 #4 「未来的软件不是 App,而是 Intent System」。*
