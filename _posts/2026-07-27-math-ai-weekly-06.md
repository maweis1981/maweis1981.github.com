---
title: "数学 × AI 周报 · 第 06 期：一条推翻 87 年猜想的推文，一场追平人类满分的官方判卷"
date: 2026-07-27 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 6
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - 雅可比猜想
  - Claude Fable 5
  - Levent Alpöge
  - Anthropic
  - IMO
  - 华为
  - 小红书
  - ICM 2026
  - 陶哲轩
  - Lean
  - 形式化验证
description: >-
  第 06 期：Anthropic 数论学家 Levent Alpöge 用 Claude Fable 5 找到反例，推翻了悬置 87 年的雅可比猜想（n≥3
  情形），当晚就被 Lean 形式化核验，OpenAI 内部模型据称也独立找到了同一个反例；IMO 2026 官方判卷结果揭晓，华为"Celia"与小红书
  "dots-note-3.0"双双拿到 42/42 满分，是 AI 首次在官方评分流程下追平人类最高分；国际数学家大会（ICM 2026）在费城开幕，陶哲轩发表公开演讲
  「AI 时代的数学」，呼吁把声望分配给核验与消化结果的人，而不只是生成结果的人。
image:
  path: /assets/img/posts/math-ai-weekly-06/cover.png
  alt: "数学 × AI 周报 第 06 期封面"
---

> **本期一句话**：这周机器又把"算"的门槛砍掉了一截——几行对话推翻了一个 87 年的猜想，官方计时下拿到了和人类冠军一样的满分。但真正被反复提起的，是"讲清楚为什么成立"这件事，机器目前还替代不了。
{: .prompt-tip }

---

## Anthropic 数论学家用 Claude Fable 5 推翻雅可比猜想，当晚被 Lean 核验

**7 月 19 日周日（美国时间）**，Anthropic 数论学家 Levent Alpöge（哈佛大学 Junior Fellow 出身）在 X 上发了一条很随意的帖子："hello there the jacobian conjecture is false thanx"，附上一个只有几行的三元多项式映射：其 Jacobian 行列式恒为常数 −2，按照通常直觉这应当保证映射整体可逆，但 Alpöge 构造的这个映射把多个不同的输入点送到了同一个输出点，并不可逆。雅可比猜想由 Ott-Heinrich Keller 在 1939 年提出，是 Steve Smale"21 世纪 18 个问题"之一，此前一直悬而未决。这个反例由 Alpöge 与 Claude Fable 5（Anthropic 几周前刚发布的模型）合作构造，证明猜想在 n≥3 的所有维度上都不成立，二维情形依然是公开问题。

伦敦时间**周一清晨**，帝国理工学院数学家 Kevin Buzzard 醒来时，反例已经被 Lean 形式化核验通过；到中午，这条消息已经传遍帝国理工纯数学系。Buzzard 说："这是重要的一天，我个人觉得能活在当下真是幸运。"芝加哥大学数学家 Akhil Mathew 的评价更谨慎："你可以核实它是对的，但还是希望能讲出一个道理来"，并称这类突破对青年数学家而言"是一场非常迅速、也非常让人不安的变化"。**OpenAI 研究员 Aaron Lou 随后表示**，公司内部版本的 Codex 模型独立找到了本质上相同的反例。

**解读**：这条新闻里最关键的细节，其实不是"AI 推翻了猜想"，而是"猜想被推翻之后当晚就有 Lean 兜底核验"——核验环节没有缺席，只是被压缩到了几个小时。两家实验室各自独立撞上同一个反例，也说明这不是一次孤立的运气，而是一类问题正在变得"可被机器找到"。

> 来源：[Secret Blogging Seminar 数学分析](https://sbseminar.wordpress.com/2026/07/20/the-new-counterexample-to-the-jacobian-conjecture/) · [The Conversation 报道](https://theconversation.com/hello-there-the-jacobian-conjecture-is-false-thanx-why-a-tiny-social-media-post-has-mathematicians-rethinking-ai-283883) · [Fortune 报道（Yahoo 转载）](https://tech.yahoo.com/ai/articles/mathematicians-grapple-very-rapid-very-161544136.html)

---

## IMO 2026 官方判卷揭晓：华为、小红书模型双双拿到 42/42 满分

第 67 届国际数学奥林匹克官方判卷结果本周公布：**华为的"Celia"与小红书的"dots-note-3.0"**均在 IMO 官方评分流程下拿到 **42/42 满分**——据小红书方面说明，测试期间"严禁任何形式的人工干预"，且在规定时限内完成，解答提交给 IMO 组委会评审，这是大语言模型首次在官方判卷流程下取得满分。本届 666 名人类参赛者中，只有 **7 人**拿到满分。此外，投资人 Deedy Das 私下用同一套赛题测试了另外四个模型——OpenAI、Anthropic、创业公司 Axiom Math 与月之暗面的 Kimi K3——据称也都拿到了 42 分，但这属于非官方测试，未经组委会评审。

**解读**：上一期我们留下的悬念是"AI 阵营这次会不会愿意接受官方核验，而不是像去年那样自己先宣布"——这周至少两家中国厂商给出了肯定的答案：走了官方判卷流程，而不是自行宣布战绩。但"官方判卷"和"官方对外确认结果为真"仍是两件事，组委会本身并未就这两个结果发表评价，这条线还需要继续追。

> 来源：[Digital Journal 报道](https://www.digitaljournal.com/article/ai-catches-up-with-humans-to-score-100-at-top-maths-contest/) · [Tech Xplore 报道](https://techxplore.com/news/2026-07-ai-humans-score-math-contest.html)

---

## ICM 2026 费城开幕，陶哲轩公开演讲「AI 时代的数学」

国际数学家大会（ICM）**7 月 23 日至 30 日**在费城宾夕法尼亚会展中心举行，这是 ICM 四十年来首次在美国举办。陶哲轩在会上发表公开演讲《数学在 AI 时代》（Mathematics in the Age of AI），主题是 AI 与形式化将如何重塑数学研究与教育，同时强调"这个专业里那些独属于人类的部分，并没有在这场变革中消失"；罗格斯大学的 Alex Kontorovich 则做了关于自动形式化（auto-formalization）的大会报告，讨论如何让 AI 把已有数学知识形式化，从而让更多研究者用上计算化的发现工具。陶哲轩在他持续更新的个人主页（**7 月 24 日**更新）中进一步写道：现在"生成一篇长而正确的证明"已经比"生成一篇简短的证明"更容易，但证明产出速度变快并没有让数学进展本身跟着加速；他建议这个专业应该把声望更多地分配给核验和消化结果的人，而不只是生成结果的人。

**解读**：这句话正好接住了第一条新闻里 Akhil Mathew 的顾虑——"能核实对，但还是想听个道理"。陶哲轩这周把这种个人感受，讲成了一条明确的学科建议：荣誉不该只给"算得快"的人，也该给"讲得清楚"和"核验到位"的人。

> 来源：[Terence Tao 个人页面（AI 观点汇总）](https://teorth.github.io/tao-web/ai-views.html) · [Simons Foundation 报道](https://www.simonsfoundation.org/2026/05/04/ai-will-be-top-of-mind-at-icm-maths-biggest-conference/)

---

## 把这一周连起来看

这三条新闻其实在说同一件事：**机器把"算出来"这件事的门槛又砍低了一截，但"证明"里"核验、复现、讲清楚为什么成立"的部分，仍然稳稳地落在人和形式化系统的手里。**

Alpöge 用几行对话就把一个 87 年的猜想变成了反例，但真正让这件事"落地"的，是伦敦清晨已经跑完的那次 Lean 核验，以及 OpenAI 内部模型独立撞上同一个答案；华为和小红书这次没有自己先宣布战绩，而是走了 IMO 官方判卷流程，把"确认权"交还给了赛事组委会；陶哲轩则在费城把这一整周的观察，浓缩成了一句对整个学科的建议——该被奖赏的，是把结果讲成一个道理的人。算得动和证得了，从来不是同一件事，这周的三条新闻恰好各自从不同角度印证了这一点。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 06 期。
