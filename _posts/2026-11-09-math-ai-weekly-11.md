---
title: "数学 × AI 周报 · 第 11 期（本周速递）：Stacks 项目被写成 1575 万行 Lean，陶哲轩说数学家开始藏问题"
date: 2026-11-09 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 11
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - Axiom
  - Stacks Project
  - Lean
  - 陶哲轩
  - OpenAI
description: >-
  第 11 期（本周速递）：Axiom 称把 Stacks 项目（约 7500 页代数几何）形式化为约 1575 万行 Lean；陶哲轩在一场演讲里说，数学家开始藏问题，好问题变得稀缺；OpenAI 那批手稿引发的争论，被 NPR 拿到了台面上。本周料少，只出三条短讯。
image:
  path: /assets/img/posts/math-ai-weekly-11/cover.png
  alt: "数学 × AI 周报 第 11 期封面（AI 生成）"
---

> **本期一句话**：证明越来越多，问题越来越少。本周的消息，一边是机器把七千多页的数学搬进了 Lean，一边是有人说，真正稀缺的是值得做的题。本期料少，是轻量版。
{: .prompt-tip }

---

## Axiom：把 Stacks 项目搬进 Lean

**11 月 4 日**，Axiom Math 宣布完成 Stacks 项目的 Lean 形式化。Stacks 是一部开源的代数几何参考文本，约 7500 页。按 Axiom 项目页的数字：约 15,751,904 行 Lean，62,975 个文件，663,090 条声明，由多个 AI 智能体协作完成，并把每条 Lean 声明链接回原文的标签。

要打折扣的地方：这些数字都是 Axiom 自己给的，我没有看到第三方的独立复核。据报道，人工审查只覆盖其中一层（StacksCore），另一层（StacksFrontier）由智能体写成，没有人工审过。Stacks 的发起人 Johan de Jong 也请对方不要把 AI 生成的拉取请求直接提到上游仓库，所以这套成果是单独存放的。耗时多久，我没有核到。

**解读**：上周是一万五千页的群论，这周是七千五百页的代数几何。机器搬得越来越快，搬完之后谁来读，还是没有答案。

> 来源：[Axiom 官方说明](https://axiommath.ai/research/the-stacks-project-formalized/) · [项目页](https://stacks.axiommath.ai/) · [FourWeekMBA 汇总](https://fourweekmba.com/ai-axiom-puts-the-stacks-project-in-lean-2-100-lines-per-page/)

---

## 陶哲轩：数学家开始藏问题

演讲不在本周，视频在本周。**10 月 16 日**，陶哲轩在 UCLA 的 Science x AI 峰会上讲了《Math 2.0》，**11 月 3 日**，主办方 SAIR 把全片放上了 YouTube。据自动字幕，他说了几句分量不轻的话：数学家在"藏自己的问题"，因为怕别人拿着 AI 工具抢先发表；"有史以来第一次，我们快没有问题可解了"。他还说，面对 OpenAI 那批三百来篇论文，他找不到可以打电话问的人。

字幕是自动生成的，不同来源的措辞略有出入，以视频为准。他没有给出多少人在藏问题，也没有点名。

**解读**：证明变得便宜，便宜的东西会先把稀缺的东西暴露出来。稀缺的是一个好问题，和一个愿意读完答案的人。

> 来源：[YouTube：Terence Tao, Math 2.0（SAIR 上传）](https://www.youtube.com/watch?v=aHpPoNNTOKY) · [FourWeekMBA 整理](https://fourweekmba.com/ai-tao-math-now-hides-its-problems-after-openais-372-proofs/)

---

## OpenAI 的手稿，争论到了公共媒体

这是上两期的后续。**11 月 4 日**，NPR 的 Short Wave 栏目以"OpenAI 一批一批地发布数学证明，是不是在伤害这个领域"为题做了一期节目，涉及 Navier–Stokes 相关的讨论。我只看到标题和摘要，没能打开全文，所以不转述具体观点。另据二手汇总，OpenAI 这批材料对外的数字有出入：372 组结果、722 篇手稿，也有报道写 719 篇、377 个问题。

**解读**：连数字都对不齐，说明还没有人能把这批东西完整读一遍。争论本身，倒是个好兆头。

> 来源：[NPR Short Wave](https://www.npr.org/2026/11/04/nx-s1-6010471/ai-math-navier-stokes-mathematicians-openai) · [OpenAI：Sharing AI progress in mathematics](https://openai.com/index/sharing-ai-progress-in-mathematics/)

---

## 把这一周连起来看

三条说的还是同一件事。写，越来越快：七千多页，一周一份新闻。读，没有变快。陶哲轩说的"藏问题"，说到底是怕别人抢在前面写完。可写完不等于证得了，要有人读，要有人认。机器会算，不等于证得了。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 11 期。
