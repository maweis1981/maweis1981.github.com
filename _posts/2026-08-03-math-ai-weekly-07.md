---
title: "数学 × AI 周报 · 第 07 期：两千美元解开十个数学难题，一位菲尔兹奖得主转身去做 AI 安全"
date: 2026-08-03 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 7
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - OpenAI
  - Astra
  - 非可音群
  - Lean
  - 形式化验证
  - Gary Marcus
  - 莱顿宣言
  - 菲尔兹奖
  - Jacob Tsimerman
  - Daniel Litt
description: >-
  第 07 期：OpenAI 公布下一代模型内部代号"Astra"的十项数学与理论计算机科学新成果，花费约两千美元，首次显式构造出悬置 27
  年的"非可音群"，全部结果配有零 sorry 的 Lean 4 核验证书；数学圈的反应两极，喝彩、愤怒与一场认输的赌局同时发生，Gary
  Marcus 泼冷水，"莱顿宣言"的背景也随之升温；2026 年菲尔兹奖得主 Jacob Tsimerman 领奖后转身加入 OpenAI 做
  AI 安全；OpenAI 同时宣布向十万名科研人员免费开放 ChatGPT。
image:
  path: /assets/img/posts/math-ai-weekly-07/cover.png
  alt: "数学 × AI 周报 第 07 期封面（AI 生成）"
---

> **本期一句话**：这周的头条数字很扎眼：两千美元，十个十年以上无人攻克的难题，外加一个悬置 27 年的存在性问题。但比数字更值得记住的，是数学圈这周的反应：有人喝彩，有人生气，一位常年打赌"AI 短期内追不上顶尖数学家"的数论学家，这周认了输。
{: .prompt-tip }

---

## OpenAI 甩出 Astra，两千美元解开十个尘封数十年的数学难题

**8 月 1 日（美国时间周六）**，OpenAI 公布了下一代主力模型内部代号"Astra"的十项数学与理论计算机科学新成果，覆盖高维几何、编码理论、群论、格密码等多个方向，这些问题此前至少十年无人取得实质进展，多数悬置更久。其中分量最重的一条：首次显式构造出一个"非可音群"（non-sofic group），回答了 Gromov 在 1999 年提出、悬置 27 年的存在性问题。公司同时放出一份 249 页的成果手稿，以及全部十项结果对应的 Lean 4 机器核验证书，GitHub 仓库以 Apache 2.0 协议开源，"sorry"（未完成证明步骤的占位符）计数为零。据披露，这些结果按"Sol"档 API 价格计算，总共只花了约两千美元的模型调用费用。克莱数学研究所的七个千禧年大奖难题，一个也没有被碰。

**解读**：这条新闻里最容易被忽略的细节，是"零 sorry"：不是模型自己说证明成立，而是形式化系统把每一步都核验过了。但"能核验"和"能被数学圈接受"之间，这周马上就有人跳出来提醒大家，那不是一回事。

> 来源：[OpenAI 官方博客](https://openai.com/index/ten-advances-in-mathematics/) · [Tech Times 报道](https://www.techtimes.com/articles/322710/20260802/openais-astra-solves-ten-decade-old-math-problems-machine-checkable-lean-proofs.htm) · [BleepingComputer 报道](https://www.bleepingcomputer.com/news/artificial-intelligence/openai-teases-astra-its-next-major-ai-model-after-it-solves-10-long-standing-math-problems/)

---

## 数学圈的反应两极：喝彩、愤怒，还有一场认输的赌局

Astra 论文发布后，数学圈没有统一口径。整理 Erdős 问题集的曼彻斯特大学数学家 Thomas Bloom 在 X 上评价"这是大新闻"，认为光是构造方法本身就有分量；也有一位即将升任教授的数学博士后，事后描述自己的第一反应是震惊，接着是愤怒。多伦多大学数论学家 Daniel Litt 认了一场旧账：他此前和人打赌，AI 在 2030 年前造不出一篇《数学年刊》水准、成本可比人类的数论论文，这周他公开承认要输了："严格说赌局还没到期，但我显然低估了需要的能力。"批评声量最大的是认知科学家 Gary Marcus，他说把 Astra 的发布称作"数学史上最重要的一天"很荒谬：这次没有新理论、没有新方法，数学恰好是最容易被符号化核验、又能用廉价合成数据喂养的特例，不代表能力会自动扩散到别的领域。这些反应背后还有一层背景：今年 6 月，包括 Kevin Buzzard、Peter Scholze 在内的数学家联署了"莱顿宣言"（Leiden Declaration），得到国际数学联盟背书，警告 AI 公司未经同意使用已发表研究、绕过同行评审，正在侵蚀证明与署名的完整性。

**解读**：喝彩和愤怒其实是同一件事的两面。机器把"算不算得出来"这件事变便宜了，"这算不算数学、该记在谁名下"的问题反而变贵了。

> 来源：[The Next Web 报道](https://thenextweb.com/news/openai-astra-model-ten-math-proofs-non-sofic-groups) · [Daniel Litt 认输推文](https://x.com/littmath/status/2083733224027500584) · [Gary Marcus 评论](https://garymarcus.substack.com/p/openais-amazing-but-vastly-oversold) · [Leiden Declaration 官网](https://leidendeclaration.ai/)

---

## 菲尔兹奖得主 Tsimerman 领奖之后，转身去了 OpenAI

**7 月 23 日**，在费城举行的国际数学家大会（ICM 2026）上，多伦多大学数学家 Jacob Tsimerman 因证明"安德烈-奥尔特猜想"（André-Oort conjecture）中的关键部分获得 2026 年菲尔兹奖，是历史上第二位拿到这项荣誉的加拿大人。领奖同时他宣布：将从多伦多大学休假（保留教职），几周内动身去 OpenAI 做 AI 安全研究。《华尔街日报》**8 月 2 日**的一篇人物特写还原了他的判断：他相信 AI 很快会在数学上全面超过人类，"做得更好、更快"，甚至可能构成对人类的严重威胁，这也是他转向研究"如何让 AI 系统的行为在数学上可被确定"的原因。

**解读**：上一条新闻里，数学圈忙着争论 AI 证明该不该算数、该记谁的名字。Tsimerman 的选择是另一种回答：与其守住自己最擅长的领域，不如去研究怎么让下一代系统的行为本身可证。

> 来源：[Quanta Magazine 报道](https://www.quantamagazine.org/jacob-tsimerman-wins-2026-fields-medal-for-andre-oort-conjecture-proof-20260723/) · [BetaKit 报道](https://betakit.com/u-of-t-professor-jacob-tsimerman-who-won-maths-highest-prize-to-join-openai/)

---

## OpenAI 向十万名科研人员免费开放 ChatGPT

**7 月 29 日**，OpenAI 宣布启动"ChatGPT for Academic Researchers"计划：今年夏天先向一万名科研人员免费开放最新的 GPT-5.6 Sol Pro，到 2027 年扩大到十万人，每人还能再邀请四位同机构的合作者，享受更高的用量上限、更大的上下文窗口和更多深度研究额度。首批参与机构包括普林斯顿高等研究院、巴黎高等师范学院。OpenAI 称这是其到 2027 年累计投入超过 2.5 亿美元支持外部科研的一部分。

**解读**：把最强模型免费送给科研圈，换来的不只是口碑，也是更多"愿意较真"的用户帮忙挑错、试探边界。这周关于 Astra 的争论越大，这笔投入的算盘就打得越精。

> 来源：[OpenAI 官方博客](https://openai.com/index/chatgpt-for-academic-researchers/) · [SiliconANGLE 报道](https://siliconangle.com/2026/07/29/openai-opens-new-chatgpt-academic-researchers-program-100000-scientists/)

---

## 把这一周连起来看

这四条新闻拼在一起，其实是同一场辩论的四个切面。Astra 用两千美元解开十个尘封多年的难题，把"算出来"的门槛又砍低了一截；但零 sorry 的形式化证书换不来数学圈的一致认可，喝彩、愤怒和一场认输的赌局同时发生，说明"这算不算数学"本身还没有答案。Tsimerman 拿到这个领域最高的荣誉之后转身离开，赌的是"让系统本身可证"比"守住人类最后一块阵地"更值钱。OpenAI 则用真金白银把更多数学家、物理学家拉进场，某种程度上是在为未来的核验环节招募人手。算得动的东西越来越多，但谁来核验、谁来担责、荣誉记在谁头上，这些问题这周一个都没有解决，反而被摆得更明显了。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 07 期。
