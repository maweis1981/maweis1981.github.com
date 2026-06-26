---
title: "数学 × AI 周报 · 第 01 期：Erdős 猜想破了，AI 进入「研究数学」时代"
date: 2026-06-26 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 1
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - OpenAI
  - DeepMind
  - AlphaProof
  - Lean
  - 形式化验证
  - Erdős
  - 陶哲轩
  - IMO
  - 定理证明
description: >-
  第 01 期：OpenAI 推翻持续 80 年的 Erdős 单位距离猜想；DeepMind AlphaProof Nexus 连解 9 个公开难题并证明 44 个 OEIS 猜想；陶哲轩在 Quanta 阐述实验数学新范式；数学家质疑 AI「金牌」含金量，IMO 2026 七月上海开幕。
image:
  path: /assets/img/posts/math-ai-weekly-01/cover.png
  alt: "数学 × AI 周报 第 01 期封面"
---

> **本期一句话**：AI 不只是做题机器了——它开始在没有标准答案的地方打洞，而「打洞之后还要封洞」，才是证明真正的价值所在。
{: .prompt-tip }

---

## OpenAI 推翻持续 80 年的 Erdős 单位距离猜想

**5 月 20 日**，OpenAI 宣布其内部通用推理模型找到了平面单位距离问题的新构型，推翻了这个自 1946 年以来被广泛相信的上界猜想。

问题本身非常直白：把 n 个点摆在平面上，两两距离恰好为 1 的点对数，最多能有多少？Erdős 猜测上界约为 n 的 1.5 次方。OpenAI 的模型另辟蹊径——不用格点排列，而是利用高次代数数域的对称性构造了一个新结构，使单位距离点对数增长指数严格大于 1（即 n 的 1+δ 次方，δ > 0），直接击穿猜想。

菲尔兹奖得主 Tim Gowers 事后表示，若这份证明由人类提交到顶级数学期刊，他会毫不犹豫推荐录用。外部数学家也独立完成了验证。

**解读**：这是 AI 在「无人知道答案」的开放数学问题上首次实质性推进，区别于此前在竞赛题或已知结论的形式化上的表现。核心能力是探索性构型搜索，而非步骤推导。

> 来源：[OpenAI 官方公告](https://openai.com/index/model-disproves-discrete-geometry-conjecture/) · [arXiv:2605.20695](https://arxiv.org/abs/2605.20695) · [Gil Kalai 数学博客](https://gilkalai.wordpress.com/2026/05/21/amazing-erdos-unit-distance-problem-was-disproved-it-was-achieved-by-ai/)

---

## DeepMind AlphaProof Nexus：一次性解决 9 个公开 Erdős 难题

一天之后，**5 月 21 日**，DeepMind 发布 AlphaProof Nexus 的论文与结果：系统从 353 个公开 Erdős 问题中解出 9 个，同时证明了 500 余个 OEIS 开放猜想中的 44 个。其中两个问题悬而未决长达 56 年。

AlphaProof Nexus 的架构是大语言模型与 Lean 形式证明助手的「闭环」：LLM 生成候选证明，Lean 验证每一步逻辑；若验证失败则反馈给 LLM 迭代，直到通过或放弃。每道问题的算力成本约几百美元——在研究级数学中是惊人的低廉。

**解读**：与 OpenAI 的单点突破不同，AlphaProof Nexus 展示的是「流水线式」的批量研究能力。Lean 验证赋予结果可信度——机器生成的证明每一步都有迹可查，这正是「算」和「证」之间的本质区别。

> 来源：[BuildMVPFast 报道](https://www.buildmvpfast.com/blog/deepmind-alphaproof-nexus-erdos-math-problems-ai-reasoning-2026) · [Dev.to 技术解析](https://dev.to/monuminu/how-deepmind-alphaproof-nexus-cracks-56-year-old-math-agentic-llm-loops-and-lean-formal-45ei)

---

## 陶哲轩：数学正在进入「实验科学」阶段

**6 月 8 日**，Quanta Magazine 刊出深度报道《Terry Tao 如何成为 AI-in-Math 的布道者》，内容节选自 Kevin Hartnett 新书《The Proof in the Code》。

陶哲轩近年主导了多个 Lean 形式化大项目：2023 年领导 13 人团队完成多项式 Freiman-Ruzsa (PFR) 猜想的形式化，整个证明被切成模块化的五行引理分布协作；2024 年绘制 4694 条代数定律之间的 22 百万个逻辑蕴含关系，意外发现了「magma 上同调」这一全新数学结构。

他的愿景是三层协同：人类的直觉与洞察力 + 大语言模型的创意生成 + 形式验证系统的逻辑保证。他把这类研究类比于物理学中的大型合作实验——数百人协作，计算机充当「同行评审」。

**解读**：陶哲轩的转变意义在于，他不是在用 AI 做演示，而是在用 AI 做新的数学。这种「实验数学」模式一旦规模化，对数学社区的组织方式将是结构性冲击。

> 来源：[Quanta Magazine，2026年6月8日](https://www.quantamagazine.org/how-terry-tao-became-an-evangelist-for-ai-in-math-20260608/)

---

## 数学家质疑 AI 的 IMO「金牌」含金量

去年 IMO（2025）闭幕后，OpenAI 和 DeepMind 相继宣布各自的模型在非正式测试中解出 6 题中的 5 题，达到金牌分数线。这引发了数学界的持续讨论，Scientific American 专门整理了数学家的质疑。

核心问题有三：第一，AI 采用「最优 N 选一」策略——多次生成取最优——人类选手没有这个选项；第二，IMO 主席 Gregor Dolinar 指出无法核验算力投入、是否有人工干预、以及结果能否复现；第三，Emily Riehl 等人指出 IMO 题目与真实前沿研究相去甚远，前者有既定答案且在数小时内可解，后者可能需要数年并无保证存在答案。

值得关注的是，**IMO 2026（第 67 届）将于 7 月 10—21 日在上海举行**，届时 AI 模型是否会再次「参加」并公布成绩，已成为数学社区的焦点话题之一。

**解读**：「能做题」和「能做数学」之间隔着一道关于可重现性、计算透明度和问题难度的鸿沟。质疑本身是健康的——它推动着评估标准的演进。

> 来源：[Scientific American 报道](https://www.scientificamerican.com/article/mathematicians-question-ai-performance-at-international-math-olympiad/) · [IMO 2026 官方页面](https://www.imo-official.org/editions/2026/)

---

## Mathesis：让 AI「读懂」自然语言数学题并输出 Lean 证明

6 月初，arXiv 上线论文 *Mathesis: Towards Formal Theorem Proving from Natural Languages*（arXiv:2506.07047），来自 Yu Xuejun 等 20 位作者的团队。

系统分两个模块：Mathesis-Autoformalizer 负责将自然语言数学题转化为 Lean 4 形式表述，引入了一个名为 LeanScorer 的框架做形式化质量评分；Mathesis-Prover 再从形式表述生成 Lean 证明。在 MiniF2F 基准上，完整系统以 pass@32 达到 64% 准确率；在新引入的高考数学形式化基准 Gaokao-Formal（488 题）上达到 18%，较基线提升 22 个百分点。

**解读**：高考数学是「有结构、有标准答案、但对语言理解要求极高」的测试集，它的形式化难度远高于 IMO 题目。18% 的数字说明「读懂题意然后证明」这条链路仍在早期，但方向是对的。

> 来源：[arXiv:2506.07047](https://arxiv.org/abs/2506.07047)

---

## 把这一周连起来看

这五条新闻有一根隐线：**机器「算」的能力在快速逼近人类，但「证」的标准反而越来越严苛**。

OpenAI 的 Erdős 突破令人振奋，但 Tim Gowers 的验证才让它进入数学史。AlphaProof Nexus 的 Lean 闭环让每一步都可查。陶哲轩强调的正是这一点：大规模协作 + 形式验证，才是「实验数学」的护城河。数学家对 IMO 金牌的质疑，本质上也是在追问同一件事——结果可不可以独立核验？

AI 能算出来，和 AI 真的证明了，是两件不同的事。「证」越来越值钱，正因为它是不可伪造的。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 01 期。
