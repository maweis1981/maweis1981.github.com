---
title: "Engine Showcase：把引擎的 feature list 做成游戏，再给每个 feature 一个跑分按钮"
date: 2026-07-07 12:00:00 +0800
author: Max (Ma Wei)
location: Singapore
categories: [游戏开发]
tags:
  - vibe coding
  - Rust
  - Bevy
  - Lua
  - WebAssembly
  - Floniks
  - AIGC
  - benchmark
image: /assets/img/engine-showcase/keyart.jpg
---

> 在线试玩（浏览器直接打开）：<https://maweis.com/rust_bevy_lua_game/> → 菜单选 **Engine Showcase**。
> 本文对应的全部代码、issue、开发过程记录都在 [rust_bevy_lua_game](https://github.com/maweis1981/rust_bevy_lua_game) 仓库里（PR [#56](https://github.com/maweis1981/rust_bevy_lua_game/pull/56)，主工单 [#52](https://github.com/maweis1981/rust_bevy_lua_game/issues/52)）。

游戏引擎的宣传页都长一个样：一排 feature 图标，一段"强大而灵活"的形容词。今天我们换了个做法——**把 feature list 本身做成游戏**。

## 一个上午的背景

上午，两条并行的 agent 流水线把这个引擎 roadmap 上的 P0/P1 缺口全部清零：存档、多点触控、图集动画、摄像机、音频控制、CPU 粒子、tilemap、cutout 骨骼、本地统计——9 组 `game.*` API，逐项带单测合入 main，全程 issue 记录、耗时精确到分钟（复盘见仓库的 [roadmap 文档](https://github.com/maweis1981/rust_bevy_lua_game/blob/main/docs/roadmap-and-benchmark.md) §5）。

下午的任务只有一句话：把这些能力都通过游戏的方式展示出来，每个能力配一个 benchmark 场景。

## Engine Showcase 是什么

一个 3×3 的能力矩阵。九张卡片，每张对应一组引擎 API，点进去不是文档，是一个立刻能上手的小玩具：

![九个能力站](/assets/img/engine-showcase/stations.jpg)

- **VAULT**——存进去的金币杀掉进程再开还在（iOS 沙盒 / 桌面配置目录 / 浏览器 localStorage，同一个 API）
- **TOUCH**——每根手指一个光环（最多 8 根）
- **ATLAS**——一张 6 帧贴图驱动满屏旋转金币
- **CAMERA**——镜头追着无人机巡游一个 3 倍屏幕大的世界
- **MIXER**——能真拖的三通道混音台，正在播的音乐即时变
- **SPARKS**——点哪炸哪的烟花，全局 512 粒子上限可视化
- **TILES**——手指作画的地形编辑器，四种笔刷
- **ROBOT**——剪纸骨骼机器人，头会看向你的手指
- **JUICE**——屏幕抖动/变焦冲击/触觉反馈，每次按压落一条分析日志

每个站右上角有个 **BENCH** 按钮。按下去，引擎当着你的面给自己加压：更多精灵、更多粒子、更大的全图重刷、更多行走的骨骼角色——直到帧时间守不住预算，把最后守住的档位定格成分数，存进游戏存档。**你手机的九项能力跑分，就挂在存档站的墙上。** 而且 benchmark 的成绩持久化用的就是被测的存档 API——这是这个 demo 最诚实的部分。

## 没有一张人画的图

金币图集、地形贴图、机器人部件：Floniks 上 Seedream 4 文生图；两支背景音乐：Lyria 2 文生音乐。处理管线（色键抠底、切格、镜像补件、重组条带）是一个 130 行的 Python 脚本，一条命令可重放——换个 prompt 就是换一套皮肤。

机器人的动画没有用任何工具"制作"：`robot.rig` 是一份 47 行的手写 JSON——部件层级、旋转枢轴、三个关键帧剪辑。改一个数字，动画就变。这就是"AI 时代的引擎不需要编辑器"的具体含义：**它的编辑器是数据 + agent**。

三个值得记录的坑（详细过程在 issue #52）：

1. 同一个 Floniks workflow 并发执行两次，第二次拿回了节点缓存的旧文件——广告配乐下载下来一对 md5，是上周另一个游戏的 BGM；
2. AI 不会数格子：要 6 帧给 8 帧，要 6 个部件给 6 个部件加两个空格子还缺躯干——确定性的后处理（挑帧、镜像、挪用）比重新抽卡便宜；
3. 色键的边界在阴影里：生成图好心给每个金币配了深紫投影，第一版抠图判定放走了它们。

## 拍视频拍出两个真 bug

给 demo 录产品视频时（无头容器里 Xvfb + 软件渲染跑原生构建、脚本驱动输入、ffmpeg 抓屏），录制脚本卡住了两次——都不是录制的问题：

1. **CAMERA 站会把玩家困住**：镜头巡游后，世界坐标锚定的返回按钮飘出了屏幕。修复：点按循环"跟随 → 俯瞰 → 自动回大厅"。
2. **BENCH 固定预算在慢设备上永远零分**：软件渲染静息就超 1/45s 预算。修复：首个周期先标定本机静息帧时间，预算 = 基线 × 1.4——低端设备能爬出有意义的档位，高刷设备也不会白送分。

给产品拍广告结果修了产品——这大概是"demo 必须真实可玩"这条规则最好的回报。

## 时间账

从"把功能展示出来"这句话，到 demo、资产、文档五件套（产品介绍/使用手册/宣传文案/场景应用/开发博客）、两支视频全部合入 main：**约两个半小时**，其中游戏包本体（630 行 Lua，零引擎改动）约 15 分钟。

能这么快不是因为省了步骤——9 个站全部接入无头测试套件，13 万条断言在每次提交前全量跑过。是因为架构把每个能力的用法压缩成了一两行 Lua，而测试网让"敢改"成为默认状态。

---

*引擎系列前文：[AI 时代，应该有 AI 时代的游戏开发方式](https://github.com/maweis1981/rust_bevy_lua_game/blob/main/docs/ai-era-game-dev.md)、[没有编辑器，是设计使然](https://github.com/maweis1981/rust_bevy_lua_game/blob/main/docs/no-editor-by-design.md)。产品介绍视频与广告片在仓库 [docs/showcase/media/](https://github.com/maweis1981/rust_bevy_lua_game/tree/main/docs/showcase/media)。*
