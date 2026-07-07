---
title: "纯 Vibe Coding：用 Claude Code + Floniks 做 AI 时代的游戏（总览篇）"
date: 2026-07-07 10:00:00 +0800
author: Max (Ma Wei)
location: Singapore
categories: [AI-Native Engineering]
tags:
  - Vibe Coding
  - Claude Code
  - Floniks
  - MCP
  - AI 游戏开发
  - Rust
  - Bevy
  - Lua
  - WebAssembly
description: >-
  你只说"想要什么"，Claude Code 写代码、调 Floniks 生成素材、跑测试、自主迭代。本文用一整段真实的
  git 历史，7 步复盘我们如何用纯 vibe coding 做出一套浏览器直接可玩的小游戏合集——从一句话加一个解谜游戏，
  到用文生图/图生图/去背景/TTS/文生音乐做出一个悬疑微恐视觉小说，再到系统性 debug 与一键发布。
image:
  path: /assets/img/posts/vibe-coding-game-dev/cover.png
  alt: "纯 Vibe Coding 做 AI 时代的游戏"
wechat_source_url: https://maweis.com/posts/vibe-coding-game-dev/
---

> 你只说"想要什么"，Claude Code 写代码、调 Floniks 生成素材、跑测试、自主迭代。本文是**总览篇**（7 步方法论提纲）；两篇实战教程分别拆解一款游戏：上篇《[小马拼图]({% post_url 2026-07-07-pony-parade-tutorial %})》、下篇《[深夜画廊]({% post_url 2026-07-07-midnight-gallery-tutorial %})》。

上一篇《[AI 时代，应该有 AI 时代的游戏开发方式]({% post_url 2026-07-02-ai-era-game-dev %})》讲了"为什么"。这一篇讲"怎么做"——把我们这套方式一步一步拆开，全部来自真实的 git 历史，**你能照着复现**。

先说清楚这里的 **vibe coding** 是什么意思：你只说"想要什么"，不写提示词、不搬文件。**Claude Code** 把你的一句话展开成计划——读仓库约定、写代码、调 **Floniks** 生成素材、跑测试、自己修 bug、提交。你的角色从"操作工具的人"变成"定方向、验成果的人"。

它靠三件东西咬合成一个闭环：

| 角色 | 是什么 | 负责 |
| --- | --- | --- |
| **编排** | Claude Code | 读约定、写代码、跑测试、自主迭代 |
| **引擎** | Rust + Bevy + Lua | Rust 管渲染/跨平台，Lua 管玩法，命令队列解耦 |
| **素材** | Floniks（经 MCP） | 文生图 / 图生图 / 去背景 / TTS / 文生音乐，变成 agent 的工具 |

> 这不是愿景稿。下面每一步都有真实的踩坑与修复。成果是一套 12 个小游戏、浏览器直接可玩的合集：<https://maweis.com/rust_bevy_lua_game/>

---

## STEP 01 · 准备：一个为 agent 设计的项目

关键不在工具多强，在于**把上下文写进仓库**。项目根的 `CLAUDE.md` 不是给人看的 README，而是给 agent 的架构契约：Lua 怎么跟引擎通信、加一个游戏分几步、什么归 Rust 什么归 Lua。你在文档里说一次，胜过每次对话重复一百次——这就是"agent 会自行完善提示词"的真正含义。

然后把 Floniks 接进来，一行命令，素材工厂就出现在 agent 的工具箱里：

```bash
claude mcp add --transport http floniks \
  https://api.floniks.com/api/v1/mcp \
  --header "Authorization: Bearer mk_你的APIKey"
```

从此 agent 能调 `list_models`、`single_task`、`execute_workflow` 等工具——生成图像、跑工作流、查积分、取结果，全程无需你搬运文件。

## STEP 02 · 一句话，加一个游戏

最小的循环是这样的：

> **你说**：做一个 Queens / 数独变体的解谜游戏，8×8，每行每列每种颜色各放一匹小马，小马不能相邻。
>
> **agent 做**：新建一个 Lua 文件、写生成器（保证唯一解）+ 交互，自注册进菜单，补上一套无头测试断言规则不变量，跑绿，提交。

这就是《小马拼图》的由来。玩法逻辑全在一个 Lua 文件里，改一行、保存，桌面端**热重载**秒级生效——agent 的"写 → 验"循环因此是秒级的。而它写的生成器真的会**数解的个数**，只保留唯一解的棋盘。

![小马拼图运行截图](/assets/img/posts/vibe-coding-game-dev/ponyshot.webp)
_《小马拼图》——圆角瓦片、粗体中文标题、心数/倒计时/连胜 HUD，由 agent 按参考视频逐帧还原。完整过程见《[上篇教程]({% post_url 2026-07-07-pony-parade-tutorial %})》。_

## STEP 03 · 素材：让 Floniks 现场生成

程序员做游戏，卡住的从来不是代码，是美术。这里 agent 自己解决：它读一份"**可执行的风格圣经**"（锁死色板 / 描边 / 构图的 prompt DNA），只填每个素材的主体词，经 Floniks 文生图，再**去背景、缩放到精确像素**，按"同名同尺寸"的契约落进 `assets/textures/`——游戏零代码改动就换了皮肤。

> **你说**：小马要栗色的身体、奶油色鼻梁、飘逸鬃毛，侧视，透明底。
>
> **agent 做**：拼 prompt → Floniks 生成 → 抠底 → 48×48 落位 → 更新素材清单。同一条管线也产出十个 HUD 图标和圆角 UI 贴图。

连生成的 **15 秒玩法广告视频**也来自这条管线：真实素材逐帧渲染，配乐是 Floniks 文生音乐（Lyria 2）。

![小马拼图玩法广告帧](/assets/img/posts/vibe-coding-game-dev/adframe.webp)
_广告帧：手指演示放马 → 自动打 ✕ → 过关庆祝，画面元素全部是游戏里的真实素材。_

## STEP 04 · 让它更精美：反馈驱动迭代

第一版往往"能跑但糙"。你把不满意的地方拍给它，它就改。真实发生过的一轮：截图反馈"格子是生硬色块、字体不够圆润、要相机特效"——

- **贴图**：新写一个 8× 超采样生成器，产出可染色的圆角瓦片 / 粗体 ✕ / 胶囊 / 卡片。
- **引擎**：给引擎加 `game.zoom()`——放对轻推、放错重推、过关猛推近再回弹。
- **字体**：把字体换成 Noto Sans SC Bold 子集，逐字校验无缺字。
- **生成器**：盲重摇在 8×8 找不到唯一解，改用**爬山精炼**——首关从 237 个解收敛到 1 个。

注意最后一条：这是个真 bug，被**测试当场抓住**并逼着修好。测试就是 agent 的眼睛——它看不到屏幕好不好看，但能看到"唯一解"这条不变量有没有被破坏。

## STEP 05 · 做一个更复杂的：视觉小说

同一套方法能扛住更重的东西。《深夜画廊》是一个悬疑微恐的审讯视觉小说：名画《凝视者》失窃，你逐一询问三位女性证人，选问法、看她们表情变化、最后指认真凶。这一步把 Floniks 的多模态能力全用上了。

![深夜画廊 · 三位证人选择界面](/assets/img/posts/vibe-coding-game-dev/trio.webp)
_选人界面：三位证人并排（点击前移 + 震动 + 变焦）。立绘是透明抠图，干净地叠在夜画廊背景上。完整过程见《[下篇教程]({% post_url 2026-07-07-midnight-gallery-tutorial %})》。_

四种能力，一条链路：

- **立绘 · 文生图 + 图生图**：每个角色一张"文生图"底图，再用"图生图"派生**平静 / 紧张 / 惊惧**三种表情——同一张脸，不同情绪。再过去背景，得到透明立绘。
- **语音 · TTS，一人一音色**：三位证人三个真实不同的女声（少女 / 播报 / 御姐），一人固定一个，声学验证过基频各异（291 / 202 / 158 Hz）。
- **氛围 · 文生音乐**：Lyria 2 生成的暗黑氛围循环乐，铺在对话之下。
- **剧情 · 分支对话树**：打字机字幕 + 选项分支；问对关键线索会让立绘切到惊惧表情，问软了被搪塞。

![三位证人立绘：平静表情](/assets/img/posts/vibe-coding-game-dev/portraits.webp)
_同一条管线保证角色一致性：底图定人，图生图派生表情。_

![深夜画廊 · "凝视者"惊悚场景](/assets/img/posts/vibe-coding-game-dev/scene.webp)
_"凝视者"场景：把干净的画廊底图用图生图改成惊悚变体——墙上多了一张盯着你的画。微恐氛围，全部生成。_

## STEP 06 · 系统性打磨：真实的 debug 循环

Vibe coding 不等于不出 bug，而是**你报现象、它找根因**。这个项目里真实发生、并被系统性解决的几个：

| 你报现象 | 它找根因 + 修 |
| --- | --- |
| 网页版没声音 | 浏览器把 AudioContext 初始为 suspended，需首次交互解锁——在页面里首次点击时 resume 全部音频上下文 |
| 立绘被背景挡住别人 | 立绘带烘焙底 → 9 张全过 Floniks 去背景抠成透明；缓存又拦了 → 改文件名绕过浏览器缓存 |
| 音轨乱，多条声音叠着放 | 缺声道模型 → 引擎重构成三声道：SFX 可叠但每帧去重、Music 同名不重启、Voice 单条对话（播新的先掐旧的） |

> 每一次修复都带一条回归测试或验证。到现在这套无头测试套件已有 **13 万+ 项断言**——它是 agent 敢自主迭代的底气。

## STEP 07 · 发布：浏览器里就能玩

同一份 Rust crate 编成桌面、iOS 和 WebAssembly 三份。合并到主分支即自动部署到 GitHub Pages——一条链接，手机浏览器直接玩，无需下载。

```bash
git push        # 合并到 main
# → CI 编译 wasm → 发布 GitHub Pages → 上线
```

👉 [在浏览器里试玩](https://maweis.com/rust_bevy_lua_game/) · [查看开源代码](https://github.com/maweis1981/rust_bevy_lua_game)

---

## 为什么这套方式成立

- **上下文写进仓库**。`CLAUDE.md` / `PACK_SPEC` / `ART_REQUESTS` 是 agent 的资深架构师。约定写一次，永久生效。
- **测试当 agent 的眼睛**。它看不到画面，但能看到不变量。有机器可验证的"对"，才敢自主迭代。
- **Floniks 当素材工厂**。经 MCP，生成能力变成普通工具。模型升级 = 换个 id 重放，架构不动。
- **你只出意图和验收**。不写提示词、不搬文件。你定方向、验成果；计划、代码、素材、测试都归 agent。

一个人加一个 agent，晚上留一句话，早上收一串带着绿色测试的提交。这就是我们认为的、属于 AI 时代的游戏开发方式。

> 本文所有截图、立绘、语音、音乐均来自本项目真实的构建过程与 Floniks 生成管线。开源脚手架 [rust_bevy_lua_game](https://github.com/maweis1981/rust_bevy_lua_game)；素材平台 [Floniks](https://floniks.com)（MCP 端点 `api.floniks.com/api/v1/mcp`）；编排 Claude Code。

