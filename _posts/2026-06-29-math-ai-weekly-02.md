---
title: "数学 × AI 周报 · 第 02 期：莱顿宣言，数学家的集体反击"
date: 2026-06-29 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 2
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - 莱顿宣言
  - 形式化验证
  - Lean
  - HorizonMath
  - IMO
  - Erdős
  - 定理证明
  - 数学社区
  - Peter Scholze
  - 陶哲轩
description: >-
  第 02 期：2000 余位数学家签署莱顿宣言，为 AI 数学研究划出诚信底线；Slate 质疑 Erdős 突破的"算力地毯轰炸"本质；HorizonMath 测出 GPT-5.4 Pro 两个疑似新结果；IMO 2026 上海倒计时 11 天，AI 再战前夜。
image:
  path: /assets/img/posts/math-ai-weekly-02/cover.png
  alt: "数学 × AI 周报 第 02 期封面"
---

> **本期一句话**：打破猜想的欢声还在回响，数学家已经开始追问：是谁在定义「证明了」这三个字？
{: .prompt-tip }

---

## 莱顿宣言：2000 位数学家向 AI 划下边界

**6 月 2 日**，一份名为《莱顿人工智能与数学宣言》（Leiden Declaration on Artificial Intelligence and Mathematics）正式发布。它由 17 位数学家经过八个月起草，依托 2025 年 9 月莱顿洛伦茨中心研讨会的成果，并获国际数学联盟（IMU）背书。截至 6 月 5 日，签名者已超过 1,590 人，签署者名单涵盖 Peter Scholze（2018 年菲尔兹奖）、陶哲轩、Scott Aaronson、Kevin Buzzard、Ulrike Tillmann 等重量级数学家。

宣言列出四大核心风险：

- **证明可靠性**：AI 生成的证明难以核验，错误率不透明；
- **商业炒作**：企业在验证机制建立之前过度渲染成果；
- **跟风研究**：学界可能因工具的偏好而偏离真正重要的问题；
- **理解缺失**：AI 不具备数学家所说的"理解"，只有输入-输出映射。

值得注意的是，宣言**并未呼吁禁止** AI 参与数学研究，而是呼吁社区建立使用规范——公开 AI 参与度、保留严格同行评审，以及防止商业激励扭曲研究方向。

**解读**：这份宣言的意义不在于它反对 AI，而在于签署者本身就是 AI 的用户。他们划的是诚信底线，不是技术禁令。数学证明的价值一直来源于可独立复现、可逐步核查的共识过程；任何工具，若侵蚀这一过程，都值得被审视。

> 来源：[莱顿宣言官网](https://leidendeclaration.ai/) · [莱顿大学公告](https://www.universiteitleiden.nl/en/news/2026/06/leiden-declaration-warns-ai-is-challenging-the-core-values-of-mathematics) · [Science News 报道](https://www.sciencenews.org/article/ai-guardrails-erdos-math-problem) · [Scientific American 报道](https://www.scientificamerican.com/article/mathematicians-sign-declaration-to-rein-in-ai-use/)

---

## Slate 批评：Erdős 突破是「算力地毯轰炸」

本月，Slate 刊出了一篇题为《AI 的首个重大数学突破，并非看上去那样》的长文，提供了对上周 OpenAI Erdős 成果的深度质疑视角。

文章的核心比喻直接：「2026 年，AI 的做法等同于数学领域的地毯式轰炸——把价值一笔军事预算的 token 投到一堆未解难题上，看还剩什么站着。」作者指出，OpenAI 既未公开失败率，也未披露总计算时间，使外界无法判断这究竟是「AI 的创造力突破」还是「高算力穷举加运气」。

归因问题同样被点名：AI 系统读过所有公开论文与网络讨论，却无法合理追溯想法的来源，这对数学界沿袭已久的优先权传统是一种结构性挑战。

**解读**：Slate 的批评并不否认 Erdős 结论本身是对的——Tim Gowers 的验证已经说明了这点。真正的问题是叙事框架：「AI 自主发现」和「AI 在海量尝试中碰巧找到了一个正确构型」，是两种截然不同的故事，而现有披露不足以区分二者。透明度不是附加要求，它是「证明了」这个说法本身的一部分。

> 来源：[Slate 原文](https://slate.com/technology/2026/06/math-chatgpt-erdos-problem-solved-open-ai.html) · [Science News 相关报道](https://www.sciencenews.org/article/ai-guardrails-erdos-math-problem)

---

## HorizonMath：AI 在未解问题上找到两个疑似新结果

如果说前两条是对 AI 数学能力的质疑，这一条则提供了更有说服力的正面信号——来自一个专门设计来抵抗数据污染的基准。

**HorizonMath**（arXiv:2603.15617，发布于 3 月 16 日）收录了横跨 8 个领域的 100 余道「几乎未解」的计算数学问题，并配套自动验证框架。其设计原则是：答案未知，所以无法从训练数据中背会；验证可自动化，所以无法伪造。测试结果显示，绝大多数最先进的模型在这个基准上得分接近 0%。

例外是 GPT-5.4 Pro：它在「可解性 1 级」的两道题上提出了优于已知最优结果的方案，待专家审核后可能构成文献级新结果。这两道题是经过精心筛选的，数学洞察力而非蛮力才能奏效。

**解读**：这里的对比很有意思——HorizonMath 恰恰是莱顿宣言所呼吁的那种透明机制：公开题目、公开基线、自动验证。GPT-5.4 Pro 的两个疑似新结果之所以值得认真对待，正因为机制足够严格。两个结果在百余道题里极少，但在「几乎不可能」的基准上这已经是一个信号。

> 来源：[arXiv:2603.15617](https://arxiv.org/abs/2603.15617) · [HorizonMath GitHub](https://github.com/ewang26/HorizonMath)

---

## IMO 2026：七月十日，上海见

**第 67 届国际数学奥林匹克（IMO 2026）将于 7 月 10 日至 20 日在上海举行**，竞赛日为 7 月 15 日和 16 日，各 4.5 小时，共 6 道题。距今 11 天。

上一届（2025 年，澳大利亚）赛后，OpenAI 和 DeepMind 相继宣布各自的模型在非官方测试中达到金牌分数线。这引发的争议已在上期详述。进入 2026，数学社区带着更成熟的问题等待这一年的 IMO：

- AI 模型会再次"参加"并公布成绩吗？
- 若参加，是否会公开采样次数和总计算时间？
- IMO 组委会会否设立正式的 AI 评估协议？

目前官方尚无明确声明。可以确定的是，与人类选手相比，今年的 AI 性能声索将面临来自莱顿宣言签署者更严格的审视。

**解读**：IMO 题目有既定答案且设计在数小时内可解，这与真实研究数学相去甚远——这正是上期数学家质疑「金牌含金量」的根源。但 IMO 仍然是最有公众曝光度的测试场，它的结果会塑造大众对 AI 数学能力的认知。值得关注的不只是「AI 解了几题」，还有「用了多少次尝试、多少算力」。

> 来源：[IMO 2026 官方页面](https://www.imo-official.org/editions/2026/) · [Scientific American 质疑报道](https://www.scientificamerican.com/article/mathematicians-question-ai-performance-at-international-math-olympiad/)

---

## 把这一周连起来看

这四条新闻有一条共同的主线：**「证明了」这三个字，正在变成一个需要社区集体回答的问题，而不是单个机构自己宣布的事情。**

莱顿宣言是数学社区的集体回应，说的是：我们需要标准，不是禁令。Slate 的批评指向的是透明度——失败率、计算量、归因——这恰恰是任何「证明了」声索的必要上下文。HorizonMath 则用一个严格的机制示范了什么是「有说服力的正面信号」：公开基线、自动验证、抗污染设计。IMO 2026 即将成为新的公众试验场，但问题已经升级：「赢没赢」之前，先问「用了多少次」。

机器越来越会算，所以「证」的门槛也越来越被社区认真守护。「证」值钱，不只因为它正确，更因为它是经得起追问的。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 02 期。
