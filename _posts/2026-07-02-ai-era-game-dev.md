---
title: "AI 时代，应该有 AI 时代的游戏开发方式"
date: 2026-07-02 20:00:00 +0800
author: Max (Ma Wei)
location: Singapore
categories: [AI-Native Engineering]
tags:
  - AI 游戏开发
  - 游戏引擎
  - Rust
  - Bevy
  - Lua
  - MCP
  - AIGC
  - 游戏美术
  - Agentic Coding
  - Claude Code
  - 独立游戏
  - 开源项目
  - Floniks
description: >-
  游戏行业在裁员、内卷和美术产能死结中焦虑，而 AI 时代需要 AI 时代的开发方式。本文给出一个今天就能跑起来的开源方案：Rust + Bevy + Lua 游戏脚手架负责引擎与玩法分层，Floniks 通过 MCP 协议把 AI 美术素材生成能力直接交到 coding agent 手里，配合 agentic coding 与 loop 模式，实现"agent 写玩法 → 按需生成素材 → 跑测试验证 → 自主迭代"的完整闭环。
image:
  path: /assets/img/posts/ai-era-game-dev/cover.jpg
  alt: "AI 时代的游戏开发：玩具盒里的游戏世界，AI agent 正在用画笔把新的素材画进去"
---

> **TL;DR（太长不看版）**
>
> 1. **痛点**：游戏行业收入创新高但两年裁掉 2.5 万人；Steam 每天上架 50 多款游戏、约 80% 无人问津；美术占 AAA 预算 25–30%，是独立开发者最大的产能死结。
> 2. **判断**：代码 agent 不会画画，素材工具不进工具链，meme 游戏平台不留代码——现有方案都是孤岛，缺一个闭环。
> 3. **方案**：开源的 **Rust + Bevy + Lua 游戏脚手架**（引擎归 Rust、玩法归 Lua、验收归无头测试）+ **Floniks**（通过 **MCP 协议**把文生图/图生图/去背景/序列帧等美术生成能力变成 agent 的普通工具）+ **agentic coding**（你出意图，agent 出代码、素材和测试）。
> 4. **结果**：一个人加一个 agent，晚上留一句话，早上收一串带绿色测试的 commit。本文所有游戏截图和配图，均由这套流程产出。
{: .prompt-tip }

**—— 一个开源的 Rust + Bevy + Lua 游戏脚手架，加上通过 MCP 接入的 Floniks 素材生成平台，再加上 agentic coding：我们正在实践的下一代游戏开发工作流。**

> 本文既是一篇观点文章，也是一份可以照着做的教程。上半部分讲"为什么"：游戏开发工具的历史、今天开发者的真实处境；下半部分讲"怎么做"：我们的开源项目怎么用、Floniks 怎么通过 MCP 嵌进开发循环、agent 怎么在 loop 模式下自主迭代出一个完整的游戏。
{: .prompt-info }

## 一、每个时代，都有那个时代的游戏开发方式

游戏开发的历史，本质上是一部"开发方式"的历史。每一次工具的换代，都重新定义了"谁能做游戏"和"做游戏需要多少人"。

![游戏开发方式的四个时代：从汇编裸机、自研引擎、大众化引擎到 AI agent 协作开发](/assets/img/posts/ai-era-game-dev/eras.jpg)
_从裸机汇编到 AI agent：每一次工具换代，都重新定义"谁能做游戏"_

### 1. 裸机汇编时代（1970s–1980s）：一个人就是一支团队

Atari 2600（1977）只有 128 字节 RAM，卡带最初只有 4KB ROM。游戏用 6502 系汇编直接写在裸机上，一名工程师包办设计、编码、美术和音效。Warren Robinett 一个人写完了《Adventure》（1980）——因为 Atari 拒绝给程序员署名，他把自己的名字藏进了一个秘密房间，这成了公认的第一个游戏彩蛋。也正是这种"不署名"文化，逼走了一批 Atari 程序员去创立了 Activision（1979），世界上第一家第三方游戏开发商。

这个时代的开发方式：**人直接对硬件负责，没有工具，工具就是你自己。**

### 2. C 语言与自研引擎时代（1980s 末–1990s）：引擎第一次成为"产品"

《DOOM》（id Software，1993 年 12 月发布）用 C 加少量汇编写成，《Quake》（1996）紧随其后。真正的分水岭是 id 开始把引擎授权出去：Valve 的《半衰期》（1998）跑在 GoldSrc 上——一个深度改造的 Quake 引擎。**"引擎"第一次从内部工具变成了可以出售的产品。**

### 3. 引擎授权与中间件时代（1990s 末–2000s）：分工开始出现

Unreal Engine 随《Unreal》在 1998 年面世，与 id 的"只给源码"不同，Epic 提供主动的授权方支持——到 1999 年底已有 16 个外部项目跑在 Epic 的技术上，包括《杀出重围》。中间件也在同期兴起：Havok 1998 年创立于都柏林，其物理 SDK 1.0 在 2000 年 GDC 上亮相。

这个时代的开发方式：**买引擎、买中间件，团队规模开始膨胀，"从零写引擎"不再是做游戏的前提。**

### 4. 民主化时代（2005–2015）：引擎属于每一个人，脚本语言进入引擎

Unity 在 2005 年 6 月的苹果 WWDC 上发布（最初只支持 Mac OS X），使命写得很直白："democratize game development"（让游戏开发民主化）。2008 年 7 月 App Store 上线，Unity 迅速跟进 iPhone 支持，移动淘金潮开始。Steam Greenlight（2012）和后来的 Steam Direct（2017，100 美元可回收门槛）把发行的门也打开了。

这个时代还有一条暗线：**脚本语言成为游戏逻辑的正统载体**。Lua 于 1993 年诞生于巴西里约热内卢天主教大学（PUC-Rio），设计目标就是"小巧、可嵌入的扩展语言"——宿主程序注册函数，Lua 脚本来编排它们。LucasArts 的《冥界狂想曲》（1998）让 Lua 在游戏界一战成名；此后《魔兽世界》的整个 UI/插件系统是 Lua，Roblox 用 Lua 方言 Luau 支撑了千万创作者，LÖVE 和 Defold 干脆是 Lua 优先的引擎。**"引擎管性能，脚本管玩法"的分层，是这个时代留给我们最重要的遗产。**

### 5. 军备竞赛时代（2015–2023）：写实主义的代价

Unreal Engine 5（2022 年正式发布，Nanite/Lumen）把画面天花板推到了新高度，代价是预算和团队规模的失控：《赛博朋克 2077》连同上线后的修复和资料片，总投入据 CDPR 财报披露约 4.4 亿美元；GTA 6 的总预算被分析师估到 10–20 亿美元（官方从未确认，只承认"很贵"）。AAA 团队常态化地达到数百人，GTA 级别的项目接近千人。

单人开发者呢？他们得到了引擎，得到了资产商店，但也得到了一个前所未有拥挤的市场——这是下一节的主题。

### 6. 那么，AI 时代呢？

2023 年之后，AI 辅助开发进入视野。而就在最近这几天，一个信号变得再明显不过：App Store 上一款叫 **Rezona: Make Memeplays** 的产品爆红了。它的玩法是——你用一句话描述一个梗、一个脑洞、一段"脑腐"创意，**agent 当场把它做成一个可以玩的小游戏**（他们管这叫 "memeplay"），然后像刷 TikTok 一样在无限信息流里刷别人做的游戏，可玩、可评论、可 remix。不用代码，不用引擎，不用教程。上线仅数月，下载量已达约 840 万，安卓端月活约 120 万，冲进娱乐榜前 100。媒体把这个现象称为"**游戏的 TikTok 时刻**"——"游戏用一个周末做出来，被玩上一个星期"，围绕一个梗、一个文化事件的互动体验，像发一条短视频一样随手创作、随手分享。

Rezona 的爆火证明了两件事。**第一，需求侧已经验证完毕**：普通人渴望"说一句话就得到一个游戏"，玩家也真的愿意玩 agent 做出来的游戏——这不再是论文里的猜想，是榜单上的事实。**第二，也暴露了缺口**：memeplay 是消费品，不是作品。它的产出锁在平台里——没有你能拿走的代码，没有可维护的工程，没有测试，火一周就沉底，更谈不上打磨成一款能上架、能长期迭代的产品。从"一句话生成的玩具"到"一个团队可以长期经营的游戏"，中间隔着的正是**一整套属于 AI 时代的开发方式**——有的只是散落的碎片，还没有人把它拼成完整的工具链。这正是我们这个项目想回答的问题。

## 二、今天的游戏开发者，在焦虑什么

在谈解决方案之前，先诚实地看一眼行业的现状。这些数字都有公开来源。

**裁员。** 2023 年全行业约 10,500 人被裁；2024 年更是创纪录的一年，仅第一季度就裁掉 8,619 人（游戏史上最高的单季数字），2023–2024 两年合计超过 25,000 人；2022–2025 累计约 44,000–45,000 个岗位消失。GDC《State of the Game Industry 2026》调查（约 3,000 名开发者）显示：28% 的受访者在过去两年内被裁过（美国是 33%）。而讽刺的是，2025 年行业收入还创了新高（约 2,016 亿美元）——**行业在增长，岗位在消失。**

**淹没。** 2024 年 Steam 上架了近 19,000 款游戏，2025 年约 19,468 款——平均每天 50 多款。据 Kotaku 统计，2024 年的近 19,000 款里只有约 4,041 款摆脱了 Valve 的"limited"状态，也就是说**约 80% 的游戏几乎没有玩家、没有销量**。做出来只是起点，被看见才是生死线，而被看见的前提是足够快地迭代、足够高的完成度。

**美术瓶颈。** 业内通常估计美术与动画占 AAA 制作预算的 25–30%。对独立开发者和小团队来说，这个比例的含义更残酷：程序员出身的单人开发者，卡住他的从来不是代码，而是 sprite、贴图、序列帧、UI、音效——每一样都是他不擅长、外包又贵又慢的东西。一个佐证：在 Steam 的 AI 使用披露中，**约 60% 是用于视觉素材生成**——小团队最先向 AI 求援的，恰恰是美术。

**对 AI 本身的焦虑。** GDC 调查里，对生成式 AI 持负面态度的开发者比例从 2024 年的 18% 涨到 2025 年的 30%，再到 2026 年调查的 52%；最悲观的正是视觉/技术美术（64%）。SAG-AFTRA 的游戏配音演员罢工持续了近一年（2024.7–2025.7），核心议题就是 AI 数字替身的许可与披露。与此同时，使用率却在上升：2025 年 Steam 新游戏中约五分之一披露使用了生成式 AI，同比增长约 7 倍。**采用率与反感度同时飙升**——这说明问题不在"用不用 AI"，而在"以什么方式用"：是把 AI 当成压缩人力的借口，还是把它变成让小团队获得大团队能力的杠杆。

**过劳。** Rockstar 的"100 小时周"风波（2018）、CDPR 上线前的强制六天工作制（2020）——旧的开发方式已经把人的极限当成了排期资源。

把这些焦虑放在一起，会看到一个清晰的缺口：

> **代码 agent（Claude Code、Cursor）不会画画；素材生成工具（Meshy、Scenario）产出的文件需要人手动导入、接线、调参；世界模型（Oasis、Genie 3）干脆绕过了工具链，产出的东西不可维护；meme 游戏平台（Rezona）验证了海量需求，却把产出锁在自己的平台里——没有代码、没有工程、没有沉淀。几个孤岛，没有闭环。**
{: .prompt-warning }

没有任何一个主流方案打通了这个循环：**agent 写玩法代码 → 按代码的需要精确地生成素材 → 跑测试验证 → 自主迭代**。这个闭环，就是我们在做的事。

## 三、我们的答案：一个 AI 原生的游戏开发体系

我们的体系由三部分组成，各自解决闭环的一段：

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code（编排者）                       │
│         agentic coding · loop 模式自主迭代 · 无需手写提示词       │
└──────────┬────────────────────────────────┬─────────────────┘
           │ 读写代码 / make test            │ MCP（21 个工具）
           ▼                                ▼
┌─────────────────────────┐    ┌─────────────────────────────┐
│  开源脚手架（本仓库）        │    │  Floniks（api.floniks.com）  │
│  Rust + Bevy 0.19 引擎层  │    │  AIGC 工作流平台              │
│  Lua 5.4 玩法层（热重载）   │    │  文生图/图生图/图生视频/音频     │
│  无头不变量测试套件          │    │  DAG 工作流 · 批量 · 去背景    │
│  桌面开发 → iOS 真机发布    │◄───│  素材直接落入 assets/ 目录     │
└─────────────────────────┘    └─────────────────────────────┘
```

- **引擎与玩法分层（开源脚手架）**：Rust + Bevy 管渲染、ECS、跨平台；Lua 管全部玩法逻辑，桌面端热重载，改一行脚本立刻生效。这是为 agent 的"改代码→看效果"循环优化过的结构。
- **素材供给（Floniks）**：一个多模型 AIGC 工作流平台（FAL、MiniMax、Hailuo、APImart 等提供商统一在一个 DAG 工作流引擎之后），通过 MCP 协议把生成能力直接交到 agent 手里——sprite、贴图、序列帧、参考图，按需实时生成，直接集成进游戏。
- **编排（Claude Code）**：开发者说"加一个太空射击游戏"，agent 自己读 CLAUDE.md 里的架构约定、自己写 Lua、自己调 Floniks 生成素材、自己跑测试、自己修 bug。**你不需要写提示词——agent 会自行完善**；配合 loop 模式，它还能在没有你的情况下继续迭代。

下面分别展开。

## 四、开源项目：Rust + Bevy + Lua 的游戏脚手架

仓库：[`rust_bevy_lua_game`](https://github.com/maweis1981/rust_bevy_lua_game)（内部代号 hollowlullaby）。全部代码约 4,000 行，跑在 macOS（开发）和 iOS（发布）上，目前内置 9 个小游戏：Grow the Paddle（Pong 变体）、Breakout、贪吃蛇、Roguelike 生存、2048、复古太空射击、Cozy Isle（动森式沙盒）、Garden Match（花园消消乐）、Umami Cup（和风口袋体育对战），另有一套"往 `scripts/packs/` 里丢一个 `.lua` 文件就自动上菜单"的热插拔 game pack 机制。

先看两张真机/模拟器截图——**画面里的每一个 sprite、每一张背景，都是这套 AI 流程生成的**，没有一个人类美术参与：

![游戏合集菜单：8 个小游戏的图标均由 AI 生成，玩具盒卡通风格](/assets/img/posts/ai-era-game-dev/menu.png){: width="400" .shadow }
_iPhone 上的游戏合集菜单，图标 sprite 全部由 Floniks 生成_

![Garden Match 花园消消乐实机截图：AI 生成的花园背景与消除棋子素材，风格化卡通玩具盒美术](/assets/img/posts/ai-era-game-dev/garden-match.png){: width="400" .shadow }
_Garden Match：花园背景、蘑菇/草莓/花朵棋子，全部素材来自 Floniks 的文生图 + 去背景流水线_

![Umami Cup 和风体育对战小游戏实机截图：AI 生成的榻榻米球场、鸟居球门与和风角色](/assets/img/posts/ai-era-game-dev/dojo-pong.png){: width="400" .shadow }
_Umami Cup：榻榻米球场、鸟居球门、和风小人和豆沙团子"球"，同样出自 AI 素材流水线_

### 4.1 为什么是这三样东西

**Rust + Bevy 负责"不该经常变的部分"。** Bevy 是 2020 年发布的开源 Rust 引擎（MIT/Apache 双许可），核心是一个高性能并行 ECS。渲染、资产管线、音频、输入、跨平台（同一个 crate 编成桌面 `rlib` 和 iOS `staticlib`）都在这一层。Rust 的类型系统和借用检查器在这里是资产而不是负担——**引擎层写对一次，就很难被 agent 或人改坏**。

**Lua 负责"应该天天变的部分"。** 全部玩法逻辑在 `assets/scripts/*.lua` 里。选 Lua 不是怀旧，而是它 1993 年的设计目标在 2026 年恰好命中 agent 的需求：

1. **可嵌入**：`mlua`（vendored 特性把 Lua 源码编进 crate）让 Lua 5.4 无痛跨编译到 iOS；
2. **小而稳定**：语言表面积小，LLM 对 Lua 的掌握极其扎实，生成的代码几乎不会有语法幻觉；
3. **热重载**：脚本作为 Bevy 自定义资产（`LuaScript` + `AssetLoader`）加载，桌面端开着游戏改脚本，保存即生效——**agent 的每一次修改都能在秒级得到反馈**；同一套机制在 iOS 上自动变成从 app bundle 加载，零额外代码。

**约定负责"让 agent 不迷路"。** 仓库根的 `CLAUDE.md` 不是给人看的 README，而是给 agent 看的架构契约：Rust↔Lua 边界在哪、加 API 的三步法是什么、什么改动属于 Rust 什么属于 Lua（"如果你发现自己在为了调玩法数值而重新编译 Rust，说明这段逻辑应该搬进 Lua"）。**在 AI 时代，仓库里的约定文档就是团队里的资深架构师。**

### 4.2 核心设计：Lua 永远不直接碰引擎

这是整个脚手架最重要的一条不变量。Lua 不持有 Bevy `World` 的任何引用——那会要求跨 FFI 持有 `&mut World`（借用检查器的噩梦），还会强迫单线程的 Lua VM 变成 `Send + Sync`。取而代之的是一个**命令队列**：

1. `LuaVm` 是 Bevy 的 **NonSend 资源**，它的系统固定跑在主线程；
2. 暴露给 Lua 的宿主函数（全局 `game` 表）只做一件事：往队列里**推一条 `LuaCommand` 意图**；
3. Rust 系统先跑 Lua 回调，再**排空队列、逐条应用**到 ECS。

```rust
// src/script.rs —— Lua 能对世界做的所有事，一个枚举说完
enum LuaCommand {
    Spawn { id: u32, x: f32, y: f32, w: f32, h: f32, color: (f32, f32, f32, f32) },
    MoveTo { id: u32, x: f32, y: f32 },
    SetColor { id: u32, color: (f32, f32, f32, f32) },
    SetSize { id: u32, w: f32, h: f32 },
    SpawnText { /* … */ },
    SpawnSprite { id: u32, x: f32, y: f32, w: f32, h: f32, image: String },
    Despawn { id: u32 },
    SetText(String),
    Shake(f32),
    PlaySound(String),
    PlayMusic(String),
    Haptic(i32),
}
```

每帧的顺序固定为：`reload_changed_scripts → tick_lua → apply_lua → camera_shake`。`tick_lua` 在调用 `on_update(dt)` **之前**把输入快照（指针的世界坐标、按住的键、屏幕尺寸）写进桥接数据，Lua 里的 `game.pointer()` / `game.key(name)` 读的是快照——读路径和写路径都不触碰 `World`。

这个设计对 agent 的意义：**Lua 里无论写出什么代码，都不可能让引擎崩溃或产生数据竞争**。玩法层是一个安全的沙盒，agent 可以在里面放开手脚，最坏的结果是逻辑 bug——而逻辑 bug 有测试兜底（见 4.4）。

Lua 侧的完整 API 一屏就能看完（这同样是刻意的——API 表面积小，agent 记得住、用得对）：

| 类别 | 函数 |
|---|---|
| 读 | `game.bounds()`、`game.pointer()`、`game.key(name)` |
| 实体 | `game.spawn(x,y,w,h,r,g,b[,a])`、`game.spawn_sprite(x,y,w,h,name)`、`game.spawn_text(…)`、`game.move_to(id,x,y)`、`game.set_color(…)`、`game.set_size(…)`、`game.despawn(id)` |
| 表现 | `game.set_text(s)`、`game.shake(0..1)`、`game.play_sound(name)`、`game.play_music(name)`、`game.haptic("light"/"medium"/"heavy"/"success")` |
| 调试 | `game.log(msg)` |

### 4.3 游戏 = 一个闭包：场景路由器

`assets/scripts/main.lua` 是一个场景路由器：菜单列出所有游戏，每个游戏是一个 `make_*` 闭包，返回 `{ enter, update, tap, leave }` 四个回调，自己追踪自己生成的实体（离开时统一销毁）。写一个新游戏的最小骨架长这样：

```lua
local function make_mygame()
  local T = GAME_KIT.tracker()          -- 记录生成的实体 id，leave 时统一清理
  local back, built = nil, false
  return {
    enter = function() built = false end,
    leave = function() T.clear(); built = false end,
    tap = function(x, y)
      if back and GAME_KIT.in_rect(back, x, y) then GAME_KIT.switch("menu") end
    end,
    update = function(dt, hw, hh)
      if not built then
        back = GAME_KIT.make_back(T, hw, hh)   -- 左上角的 BACK 按钮
        DEBUG = { game = "mygame", back = back } -- 暴露给无头测试
        built = true
      end
      -- 玩法在这里：读 game.pointer()/game.key()，驱动 game.move_to(...)
    end,
  }
end
```

新游戏可以放在独立的 `.lua` 文件里（如 `shooter.lua`、`game2048.lua`），注册一个全局工厂函数即可；`main.lua` 用 `if make_shooter then …` 的方式条件挂载——**一个游戏的脚本坏了，不会拖垮菜单和其他游戏**。这种模块隔离对 agent 尤其友好：它添加第 10 个游戏时物理上碰不到前 9 个的代码。

### 4.4 测试：agent 自主迭代的安全网

`make test` 跑两层测试，其中关键的是 `tools/test_pong.lua`——一个数百行的**无头玩法不变量套件**。它用纯 Lua mock 掉整个 Rust `game` API（生成的实体记录在表里，`math.random` 被替换成可控的 LCG 以强制球的颜色），然后驱动真实的 `main.lua` 跑几千到几万帧，断言的是"手感契约"而不是实现细节：

- 挡板和球**永不瞬移**（`|Δ位置| ≤ 最大速度 × dt`）、**永不穿透**（对比挡板的*当前*高度）；
- 球速有上限、球永在屏幕内、大 `dt` 卡顿帧不会让任何东西飞出去；
- 绿球命中必须触发变大 + 音效 + 成功震动；铺满屏幕 = 胜利，落地 = 失败，两者都可达；
- 贪吃蛇每帧最多走一格、吃了会长、撞墙会死；2048 的每个格子永远是 0 或 2 的幂；射击游戏开局必须是完整的 5×4 敌阵……

这个套件不是摆设：**它抓到过球速无上限和 `dt` 未钳制两个真实的手感 bug**（见 git 历史 `c3f4043 "Add automated gameplay tests; fix two feel bugs they caught"`）。

对 agent 而言，这层测试的意义再怎么强调都不过分：`make test` 是 agent 的眼睛。它看不到屏幕上球滚得顺不顺，但它能看到 `PASS — all games' invariants held`。**有了机器可验证的"手感契约"，agent 才敢自主迭代**——这就是 loop 模式成立的前提（见第六节）。

### 4.5 素材管线：占位符先行，AI 素材即插即用

仓库里的初始音效和贴图都是程序化生成的占位资产：

- `tools/gen_audio.py`：纯 Python 标准库合成 WAV——击打音、墙壁音、C5-E5-G5 得分琶音、一段 Am-F-C-G 四和弦循环 BGM（带起落包络和环绕式音符排布，循环无接缝）；
- `tools/gen_textures.py` / `gen_sprites.py` / `gen_world.py`：手写 PNG 编码器（不依赖 PIL）产出像素风 sprite，射击游戏的用 4×4 超采样抗锯齿。

关键在 `assets/ART_REQUESTS.md` 定义的**素材替换契约**：

> 每个素材有确定的文件名和像素尺寸；要升级画质，把新图**以完全相同的文件名和尺寸**放进 `assets/textures/`，游戏零代码改动直接生效。
{: .prompt-info }

这个契约就是为 AI 素材生成设计的接口。占位符保证游戏永远可跑，Floniks 生成的正式素材按契约落位——**素材升级和代码迭代完全解耦**。文章开头那些截图里的花园背景、蘑菇棋子、和服小人，就是这样一批一批替换上去的。这是下一节的入口。

### 4.6 从桌面到 iOS 真机

`make run` 在桌面上开发（Lua 热重载），`make ios-run` 一条命令走完"交叉编译静态库 → XcodeGen 生成工程 → xcodebuild → 装进模拟器"，`make device-run CONFIG=Release` 上真机（自动签名，支持 120Hz ProMotion）。Xcode 工程本身是 git-ignored 的生成物——**构建系统也遵循"一切皆代码"，agent 可以完整地操作发布管线**。

![Garden Match 冒险模式关卡地图：AI 生成的花园场景与关卡节点](/assets/img/posts/ai-era-game-dev/garden-map.png){: width="400" .shadow }
_Garden Match 的冒险模式关卡地图，跑在 iPhone 真机上，120Hz ProMotion_

## 五、Floniks：通过 MCP 嵌入开发体系的素材工厂

先把一个前提说透：**美术能力不是游戏开发的"加分项"，而是必选项。** 第二节的数字已经说明了一切——美术占 AAA 预算的 25–30%，是独立开发者最普遍的产能死结，也是 Steam 上 60% 的 AI 使用披露所指向的环节。一个 AI 时代的游戏开发体系，如果只解决代码不解决美术，等于没解决。

[Floniks](https://floniks.com)（floniks.com）就是我们给出的美术侧答案：一个 AI 媒体创作平台，把多家模型提供商（FAL、MiniMax、Hailuo、APImart 等）的图像、视频、音频生成能力统一在一个可视化 DAG 工作流引擎之后。它有网页端的工作流编辑器，但对本文重要的是另一面——**它是一个生产级的 MCP 服务器，生来就是为了被融合进 agent 的开发循环**。

![AI 素材流水线示意：从提示词卡片经过 AI 绘画工厂，生成的游戏 sprite 直接落进手机里运行的游戏](/assets/img/posts/ai-era-game-dev/pipeline.jpg)
_Floniks 的角色：素材工厂在流水线上按需产出 sprite，直接落进正在运行的游戏_

### 5.1 MCP：把素材工厂接到 agent 手上的那根线

MCP（Model Context Protocol）是 Anthropic 在 2024 年 11 月发布的开放标准，用于把 AI 助手连接到外部工具和数据；OpenAI（2025 年 3 月）和 Google DeepMind（2025 年 4 月）先后采纳，2025 年 12 月 Anthropic 把它捐给了 Linux 基金会旗下的 Agentic AI Foundation——它已经是事实上的行业标准。

Floniks 在 `https://api.floniks.com/api/v1/mcp` 上暴露了一个完整的 MCP 端点（OAuth 2.1 + PKCE，或直接用 `mk_` 前缀的 API Key），共 **21 个工具**，覆盖从"探索能力"到"编排工作流"到"拿到结果"的全链路：

| 环节 | 工具 | 作用 |
|---|---|---|
| 探索 | `list_models` / `list_model_aliases` / `get_model_params` | 有哪些模型（文生图/图生图/文生视频/图生视频）、参数长什么样、花多少积分 |
| 探索 | `list_node_types` / `list_templates` / `get_template` | 工作流有哪些节点类型（输入/处理/AI/输出）、公开模板长什么样 |
| 编排 | `generate_workflow` | **自然语言 → 工作流图**（不落库、不扣积分，agent 编排的起点） |
| 编排 | `create_workflow` / `update_workflow` / `execute_workflow` | 落库、修改、执行 DAG 工作流 |
| 快捷 | `single_task` | 单步生成（一张图/一段视频），和网页端 AI Image/Video 页面同一条通道 |
| 结果 | `get_task` | 服务端长轮询（默认 25 秒），任务终态才返回产物 URL——**agent 不需要写轮询循环** |
| 一致性 | `list_characters` / `list_locations` | "角色护照/场景护照"：跨多次生成保持同一角色、同一场景的外观一致 |
| 发布 | `publish_task` / `create_template` | 把成果公开、把工作流发布成模板 |

注意几个专为 agent 设计的细节：`get_task` 内置服务端长轮询，杜绝了 agent 疯狂轮询的反模式；`generate_workflow` 让 agent 用一句话拿到工作流草图再精修，而不是从零手搓节点 JSON；每个工具都带 `readOnlyHint`/`destructiveHint` 注解，宿主（比如 Claude Code）能据此决定哪些操作需要用户确认。

### 5.2 游戏素材怎么生成：不是一个按钮，而是一条 agent 编排的流水线

Floniks 是通用 AIGC 平台，没有一个叫"sprite sheet 生成器"的按钮——**也不需要有**。游戏素材的各种形态，都是 agent 用现有节点现场编排出来的流水线：

- **透明底 sprite**：文生图/图生图 → **去背景节点**（`RemoveBackground`，快速版 rembg / 发丝级 BiRefNet）→ 透明 PNG；
- **贴图 / 高清化**：生成 → **放大节点**（Clarity / AuraSR 4x，适合纹理细节）；
- **局部修改**：**inpaint 节点**（FLUX / SDXL inpaint）——"把这把剑的剑柄改成金色"不必重画整张图；
- **序列帧**：关键帧图 → **图生视频**（Kling / Veo / Hailuo 等）→ **视频拆分/抽帧节点** → 一组连贯的动画帧；
- **成批变体**：**批量节点 + 循环节点**（`ImageBatch` / `BatchRender` / LoopStart-LoopEnd），一次执行、多路输出——`get_task` 会把每个输出节点的产物带着 `node_label` 一起返回；
- **角色一致性**：**角色护照**（character passport）挂上参考图，让主角在待机、奔跑、攻击三套序列帧里是同一张脸。

这些流水线一旦被 agent 建好，可以 `create_workflow` 存下来反复执行、`create_template` 发布给别人复用。**素材管线本身也成了代码一样的资产。**

顺带一提：**本文的封面和所有章节配图，也是用 Floniks 生成的**——和游戏素材同一套"风格化卡通、玩具盒"美术方向，同一个 MCP 通道，由写这篇文章的 agent 顺手完成。这就是"素材能力被融合进工作流"的意思：写代码的、写文章的、做游戏的，用的是同一个工具箱。

### 5.3 和游戏仓库的接口：ART_REQUESTS.md 契约

回想 4.5 节的契约：*同名、同尺寸、放进 `assets/textures/` 即生效*。于是完整的素材闭环是：

```
agent 读 assets/ART_REQUESTS.md（需要什么素材、什么风格、什么尺寸）
  → 调 Floniks MCP 生成（生成 → 去背景 → 放大/缩放到精确像素尺寸）
  → 下载产物，按契约文件名写入 assets/textures/
  → 桌面端热重载：游戏里立刻换上新皮肤
  → make test 确认玩法不变量未被破坏
```

没有导入向导，没有拖拽接线，没有"请美术同学切一下图"。素材需求写在仓库里，素材供给通过 MCP 到达，两端都是 agent 可读、可操作的。

## 六、Agentic Coding：你不写提示词，agent 自己完善

这套体系最反直觉的一点是：**开发者的输入可以非常少**。你不需要学 prompt engineering，原因有三：

**其一，上下文在仓库里，不在提示词里。** `CLAUDE.md` 写清了架构不变量（Lua 不碰 World、加 API 的三步法、"数值调优归 Lua"）；`ART_REQUESTS.md` 写清了素材规格和风格；测试套件写清了"什么叫对"。agent 进场先读这些文档——**你在文档里说一次，胜过在每次对话里重复一百次**。这就是"agent 会自行完善提示词"的真正含义：它把你的一句话需求，展开成符合仓库约定的完整执行计划。

**其二，MCP 工具是自描述的。** Floniks 的每个工具都带 schema 和说明，`get_model_params` 能查到每个模型的参数含义。agent 不需要你告诉它"aspect_ratio 该传什么"——它自己查。

**其三，反馈是机器可读的。** `make check` 秒级验证 Rust 编译；`make test` 跑几万帧断言手感契约；热重载让改动立刻可见。agent 的"写→验→修"循环完全不需要人在中间传话。

实际的对话是这样的（这是本仓库真实的开发过程，git 历史可查）：

> **你**：加一个复古太空射击游戏，要有高质量的美术。
>
> **agent**：（读 CLAUDE.md → 新建 `assets/scripts/shooter.lua`，写 `make_shooter` 闭包 → 在 `main.lua` 菜单挂载 → 生成 4×4 超采样的飞船/敌人/子弹 sprite → 在 `test_pong.lua` 里补上"开局 5×4 敌阵完整、自动射击加分、飞船不出屏"的断言 → `make test` 通过 → 提交）

几十条 git 提交，从一个 Pong 长成 9 个游戏的合集，中间还包括"测试抓到两个手感 bug 并修复""BACK 按钮避开灵动岛""修复真机上菜单不出现的加载竞态"这类真实的工程迭代——**每一条都是这样的对话产生的**。

### loop 模式：从"对话式开发"到"自主迭代"

Claude Code 的 loop 模式把这个循环再往前推一步：给 agent 一个持续性目标和一个节拍，它按节拍自主运行，每一轮自己决定做什么、做完自己验证，不需要你在场。

![夜间自主迭代：开发者不在，AI agent 在工位上把绿色的测试通过标记堆成一摞](/assets/img/posts/ai-era-game-dev/loop.jpg)
_loop 模式：你睡觉，agent 迭代；第二天早上 review 一串带绿色测试的 commit_

游戏开发恰好是 loop 模式的理想场景，因为这个仓库给了它两样东西：

1. **客观的完成度信号**——`make test` 的通过与否、断言数量的增长；
2. **安全的迭代空间**——Lua 沙盒 + 命令队列保证怎么改都不会崩引擎，模块化场景保证改一个游戏碰不到其他游戏。

于是你可以在下班前留一句：

> `/loop` 目标：给贪吃蛇加"金苹果"机制（吃到加三节、限时出现），为它补测试；然后把 Cozy Isle 的树/石头/花的贴图用 Floniks 换成手绘水彩风，注意读 ART_REQUESTS.md 的尺寸契约。每轮结束跑 make test，全绿才继续下一项。

第二天早上你 review 的不是 agent 的聊天记录，而是一串带着绿色测试的 commit。**人的角色从"操作工具的人"变成了"定方向、验成果的人"**——这正是每一次开发方式换代中，人的位置的变化：汇编时代人对硬件负责，引擎时代人对代码负责，AI 时代人对意图和验收标准负责。

## 七、教程：从零跑通整个闭环

下面是一份可以照着敲的完整走查。假设你有 Rust 工具链和 Claude Code。

### 第 0 步：跑起来

```bash
git clone https://github.com/maweis1981/rust_bevy_lua_game.git
cd rust_bevy_lua_game
make run        # 桌面窗口打开，菜单里是全部小游戏
```

`rust-toolchain.toml` 把项目钉在 stable（≥1.95，Bevy 0.19 的 MSRV），不用手动切工具链。开着游戏改任何 `assets/scripts/*.lua`，保存即热重载。

先感受一下测试：

```bash
make test       # Rust 单元测试 + Lua 无头不变量套件（需要 lua5.4）
# ... checks=NNNN
# PASS — all games' invariants held
```

### 第 1 步：让 agent 加一个游戏

打开 Claude Code，一句话即可：

```
加一个游戏：接住从天上掉下来的星星，接到加分，漏掉三个游戏结束。
```

agent 会自己完成（你可以全程围观，也可以去倒杯咖啡）：

1. 读 `CLAUDE.md`，得知新游戏 = 独立 `.lua` 文件里的一个 `make_*` 闭包；
2. 新建 `assets/scripts/catch.lua`，实现 `{enter, update, tap, leave}`，用 `GAME_KIT.tracker()` 管实体、`game.pointer()` 拖动接盘、`game.shake`/`game.play_sound`/`game.haptic` 加打击感；
3. 在 `main.lua` 的菜单里条件挂载（`if make_catch then … end`）；
4. 在 Rust 侧的 `EXTRA_SCRIPTS` 列表里登记新脚本；
5. 在 `tools/test_pong.lua` 里补断言：星星下落速度有上限、接住必加分、漏三个必结束、BACK 能回菜单；
6. `make test` 全绿。

如果新玩法需要引擎没有的能力（比如粒子），agent 会按 CLAUDE.md 里的三步法扩展 Lua API：加 `LuaCommand` 变体 → 在 `register_api` 注册 `game.*` 函数 → 在 `apply_lua` 里处理。**边界清晰到 agent 从不越界。**

### 第 2 步：连上 Floniks MCP

在 Claude Code 里添加 MCP 服务器（也可以走 claude.ai 的 Connector 目录，OAuth 授权即用）：

```bash
claude mcp add --transport http floniks https://api.floniks.com/api/v1/mcp \
  --header "Authorization: Bearer mk_你的APIKey"
```

API Key 在 floniks.com 的开发者页面创建。连上之后，`list_models`、`single_task`、`execute_workflow` 等 21 个工具就出现在 agent 的工具箱里了。

### 第 3 步：让 agent 生成并集成素材

继续对话：

```
把接星星游戏的素材换掉：星星要五角星形、金色描边、透明底、64×64；
接盘换成木质托盘的像素画风。风格参考 assets/ART_REQUESTS.md。
```

agent 的典型执行轨迹（全程无需你干预）：

1. `get_credit_balance` 确认额度；`list_model_aliases type=text_to_image` 挑一个适合像素风的模型；
2. `single_task` 生成星星原图 → `get_task` 长轮询拿到 URL；
3. 需要透明底？它会用 `generate_workflow` 编一条"生成 → RemoveBackground → 输出"的小流水线，`create_workflow` + `execute_workflow` 跑通；
4. 下载产物，缩放到契约要求的精确像素尺寸，以约定文件名写入 `assets/textures/`；
5. 游戏热重载，星星换装完成；`make test` 确认玩法没被碰坏；
6. 顺手更新 `ART_REQUESTS.md`，把新素材登记进清单。

想要**动画序列帧**，同理："给星星加旋转闪烁的动画"→ agent 编排"关键帧图 → 图生视频 → 拆帧"的工作流，落下来一组 `star_0.png … star_7.png`，再在 Lua 里用一个几行的帧计时器轮播 `game.spawn_sprite` 的贴图。需要主角在多套动作里长同一张脸？给它建一个**角色护照**（`list_characters`），后续所有生成都挂同一参考。

### 第 4 步：开启 loop，让它自己往前走

```
/loop 每轮从 TODO.md 取一项做完：实现→补测试→make test 全绿→commit。
素材类任务走 Floniks MCP，遵守 ART_REQUESTS.md 契约。测试不绿不许进下一项。
```

你负责往 `TODO.md` 里写想法（"加连击系统""BGM 换成 chiptune""星星偶尔是紫色的，接到扣分"），agent 负责把想法变成带测试的提交。

### 第 5 步：发布到 iOS

```bash
make ios-run                     # 模拟器
make device-run CONFIG=Release   # 真机（Debug 在真机上会明显卡，务必 Release）
```

素材（包括 Floniks 生成的）通过 Bevy 的资产管线自动进入 app bundle，`assets/` 是文件夹引用，目录结构原样保留——桌面上热重载的那些文件，一个字节不改地跟着上船。

## 八、结语：工具的换代，从来都是"谁能做游戏"的换代

回看第一节的时间线：汇编时代做游戏的门槛是"你得是那百分之一的硬件奇才"；引擎授权时代是"你得买得起授权"；Unity 时代是"你得学得会引擎"。每一次换代，门槛都在换一种形态，而每一次真正的进步，都让**更小的团队做出了以前更大团队才能做的东西**。

今天的焦虑——裁员、内卷、被 19,000 款年发行量淹没、美术产能的死结、对 AI 的恐惧——本质上是旧开发方式的产能模型撞上了新市场的残酷筛选。而 Rezona 这几天的爆红已经把风向标立在了那里：玩家不在乎游戏是谁（或什么）做的，只在乎好不好玩；八百多万人已经在刷 agent 做的游戏了。问题只剩下一个——当"一句话变游戏"从平台里的玩具走向认真的作品时，开发者手里应该握着什么样的工具链？对此我们的回答不是"AI 会取代谁"，而是一个具体的、开源的、今天就能跑起来的技术方案：

- **引擎归 Rust**：类型安全、跨平台，写对一次，agent 改不坏；
- **玩法归 Lua**：热重载、沙盒化、模块隔离，agent 放手迭代；
- **验收归测试**：几万帧的手感契约，是 agent 的眼睛，也是你睡觉时的安全网；
- **素材归 Floniks**：通过 MCP 这个行业标准协议，把多模型的生成能力变成 agent 工具箱里的普通工具，按契约落进仓库；
- **编排归 agent**：你出意图和验收标准，它出计划、代码、素材和测试。

一个人加一个 agent，晚上留一句话，早上收一串绿色的 commit——**这就是我们认为的、属于 AI 时代的游戏开发方式**。它不会是最终形态，就像 1998 年的 Unreal 不是最终形态一样。但方向我们很确定：下一个时代最好的游戏，会来自那些把 AI 当成团队成员而不是威胁的、很小很小的团队。

欢迎来试，欢迎来改，欢迎来一起定义它：

- 开源脚手架：[rust_bevy_lua_game](https://github.com/maweis1981/rust_bevy_lua_game)（Rust + Bevy + Lua，MIT）
- 素材平台：[floniks.com](https://floniks.com) · MCP 端点 `https://api.floniks.com/api/v1/mcp` · 开发者文档 [floniks.com/developers/mcp](https://floniks.com/developers/mcp)

## 常见问题（FAQ）

**Q：AI 现在真的能独立做出一款游戏吗？**
A：能做出"可玩、可维护、可发布"的小型游戏。本文的开源仓库就是证据：9 个小游戏、无头测试套件、iOS 真机发布，全部由 coding agent 在人的意图指引下完成。关键不是模型多聪明，而是仓库结构（引擎/玩法分层、测试契约、素材契约）是否为 agent 的迭代循环做过设计。

**Q：AI 游戏开发中，美术素材怎么解决？**
A：通过 MCP 协议把 AIGC 平台接进 coding agent 的工具箱。以 Floniks 为例：agent 用 `single_task` 文生图、用工作流串"生成 → 去背景 → 放大"，产物按仓库里 `ART_REQUESTS.md` 约定的文件名和尺寸落进 `assets/textures/`，游戏热重载直接换装。全程不需要人工导入或切图。

**Q：为什么选 Rust + Bevy + Lua，而不是 Unity 或 Unreal？**
A：不是画面之争，而是"哪种结构对 agent 友好"。Rust 引擎层类型安全、改不坏；Lua 玩法层热重载、秒级反馈、语言表面积小（LLM 生成 Lua 几乎没有语法幻觉）；无头测试给 agent 机器可读的验收信号。Unity/Unreal 的编辑器中心工作流对人友好，但 agent 无法有效操作 GUI。

**Q：什么是 MCP（Model Context Protocol）？**
A：Anthropic 在 2024 年 11 月发布的开放标准，用于把 AI 助手连接到外部工具和数据源，已被 OpenAI、Google DeepMind 采纳，2025 年 12 月捐给 Linux 基金会。对开发者的意义：只要一个服务实现了 MCP 端点（如 `https://api.floniks.com/api/v1/mcp`），任何支持 MCP 的 agent（Claude Code、Cursor 等）都能直接调用它的能力。

**Q：这套流程对独立开发者的实际价值是什么？**
A：把"美术产能"从死结变成 API 调用，把"下班后的时间"变成 agent 的迭代时间。美术与动画通常占 AAA 预算的 25–30%，也是单人开发者最常见的卡点；素材生成 + loop 模式自主迭代，让一个人的团队获得接近一支小工作室的产出结构。

---

*附：本文中的行业数据来源包括 Wikipedia（行业裁员条目、Unity、Unreal Engine、GoldSrc、Havok、MCP、SAG-AFTRA 罢工、赛博朋克 2077）、GDC State of the Game Industry 2025/2026、Kotaku、PC Gamer、SteamDB、Totally Human Media、lua.org、Anthropic 官方公告等；Rezona: Make Memeplays 的下载与月活数据来自 AppBrain / Apptopia 等应用商店数据平台的估计，"游戏的 TikTok 时刻"的说法见 Khaleej Times 的相关报道；AAA 预算与美术占比为行业通行估计。本文描述的开发流程均来自本仓库的真实 git 历史与 Floniks 的实际 MCP 工具清单；本文全部配图（封面与章节插画）由 Floniks 平台生成，游戏截图为 iPhone 真机/模拟器实拍。*
