---
title: "数学 × AI 周报 · 第 10 期（本周速递）：4310 万行 Lean 把「巨大定理」过了一遍，OpenAI 那批手稿还在被一篇篇读"
date: 2026-11-02 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 10
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - Axiom
  - 有限单群分类
  - Lean
  - 形式化验证
  - OpenAI
description: >-
  第 10 期（本周速递）：Axiom 称完成有限单群分类定理的 Lean 形式化，约 4310 万行、24 天，并报告了对原文献的 34 处偏差；OpenAI 十月初那批 AI 数学手稿，仍在被审、被撤、被补。本周料少，只出三条短讯。
image:
  path: /assets/img/posts/math-ai-weekly-10/cover.png
  alt: "数学 × AI 周报 第 10 期封面（AI 生成）"
---

> **本期一句话**：本周大新闻只有一件，而且是个"读"的故事：一个一万五千页的证明，被机器逐行重写了一遍，最值钱的产出不是"它对"，而是"它哪里不对"。其余从简，这一期是轻量版。
{: .prompt-tip }

---

## Axiom：有限单群分类，4310 万行 Lean

**10 月 27 日**前后，Axiom Math 宣布发布"有限单群分类定理（CFSG）的第一份完整的、经计算机检查的证明"。这个定理俗称"巨大定理"，原始证明散在数百篇论文里，常被说成约一万五千页。据 Axiom 自述：形式化约 4310 万行 Lean 代码，约 205 万条声明，覆盖 715 篇论文与书籍，耗时 24 天，由几十个 AI 智能体在工程师和数学家指挥下完成。仓库声称无 `sorry`，只用标准公理，不依赖 `native_decide`。

要打折扣的地方：这些数字来自 Axiom 自己的说明和二手转述，我没有看到第三方的独立复核。项目元数据把审查标为自评。形式化的是"第一代证明"，不是那份尚未完整的第二代。他们也承认早期有里程碑建在未经证明的前提上，几万行代码被删掉重来。Lean 的内核能保证"推出来了"，不能保证"陈述和原定理是同一句话"，后一步仍要懂群论的人来读。

**解读**：数字很大，但真正的信息量在检查之外：这个证明能被检查，是因为有人把它从头到尾读过了，只不过这次是机器在读。

> 来源：[Unite.AI 报道](https://www.unite.ai/axiom-math-releases-43-1m-line-lean-proof-of-group-classification/) · [Axiom 官方说明](https://axiommath.ai/research/the-enormous-theorem-formalized/) · [GitHub 仓库](https://github.com/AxiomMath/CFSG)

---

## 机器读出来的：34 处偏差

形式化的副产品是勘误。Axiom 称对照已发表的文献，共记下 34 处值得一提的偏差，从笔误、缺失的假设，到需要重新推导的实质问题。最大的一处在"不平衡群定理"（UGT）周围：据称智能体找到了 Aschbacher–Smith 准薄群卷中一条引理的反例（涉及 SL₂(5)），也找到了 Walter 1986 年专著中一个闭包断言的反例。Axiom 说这些并不推翻 UGT 本身，修补用到了他们的 AxiomProver 产出的一个新结果，后来又找到了一条更短的推导。勘误仍在整理，细节以他们的勘误页为准。

另有报道转述项目成员 Ilin 的话：真正懂这套证明的人，还在活跃的已经很少。

**解读**：几十年没人从头读完的证明，里面有几处不对，不奇怪。有意思的是修补它需要的，仍然是 Solomon、Lyons 这样的老人，在场，点头。

> 来源：[Axiom 勘误页](https://cfsg.axiommath.ai/errata) · [Unite.AI 报道](https://www.unite.ai/axiom-math-releases-43-1m-line-lean-proof-of-group-classification/)

---

## OpenAI 十月那批手稿：还在审

这条不在本周窗口内，是补一个后续。**10 月 6 日**，OpenAI 公布一批由未发布内部模型生成的数学手稿，报道数字是 722 篇、372 组结果，涉及几何、代数、数论和理论计算机科学。**10 月 7 日**，因一处符号错误，三篇被撤回（一篇被推翻，另两篇依赖它）。OpenAI 另设了由普林斯顿高等研究院承办的数学与 AI 咨询组。据二手来源，截至 10 月上旬只有约四成的主要结论有 Lean 检查，另有报道称有研究者发现某个 Navier–Stokes 相关结果的 Lean 代码与英文证明对不上。后两点我没有在一手来源核到，仅作线索，请谨慎对待。

**解读**：一次发布，一周内就有撤稿。比起"AI 写了多少"，更该看的是"多久能被发现错了"。

> 来源：[Resident 报道](https://resident.com/tech-and-gear/2026/10/31/ai-challenges-mathematics-openai-research) · [OpenAI：Sharing AI progress in mathematics](https://openai.com/index/sharing-ai-progress-in-mathematics/)

---

## 把这一周连起来看

三条说的是同一件事。机器能把一万五千页重写成 4310 万行，能一周交出几百篇手稿，写已经不是难处。难的是读：确认陈述没变，确认前提站得住，确认错处被人看见。这周最有分量的产出是那份勘误，和那几篇被撤回的手稿，都是"读"出来的。机器会算，不等于证得了。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 10 期。
