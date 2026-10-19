---
title: "数学 × AI 周报 · 第 09 期：55 万行 Lean 五天写成，DeepMind 的 Erdős 账被审出一笔，OpenAI 出钱请数学家来读"
date: 2026-10-19 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 9
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - DeepMind
  - AlphaProof Nexus
  - Erdős 问题
  - Lean
  - 形式化验证
  - OpenAI
  - Simons 基金会
description: >-
  第 09 期：上海人工智能实验室称其模型协助解决三维 Ghys 猜想，北大团队给出约 55 万行 Lean 证明；DeepMind 的 AlphaProof Nexus 在 Science 发表，解决 9 个形式化 Erdős 问题，独立审计把数字改成 8；OpenAI 与 Anthropic、Simons 基金会共设 1500 万美元倡议，帮数学家读懂 AI 的结果。
image:
  path: /assets/img/posts/math-ai-weekly-09/cover.png
  alt: "数学 × AI 周报 第 09 期封面（AI 生成）"
---

> **本期一句话**：上周的问题是"机器交卷太快，谁来验"。这周有了三个回应。有人把证明写到 55 万行，有人在自己的战绩表上被审出一笔，有人开始出钱，请数学家来读。写的速度已经不稀奇，读的能力才是稀缺品。
{: .prompt-tip }

---

## 上海 AI Lab：三维 Ghys 猜想，55 万行 Lean

**10 月 14 日**（周三），上海人工智能实验室宣布，其"书生"Shusheng-S2 大模型参与的团队解决了三维 Ghys 猜想。这个猜想由 Étienne Ghys 在 1995 年提出，说的是紧致复流形上的全纯 Anosov 微分同胚，是否共轭于复无穷小幂零流形上的仿射自同构，二维情形他自己证过。据报道，预印本作者是瑞典皇家理工学院的张介松，Xu Disheng 为学术指导；北京大学的董彬、刘若川团队用 SHEAF 框架做形式化，约 55 万行 Lean 代码，耗时约五天，动用多达 100 个 AI 智能体，覆盖四个主要定理。实验室称这项工作从 8 月开始，迭代七轮，证明图从 15 个节点长到 389 个。

需要打折扣的地方：这些细节几乎都来自实验室自己的说明和单一媒体转述，我没有找到数学界的独立评议。模型本身不对外开放，外人能检查的是 Lean 文件，复现不了 AI 的过程。论文编号各处说法不一，这里不引。

**解读**：55 万行是个吓人的数字，但数字越大，"Lean 证的是不是原来那句话"这个问题越难查。Lean 能保证推出来了，不能保证问对了。

> 来源：[TechTimes 报道](https://www.techtimes.com/articles/329134/20261016/chinese-ai-model-helps-prove-31-year-old-math-conjecture-machine-verified-lean-proof.htm)（单一二手来源，细节待独立确认）

---

## DeepMind 的 Erdős 战绩表，被审出一笔

据报道，**10 月 8 日**，Google DeepMind 的 AlphaProof Nexus 在《Science》发表：在 353 道已形式化的 Erdős 问题上解决了 9 道，其中两道开了五十多年；在 492 条选定的 OEIS 猜想里解决了 44 条。系统每题最多跑 3000 个回合，找不到证明就停。验证有几道关：证明里不许有 `sorry`，原命题不许被改，用 SafeVerify 防公理注入，在隔离的 Docker 沙盒里编译，Lean 文件公开，谁都能重新构建。（这条比本期时间窗早几天，我是在 10 月 13 日的报道里看到的，上期没有收。）

随后有独立审计指出：第 846 题的 Lean 证明没有问题，但 Reiher、Rödl、Sales 的一个旧定理翻译过来已经蕴含了它。按更严格的"新解决"定义，9 就变成 8。证明没错，只是不算新。

另外，系统本身不公开，只放出结果。评论者说它在形式化库成熟、问题能拆成子目标的领域，比如组合和数论，最顺手，并不是通用的自动数学家。

**解读**："证明对"和"问题真是新的"是两回事，Lean 管不了第二件。第二件靠的是熟悉文献的人，也就是读的人。

> 来源：[MLQ 报道](https://mlq.ai/news/google-deepminds-alphaproof-nexus-solved-nine-formalized-erdos-problems-science-paper-shows/) · [arXiv:2605.22763，DeepMind 论文预印本](https://arxiv.org/pdf/2605.22763)

---

## OpenAI 出 500 万美元，请数学家来读

**10 月 15 日**，OpenAI 宣布向 Simons 基金会的一项新倡议捐出 500 万美元，用来帮数学家检视、理解并在此基础上继续研究 AI 生成的结果，钱将用于研讨会、会议和专项项目，OpenAI 还会向基金会资助的研究者提供模型和算力。据报道，这项倡议由 Simons 基金会、Anthropic 与 OpenAI 共同出资，合计约 1500 万美元，各方具体份额各家报道说法不一。

背景是上周的风波。数学家组织"人类数学协会"（Association for Human Mathematics）批评 OpenAI，称"数学家并没有要求做这件事"，并指控其无视科研规范，还提到有两位数学家称自己快做出类似的 Navier–Stokes 结果，质疑 OpenAI 是否参考了他们的工作，OpenAI 否认见过。另外，有报道和个别网页提到"二十多位菲尔兹奖得主联名信"，我只在低质量来源里见到，没有找到可靠出处，这里不采信。

**解读**：钱解决不了"读不过来"，但这笔钱的去向很说明问题：不是买更多的证明，是买更多的读者。

> 来源：[Euronews 报道](https://www.euronews.com/2026/10/16/openai-tries-to-solve-mathematician-backlash-problem-by-pledging-5-million-to-math-foundat) · [OpenAI：Sharing AI progress in mathematics](https://openai.com/index/sharing-ai-progress-in-mathematics/)

---

## 把这一周连起来看

三条放在一起，是一个很整齐的对子。一边是写：55 万行 Lean，五天；353 道题，一遍扫完。一边是读：独立审计翻出一个旧定理，让 9 变成 8；基金会拿出钱，为的是让人看懂。机器会算，不等于证得了。证得了，还得有人确认这是那个问题，是个新结果，是一个人能带走的理解。写的成本在往零走，读的成本没有。所以"证"越来越值钱。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 09 期。
