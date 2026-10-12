---
title: "数学 × AI 周报 · 第 08 期：OpenAI 一口气放出 722 篇数学手稿，一周内撤了三篇，Lean 通过也不等于对"
date: 2026-10-12 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 8
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - OpenAI
  - Lean
  - 形式化验证
  - 陶哲轩
  - Erdős 问题
  - Navier–Stokes
  - 学术诚信
description: >-
  第 08 期：OpenAI 公开 722 篇由内部模型生成的数学手稿，Lean 形式化只覆盖约四成，发布一周内撤回三篇、修补十四篇；剑桥团队指出此前 Navier–Stokes 的 Lean 证明并非对原文的忠实翻译；托马斯·黑尔斯在陶哲轩博客上讲清楚 Lean 自己的可靠性问题。
image:
  path: /assets/img/posts/math-ai-weekly-08/cover.png
  alt: "数学 × AI 周报 第 08 期封面（AI 生成）"
---

> **本期一句话**：这周只有一件大事，却有三层。OpenAI 一次放出 722 篇数学手稿，数量吓人。一周之内，有人撤稿，有人指出形式化证明翻译走样，有人提醒 Lean 本身也还有没证完的账。机器交卷越来越快，验卷的人反而更忙了。
{: .prompt-tip }

---

## OpenAI 一次放出 722 篇数学手稿

**10 月 6 日**，OpenAI 在 GitHub 上公开了一批由内部前沿模型生成的数学研究成果：722 篇手稿，归并为 372 组结果，来自模型尝试的约 4000 个问题，涉及数论、复杂性理论、几何、数学物理等方向，其中有圆周率无理性指数、Mahler 猜想、自由群因子等题目。OpenAI 为不少结果附上了 Lean 形式化版本，同时在自己的说明里写明：Lean 通过"并不自动说明每一条研究结论都正确"，部分未形式化的结果"可能是错的"。据报道，这批结果经过 IAS 数学与人工智能顾问组的建议。

**解读**：这次的发布方式有点新。不是挑一两个最漂亮的结果开发布会，而是把一整批原料摊出来，连"可能是错的"都写在说明里。数量本身不是新闻，把验证的活交给整个数学界，才是。

> 来源：[Interesting Engineering 报道](https://interestingengineering.com/ai-robotics/openai-largest-math-release-lean-proofs) · [Redreamality 对仓库记录的整理](https://redreamality.com/blog/ai-math-verification-lean-faithfulness/)

---

## 一周内撤了三篇，修了十四篇

据仓库 `history.md` 的记录，10 月 7 日这批手稿就有三篇撤回、十四篇修补证明或更正表述、十三篇只改引用。撤回的那篇讲的是"分裂阿贝尔八重形上 Weil 类的代数性"：一处符号写错，反迹应为 −1 而不是 +1，重点计数变成 −2m 而非零，而后面用到的 Eliashberg–Murphy 定理恰恰需要零，论证就断了。撤稿说明并没有断言结论为假。另外两篇依赖同一构造，一并撤下。三篇都不在 Lean 形式化清单里，也就是没有机器查过它们。顶层结果中被形式化的比例，记录里是约 300/719，即 42% 左右。（该比例为第三方整理，不同来源对统计口径有出入，数字请当约数。）

另有一条相关消息：Thomas Bloom 在 10 月 9 日的博客里整理了这批手稿中涉及的 23 个 Erdős 问题，其中 19 个有 Lean 版本；他明确说自己还没细读证明，也没核对形式化陈述是否贴合原题，预期多数论文正确但写得粗糙，"是很丰富的原料"。他还提到，第 3 题的 Lean 文件目前只证了比论文声称更弱的界。

**解读**：撤掉的三篇恰好是没有 Lean 的三篇。这很难不让人想到，形式化确实在拦错。但同一批里，第 3 题那种"Lean 证的比论文说的弱"的情形也提醒我们，有 Lean 文件，和 Lean 文件证的就是那句话，是两回事。

> 来源：[Redreamality：Correction Week 整理](https://redreamality.com/blog/ai-math-verification-lean-faithfulness/) · [OfficeChai 对 Bloom 博文的报道](https://officechai.com/ai/openai-has-also-included-proofs-for-23-erdos-problems-in-its-latest-math-proof-drop/)

---

## 剑桥团队：Lean 通过了，但那未必是原来那篇证明

**10 月 6 日**，剑桥的 Alexander Bastounis、Fabian Circelli 和 Anders Hansen 在 arXiv 发布《Navier–Stokes lost in translation》（arXiv:2610.08144）。他们逐条对照 OpenAI 9 月 8 日宣布的 Navier–Stokes 带外力爆破结果，认为 Lean 代码并不是对原文证明的语义忠实翻译，所以"Lean 编译通过"不能为自然语言证明背书。据二手报道，举的例子之一是：原文某处需要 m+4 阶导数，而 Lean 里对应的定理假设了 m+5 阶，实际证的是一个更弱的不等式。论文并没有断言 OpenAI 的原证明是错的。我没有找到 OpenAI 对此的正式回应。

**解读**：这条的分量在于，它不攻击结论，只攻击"验证"这个动作。形式化验证的前提是：陈述对得上，翻译不走样。这一步目前还得靠人去审，而且很累。

> 来源：[AI Weekly 快讯](https://aiweekly.co/alerts/paper-flags-gap-in-openais-lean-verified-navier-stokes-proof) · [Redreamality 整理](https://redreamality.com/blog/ai-math-verification-lean-faithfulness/)（论文原文为 arXiv:2610.08144，本文未能直接读到摘要页，细节出自二手转述）

---

## 黑尔斯在陶哲轩博客上算 Lean 自己的账

**10 月 9 日**，陶哲轩的博客刊出托马斯·黑尔斯（Thomas Hales）的客座文章，题目是数学家该知道的 Lean 可靠性问题。文章回顾了今年自动形式化的几个节点，包括 9 月 4 日 Anthropic 宣布的费马大定理自动形式化（据文中说法，11 天产出 1300 万行），也讲到今年 7、8 月间一批 Lean 内核的"可靠性漏洞"，由前沿 AI 工具辅助的安全研究者发现，其中有的能"证出"不该被证出的东西。黑尔斯谈了几条补救路线：多个独立内核交叉检查，Breitner 的 Con-Leche 验证检查器等。他还写到，截至 2026 年 10 月，他所知并没有一份完整、公开的、覆盖 Lean 类型论的相对一致性证明。结尾他提醒：交给 AI 做的基础工作，要有人类认真审。

**解读**：数学家把"对不对"外包给 Lean，Lean 又把自己的可信度押在一个只有几千行的内核上，而这个内核的元理论还有没写完的部分。信任是一层一层往下传的，总得有个地方由人来兜底。

> 来源：[陶哲轩博客：黑尔斯客座文章](https://terrytao.wordpress.com/2026/10/09/what-mathematicians-should-know-about-the-lean-theorem-proverquestions-of-reliability-and-ai/)

---

## 把这一周连起来看

三条新闻其实是一条链子上的三环。OpenAI 把 722 篇手稿推出来，这是产出。撤稿和 Bloom 的"还没细读"，是人在读。剑桥那篇讲翻译，黑尔斯那篇讲内核，是人在问：连"机器检查过了"这句话，靠什么站得住。产出的速度已经不再是瓶颈，瓶颈在往后挪：先挪到读，再挪到译，再挪到工具本身。机器会算，不等于证得了。证得了，还要有人看得懂，信得过。所以"证"越来越值钱。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 08 期。
