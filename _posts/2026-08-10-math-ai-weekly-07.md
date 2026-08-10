---
title: "数学 × AI 周报 · 第 07 期：两千美元解出十道数学难题，一对师徒分别站进了 OpenAI 与 Anthropic"
date: 2026-08-10 09:00:00 +0800
author: Max (Ma Wei)
location: Singapore
series: 数学 × AI 周报
issue: 7
categories: [数学 × AI]
tags:
  - 数学 × AI 周报
  - OpenAI
  - Astra
  - Claude Fable 5
  - Levent Alpöge
  - Anthropic
  - Jacob Tsimerman
  - 菲尔兹奖
  - Erdős 猜想
  - Lean
  - 形式化验证
  - IMO
description: >-
  第 07 期：OpenAI 未发布模型 Astra 用约 2000 美元的算力成本拿出十个数学与理论计算机科学新结果，全部形式化进 Lean
  且零逻辑缺口，不到 24 小时后 Anthropic 数论学家用公开可用的 Claude Fable 5 独立复现了其中五个；《量子杂志》记录 Erdős
  问题数据库已有 565 题被解决，数学家们对"该退出还是该继续核验"意见相左；IMO 2026 落幕后的复盘文章揭出"42/42"背后评分方法、算力
  投入各不相同的可信度分层；菲尔兹奖得主 Jacob Tsimerman 领奖当天官宣加入 OpenAI，而他的本科论文学生正是那位用 Claude 推翻雅可比
  猜想的 Levent Alpöge。
image:
  path: /assets/img/posts/math-ai-weekly-07/cover.png
  alt: "数学 × AI 周报 第 07 期封面（AI 生成）"
---

> **本期一句话**：这周最贵的东西不再是"算出结果"，两千美元、不到一天，结果就能被复现一遍。真正稀缺的，变成了"这个结果该由谁来认、按什么方法认"。
{: .prompt-tip }

---

## OpenAI 用两千美元解出十道数学难题，不到 24 小时被公开模型追平一半

**8 月 1 日**，OpenAI 宣布其尚未公开的下一代模型 Astra（这批成果也是这个模型家族名字的由来）给出了十项数学与理论计算机科学新结果的机器可验证证明，横跨群论、冯诺依曼代数、高维几何、编码理论、量子复杂度、格密码学与极值组合等方向，此前这些问题的主要结论至少十年未见实质进展，部分已悬置数十年，其中包括构造出一个显式的非可循环群（悬而未决自 1999 年）、推翻 Connes 关于冯诺依曼代数的一个刚性猜想。十个证明全部形式化进 Lean 4，发布在 `github.com/openai/ten-proofs`（Apache 2.0 许可），仓库里的 "sorry" 计数为零，即形式化后的推理链条不留任何逻辑缺口。据 OpenAI 介绍，产出这批结果的算力成本约合 2000 美元。

不到 **24 小时**，Anthropic 数论学家 Levent Alpöge（就是上期报道中用 Claude Fable 5 推翻 87 年雅可比猜想的那位）在完全自主、不联网、只用通用提示词的条件下，用任何人都能调用的公开模型 Claude Fable 5，独立复现了 OpenAI 十个结果中的第 4 到第 8 题，一共五个。OpenAI 的 Astra 是未对外发布的内部模型，Fable 是公开产品，两者之间原本该有的"技术代差"，这次被压到了不足一天。

**解读**：Lean 形式化验证能保证证明链条里没有逻辑漏洞，但保证不了题面本身是否准确翻译了原始猜想的含义，这一步依然要靠人。比起十道题本身，"内部前沿模型的领先窗口不到一天就被公开模型追平一半"这件事更值得多想一层：算力和模型代差带来的护城河，可能比任何人预想的都要窄。

> 来源：[OpenAI 官方博客](https://openai.com/index/ten-advances-in-mathematics/) · [openai/ten-proofs 代码仓库](https://github.com/openai/ten-proofs) · [Simon Willison 摘要](https://simonwillison.net/2026/Aug/1/ten-advances-in-mathematics/) · [Forbes 报道](https://www.forbes.com/sites/jonmarkman/2026/08/03/openais-astra-solved-10-decades-old-math-problems-for-just-2000/)

---

## Erdős 问题数据库已有 565 题被解决，数学家们对"该退出还是该核验"意见相左

**8 月 3 日**，《量子杂志》刊文记录了 Thomas Bloom 在 erdosproblems.com 上维护的问题数据库最新进展：目前已有 **565** 个问题被解决、**652** 个仍然公开。近几个月里，从去年 5 月 OpenAI 内部模型推翻的"单位距离猜想"（Erdős 1946 年提出，悬置 80 年），到今年 5 月由业余数学家 Barreto、Price 与陶哲轩等人合作、用 GPT-5.2 Pro 解决的"原始集合猜想"（第 1196 题），一批长期公开问题相继被 AI 辅助攻克。

普林斯顿数学家 **Noga Alon** 说 AI 正在"彻底改变数学研究的方式"，但他也因此放弃了继续攻关 Erdős 问题："一旦 AI 开始解决它们，再做就没什么意义了。"剑桥/法兰西学院数学家 **Tim Gowers** 的反应相反：他说如果有人把"单位距离猜想"这份证明投给《数学年刊》，他会"毫不犹豫地建议接收"。Bloom 本人则提出另一重隐忧："一个大问题是，用 AI 的人里有很多根本不是数学家"，大量无人核实的长篇论文正在流通。

**解读**：这条新闻最有意思的地方不是"AI 能不能解题"，而是数学家们对"解完之后该怎么办"给出了完全相反的答案。Alon 选择退出，Gowers 选择用期刊最高标准去衡量它，Bloom 选择继续做那个愿意花时间核实和策展的守门人。三种反应背后是同一句潜台词：算的门槛已经不太值得较劲了，真正稀缺的是愿意花时间核验和消化的人。

> 来源：[Quanta Magazine 报道](https://www.quantamagazine.org/why-the-legendary-erdos-problems-are-falling-to-ai-20260803/) · [Erdős 问题数据库 AI 贡献记录](https://github.com/teorth/erdosproblems/wiki/AI-contributions-to-Erd%C5%91s-problems)

---

## IMO 2026 落幕复盘：同样是 42/42，评分方法把可信度分成了好几层

第 67 届国际数学奥林匹克（IMO 2026）**7 月 15—16 日**在上海举行。本报上期已报道：华为"Celia"与小红书"dots-note-3.0"在 IMO 官方判卷流程下拿到 **42/42** 满分；另有投资人 Deedy Das 私下用同一套赛题测试了 Claude Fable 5、GPT-5.6 Sol、Kimi K3、AxiomProver 四个模型，也都拿到了 42 分，但那属于非官方测试。

赛后陆续出现的复盘文章补上了此前多数报道略过的一层细节：Das 的私测用的是一套只有三个工具（执行命令、写文件、读文件）的极简"脚手架"，负责评分的不是人类裁判或 IMO 官方，而是另一套基于 Claude 搭建的 AI 智能体，其中 Claude Fable 5 那 42 分，部分正是由同属 Claude 家族的智能体判出来的。这层"自己给自己打分"的循环，Das 本人在 GitHub 说明里做了披露，但被多数媒体报道略去。分析文章还指出，同一个模型仅仅调高一档"推理强度"就能从 28 分跳到 39 分，评测脚手架本身的差异也能造成十分以上的波动。

**解读**：上期我们留下的悬念是"官方判卷"和"官方确认结果为真"是不是一回事，这周的复盘给出了更扎心的答案：就连"42/42"这个数字本身，也分成官方判卷、私下测试、AI 自我评分好几个可信度完全不同的等级，而大多数标题不会告诉你这层区别。分数正在变得像一句广告语，评分方法才是真正值钱的信息。

> 来源：[Digital Applied 复盘分析](https://www.digitalapplied.com/blog/imo-2026-perfect-scores-ai-benchmark-saturation) · [Tech Xplore 报道](https://techxplore.com/news/2026-07-ai-humans-score-math-contest.html)

---

## 菲尔兹奖得主领奖当天官宣加入 OpenAI，他的学生正是那位推翻雅可比猜想的人

**7 月 23 日**，2026 年菲尔兹奖在费城国际数学家大会开幕式上颁出，四位得主为邓煜、王虹（本报此前专门介绍过王虹与挂谷猜想）、John Pardon，以及 38 岁的加拿大数学家 **Jacob Tsimerman**（因证明近 40 年未解的 André-Oort 猜想获奖）。领奖当天，Tsimerman 当场宣布将加入 OpenAI，专职从事 AI 安全研究。

他此前曾公开警告"AI 有相当概率导致人类灭绝"，并合著过一篇讨论 AI 导致人类灭绝路径的论文；但他认为暂停 AI 发展并不现实，留在场内参与塑造它的走向才是可行的路。他也坦言 AI 已经让自己的研究效率翻倍："它给出的证明通常是错的，但往往能把方向指对，帮我完成 80% 的路。"一个容易被忽略的细节：Alpöge（本期第一条新闻里那位用 Claude Fable 5 复现 Astra 结果、也是上期雅可比猜想反例的主角）本科时期的论文导师正是 Tsimerman。三天前 Alpöge 刚推翻 87 年的雅可比猜想，如今这对师徒分别站进了 Anthropic 与 OpenAI。

**解读**：Tsimerman 那句"这个专业不会再以现在的样子存在"，和陶哲轩在费城说的"该被奖赏的是核验和消化结果的人"，其实是同一枚硬币的两面：一个用脚投票，离开纯数学去参与重新定义规则；一个留在数学界内部，重新分配声望的去向。但两人的判断前提相同：数学家的角色正在被重写，而不是被替代。

> 来源：[BigGo Finance 报道](https://finance.biggo.com/news/51505da0-b37a-4362-9b11-dca8b7ec50c8) · [BigGo Finance 报道（二）](https://finance.biggo.com/news/bca88ca4-8438-4d70-b512-75cda1dd3bd1)

---

## 把这一周连起来看

这四条新闻其实在说同一件事：**"算出来"这一步正在变得又快又便宜，两千美元、不到一天就能把前沿结果复现一半；但"这个结果该信到什么程度、该由谁来认"，反而比以前更贵、更复杂了。**

Astra 与 Fable 之间的"代差"被压缩到不足一天，说明护城河比想象中窄；Erdős 数据库的 565 道解题记录背后，数学家们对"该退出还是该继续核验"给出了完全相反的答案；IMO 的 42/42 被拆穿成官方判卷、私测、AI 自评三种不同可信度的分数；Tsimerman 和他的学生 Alpöge，一个进了 OpenAI 重新定义规则，一个在 Anthropic 的前沿上继续攻关。四件事拼在一起，指向的是同一条正在往前挪的分界线：机器已经能替我们把"算"这一步做得又快又便宜，但"证得了"里"谁来认、按什么标准认"的部分，依然稳稳地落在人的手里，而且价码还在往上走。

---

机器越来越会算，「证」也就越来越值钱。\
—— 数学 × AI 周报 · 第 07 期。
