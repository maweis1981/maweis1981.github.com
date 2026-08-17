---
title: "数学 × AI 周报 · 第 07 期：黎曼零点密度被顶到 67.2%，一份「生证明」要陶哲轩亲自消化八天"
date: 2026-08-17 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 7
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - 黎曼猜想
  - Anthropic
  - Claude
  - 森多夫猜想
  - 陶哲轩
  - Lean
  - 形式化验证
  - OpenAI
  - Astra
  - 学术诚信
description: >-
  第 07 期：Anthropic 未发布的研究版 Claude 用两轮 Claude Code、共 3100 万 token，把黎曼ζ函数零点密度的已证下界从
  41.6% 顶到 67.2%，官方同时说清楚这不等于证明黎曼猜想；数学爱好者 Lech Mazur 借 GPT-5.6 Pro 拿下悬置近 70 年的森多夫猜想，陶哲轩花八天把这份九万多行的「生证明」消化、重新形式化，压到一万五千行；OpenAI 十项数学突破被数学家指控引用不实，卷入"研究不端"争议。
image:
  path: /assets/img/posts/math-ai-weekly-07/cover.png
  alt: "数学 × AI 周报 第 07 期封面（AI 生成）"
---

> **本期一句话**：这周最扎眼的不是又一个猜想倒下，是"倒下之后谁来收拾"。Claude 把一个数论下界顶过了三分之二，自己先说清楚这证不了黎曼猜想；一份 AI 生成的森多夫猜想证明，被陶哲轩关起门消化了八天才能读。与此同时，OpenAI 的十项数学突破里，有两项被当面指认"抄了却不写名字"。算得快和讲得清，这周又分出了胜负。
{: .prompt-tip }

---

## Claude 把黎曼零点密度下界顶到 67.2%，官方自己划了边界

**8 月 10 日**，Anthropic 发布研究页面：一个未发布的研究版 Claude，把黎曼ζ函数零点中"落在临界线上"那部分零点所占比例的已证下界，从 **41.6% 顶到了 67.2%**，提升 25.6 个百分点，是这个常数首次被顶过一半。过程分两轮 Claude Code 会话：第一轮生成了 650 个想法，全部失败；第二轮耗时约一天半，编排约 60 个子代理，跑了 2400 条 shell 命令，消耗 3100 万个输出 token，最终找到一种把两篇已有论文结合起来的思路，此前没人这么组合过。**Anthropic 在公告里明确写道**："我们不认为 Claude 用的这套技巧能通向黎曼猜想本身的证明"，这只是黎曼猜想相关技术工具箱里一条分支上的下界改进。结果先由内部数论学家 Levent Alpöge（上期雅可比猜想反例那位）与 Ralph Furman 审读，又请外部数论专家 Brian Conrey、Dan Goldston 复核；Claude 还和 Anthropic 员工 Eric Easley 一起把结果做成了 Lean 4 形式化版本。

**解读**：这条新闻的看点不是 67.2% 这个数字，是 Anthropic 把"这不等于证明黎曼猜想"写在了公告最显眼的位置，还配了两位外部专家背书和一份 Lean 形式化。比起"我们又赢了一个猜想"的营销话术，这更像是把"讲清楚边界"当成了交付的一部分。

> 来源：[Anthropic 官方研究页面](https://www.anthropic.com/research/riemann-zeta) · [Tech Times 报道](https://www.techtimes.com/articles/324173/20260812/claude-raises-riemann-zeta-zeros-672-two-papers-no-one-had-combined.htm)

---

## 森多夫猜想被拿下，陶哲轩花八天把「生证明」消化成论文

**8 月 5 日**，数学爱好者 Lech Mazur 借助 GPT-5.6 Pro，通过 ProofAtlas 平台的验证工作流，拿出了森多夫猜想（Sendov's Conjecture，1958 年提出：单位圆盘内的多项式，每个根附近单位距离内都存在一个临界点）对所有阶数的完整证明，顺带解决了相关的 Phelps-Rodriguez 猜想。证明在 Lean 里通过了形式化核验，但原始版本有 1160 个文件、92816 行代码，不是给人读的东西。**8 月 12 日**，陶哲轩在博客发文《森多夫猜想证明的消化》，说他花了好几天、重度借助 AI，把这份"生证明"放回合适的文献脉络里，抽出主干逻辑；随后他和 Claude Opus 5 合作重新做了一遍形式化，压缩到 80 个文件、15152 行代码，不用区间算术和浮点数，全靠精确有理数的伯恩斯坦证书，代码里除声明文件外没有一处"sorry"（未完成标记）。

**解读**：Mazur 那份能过 Lean 的证明，严格意义上已经"证明"了。但没人读得懂它在说什么，直到陶哲轩把它"消化"成一份人能看懂的论文，顺手把代码量压掉了六分之五。机器把猜想变成了一堆逻辑上无懈可击、却没有意义的符号，是人把它变回了数学。

> 来源：[GitHub · teorth/sendov 形式化仓库](https://github.com/teorth/sendov) · [HyperAI 报道](https://hyper.ai/en/stories/2151971ca8a6d993ce56e176696db431) · [陶哲轩博客原文](https://terrytao.wordpress.com/2026/08/12/a-digestion-of-the-proof-of-sendovs-conjecture/)

---

## OpenAI 十项数学突破被指"抄了却不写名字"

**7 月 31 日**，OpenAI 发布一份 249 页的 PDF，宣布未发布模型 Astra 在数学与理论计算机科学领域拿下十项进展，涵盖高维球体堆积、群论 sofic 性等多个方向，称总算力成本约 2000 美元。**8 月 6 日**，多家媒体报道，数学家指控其中至少两项结果引用不实。耶什瓦大学数学家 Steven Miller 说，球体堆积那道题里的核心论证最早出现在他 2016 年的论文里："他们是在有意地、系统性地无视前人的工作"，直言这是研究不端；剑桥大学群论学家 Francesco Fournier-Facio 说，sofic 性那项结果实际上是把 2016 年和 2019 年两篇论文的思路拼在一起，却没写清楚。OpenAI 回应称对结果正确性负责，计划本周做"小幅更新"以符合学术规范。

**解读**：这条新闻和前两条正好构成对照。前两条里，不管是 Anthropic 还是陶哲轩，都在主动补"讲清楚"这一课；这一条里，漏掉的恰恰是数学写作最基本的一条规矩：引用。算对一道题，和写出一篇够格的论文，从来不是同一件事。

> 来源：[Yahoo News 转载 Scientific American 报道](https://www.yahoo.com/news/science/articles/openai-latest-math-breakthroughs-commit-184300525.html) · [AI Weekly 快讯](https://aiweekly.co/alerts/openais-astra-math-proofs-draw-research-misconduct-claims)

---

## 把这一周连起来看

三条新闻站在同一门功课的两侧。算得快这件事本周继续刷新纪录：Claude 一天半把一个数论下界顶了 25.6 个百分点。但真正决定这些结果能不能进数学史的，从来不是算得多快，是围绕它的那圈"讲清楚"的功夫。Anthropic 自己划清了"这不是证明黎曼猜想"的边界，还找外部专家核验；陶哲轩花八天把一份没人读得懂的生证明，消化成一篇讲得清道理的论文；而没做到这一步的 OpenAI，这周就被数学家当面指出了漏洞。机器算得越快，人和形式化系统要补的功课就越多。这周的三条新闻，恰好分别站在了这门功课的两侧。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 07 期。
