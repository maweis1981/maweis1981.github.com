---
layout: post
title: "(Not Boring) Camera 产品调研：两人工作室的订阅生意，开发者能借鉴什么"
date: 2026-06-17 08:00:00 +0800
author: Max (Ma Wei)
location: Singapore
categories: [产品调研]
tags:
  - 产品分析
  - iOS
  - 订阅制
  - 独立开发
  - 设计驱动
description: 拆解 (Not Boring) Camera：它如何在被免费系统应用占满的红海里，靠体验+信任+套件撑起订阅生意，以及对独立开发者的 9 条可迁移打法。
image:
  path: /assets/img/posts/not-boring-camera/cover.jpg
  alt: (Not Boring) Camera 的标志性"实体相机"式界面
---

<!--
发布前请注意：
1) 正文内嵌图片已下载到 /assets/img/posts/not-boring-camera/ 本地引用（原为 Epic Tutorials 图床热链，研究性引用并已注明出处）；如需替换为自有图床/CDN 可直接更新这些文件。
2) 本文当前在 feature 分支 / 草稿 PR 中评审；确认无误后再合并到 main 发布。
3) front-matter 字段已按本博客（Jekyll / Chirpy）调整。
-->

> **一句话**：一款把"最被商品化的 App（相机）"做成可付费体验的两人工作室作品。
> **本报告为谁写**：独立 / 小团队 App 开发者。重点不在"这相机好不好用"，而在"**它做对了什么、哪些可以被我们借鉴**"。
> **下载（新加坡区）**：<https://apps.apple.com/sg/app/not-boring-camera/id6737783441>
> 报告日期：2026-06-17

![Not Boring Camera 概览](/assets/img/posts/not-boring-camera/cover.jpg)
_图：(Not Boring) Camera 的标志性"实体相机"式界面。（图源：Epic Tutorials 评测）_

---

## 0. 执行摘要（TL;DR）

(Not Boring) Camera（应用内称 **!Camera**）由两人工作室 Not Boring Software 出品。它最反直觉的一点：相机是 iPhone 上**最免费、最被商品化**的功能，他们却把它做成了一个**愿意有人付费订阅**的产品，且做到 Photo & Video 免费榜约 **No.59**、**4.3 分 / 127 评价**（SG 区）。

它的差异化是三层叠加：

1. **SuperRAW™ 成像** —— 绕开苹果的计算摄影，直取传感器 Bayer RAW 数据，主打"自然颗粒、胶片感、所见即所得"，是反"算法磨平感"的技术立场。
2. **3D LUT 调色 + Photo Lab** —— 号称首个把影视级 3D LUT 引入手机相机，并把"调色/显影"前置到拍摄与轻量后期。
3. **游戏化外壳** —— 全 3D 界面、动态光照、定制 haptics + 立体声、成就/贴纸/活动网格，"像握着一台实体胶片机"。

**对开发者最值钱的结论**：它证明了在一个被免费系统应用占满的红海里，**"体验 + 信任 + 套件"三件套**仍能撑起一个健康的订阅生意——而且是**两个人、不融资、不投广告、不收集任何数据**做到的。详见第 7 章。

---

## 1. 产品概况（事实卡）

| 项目 | 信息 |
|------|------|
| 应用名 | (Not Boring) Camera / 内部称 **!Camera** |
| 开发者 | Not Boring Software LLC（工作室 Andy Works / andy.works） |
| 创始人 | Andy Allen（设计）+ Mark Dawson（技术），**仅两人** |
| 平台 | iPhone / iPad（iOS 18+）、Mac（macOS 15+、M1 及以上）、Apple Vision Pro（visionOS 2+） |
| 体积 | 189.1 MB |
| 当前版本 | 1.53（2026 年 6 月，仍在高频更新） |
| 榜单 | Photo & Video 免费榜约 No.59（SG 区） |
| 评分 | **4.3 / 5，127 个评价**（SG 区） |
| 隐私 | App Store 标注 **"Data Not Collected"**："我们什么都不收集、不存储、不分享" |
| 背书媒体 | The Verge、Washington Post、MKBHD、Daring Fireball（John Gruber） |

> 同门兄弟（共享一套设计语言与会员）：(Not Boring) **Weather / Habits / Calculator / Timer / Vibes（音乐）**。Habits 曾获 **2022 Apple Design Award**。工作室自陈"**内部路线图就是初代 iPhone 的主屏**"——逐个重做系统级日常 App。

---

## 2. 核心功能拆解

### 2.1 SuperRAW™ —— 反"计算摄影"的技术立场

![SuperRAW](/assets/img/posts/not-boring-camera/superraw.jpg)
_图：SuperRAW 直取传感器原始数据。（图源：Epic Tutorials）_

- **绕开计算摄影**：苹果 ProRAW 仍经较重处理，常被批"过曝、过锐、HDR 痕迹重、塑料感"。SuperRAW 在计算介入**之前**就取走 Bayer 原始数据，配合自家 Styles / LUT 输出。
- **结果**：自然颗粒、更锐利、胶片化曝光、无诡异伪影；可存 DNG 进 Lightroom/Darkroom 进一步处理；同时兼容 Apple ProRAW 与 Basic 模式。
- **取舍诚实**：在 2× / 8× 变焦下 SuperRAW 不可用，会临时退回 Basic 处理——这点开发者值得注意：**它没有为了"全都支持"而牺牲核心管线的纯度，而是明确告诉用户边界。**

> **类比**：苹果相机像"帮你修好图再交给你"的助理；SuperRAW 像递给你一卷**未冲洗的胶片**——它赌"不完美的真实"比"被算法抹平的完美"更有味道。

### 2.2 3D LUT 调色 + Photo Lab —— 把后期前置

![LUT 导入与 Styles](/assets/img/posts/not-boring-camera/lut-import.jpg)
_图：Style Dial 与 LUT 导入。（图源：Epic Tutorials）_

- 号称**首个支持专业 3D LUT 的手机相机**：用内置预设、导入创作者 LUT、或自制导入（上限 50 个）。
- **Photo Lab（2026 年新增）**：非破坏式轻后期——显影 SuperRAW、调曝光/HDR/白平衡、切换胶片 Style 并调强度，"改了还能反悔"。
- 第三方生态已经长出来：评测者 Epic Tutorials 专门做了一套"Epic Boring LUT Pack"卖给 !Camera 用户——**别人在为你的 App 生产可售卖的内容**，这是平台化的早期信号。

![自定义 LUT 胶片观感](/assets/img/posts/not-boring-camera/custom-luts.jpg)
_图：不同 LUT 下的成片观感。（图源：Epic Tutorials）_

### 2.3 交互层 —— 游戏化的"实体感"

- **全 3D 界面 + 动态光照**：界面像真实物理装置，光影随手机姿态移动。
- **声音与触觉**：被评测称"任天堂级别音效"，每次点按与快门都有真实质感的 haptics + 立体声。
- **可选拍后回看**：拍完短暂"显影"回看，刻意**放慢节奏**，模拟等宝丽来出片。

### 2.4 专业控制（藏在玩具壳下）

完整手动：ISO、快门、白平衡（被用户评为"最可定制"）、手动对焦环 + **focus peaking**、**直方图**、**zebra stripes**。锁屏 1 秒内出片、硬件键拍照、Camera Control / 小组件多入口。

### 2.5 留存与习惯设计（把 Habits 的基因搬进相机）

这是 v1 报告漏掉、但对开发者极关键的一块：

- **Activity Widget**：用一张"年度网格"（类似 GitHub 贡献图）记录每日拍照活动，**把"拍照"做成可视化习惯**。
- **Achievements（手绘成就）+ Streaks（连续打卡）+ Stickers（解锁贴纸）**：把游戏化留存直接缝进工具。
- 也就是说：他们**把同门 Habits 的留存机制平移到了相机**——这是套件公司复用"留存模块"的范例。

---

## 3. 设计哲学：反极简主义

- **立场**：创始人 Andy Allen 公开主张"为极简主义画句号"。论据：手机算力/分辨率十几年涨了数百倍，但 Weather、Calculator 这类基础 App 的设计**几乎没变**。
- **方法**：用苹果游戏引擎，以**真 3D + 物理 + 声音**重做日常工具——"**玩起来像游戏，用起来像 App**"。
- **精神起点**：受观念艺术家 John Baldessari 1971 年作品《I Will Not Make Any More Boring Art》启发——与平庸彻底决裂。

---

## 4. 商业模式（开发者重点）

### 4.1 创始人决定了模式

Andy Allen 是 FiftyThree 联合创始人、爆款绘图 App **Paper** 与初代 **Pencil 触控笔**（Apple Pencil 原型）的缔造者；曾**融资约 4500 万美元**做软硬件、完成退出——**然后主动离开**，转做一个**完全自筹、不要投资人**的两人工作室，以"**每个 App 打磨约 3 年**"著称。

**关键认知：'小而慢、不扩张'是主动战略，不是被迫。**

### 4.2 定价结构（已据 SG App Store 校正）

> v1 报告里"$15/月"是**错的**。开发者本人在 App Store 回复差评时澄清：解锁相机全部功能只需 **$1.25/月（即 $15/年 USD）**。

| 档位 | 价格（SG 区） | 范围 |
|------|--------------|------|
| **!Camera Plus 年付** | S$19.98 / 年（≈ US$15/年） | 仅相机 |
| **!Camera Plus 买断** | S$89.98（≈ US$60–65 一次性） | 仅相机 |
| **Super !Boring 月付** | S$9.98 / 月 | 全套 App 会员 |
| **Super !Boring 年付** | S$39.98 / 年 | 全套 App 会员 |

要点：

- **免费可玩、付费解锁定制与高级功能**（freemium）。
- **单品 vs 套件双轨**：只想要相机 → Plus；想要全家桶 → Super !Boring 会员。**套件把单品的获客成本摊薄、把 LTV 抬高。**
- **买断选项**保留给抵触订阅的人群——降低流失、增加信任。

### 4.3 用"不作恶"当留存机制（官方 Plans 页直接写成卖点）

- **Price Lock**：只要订阅不断，**永不涨价**；
- **随时取消 + 14 天全额退款**；
- **100% 会员供养**：无广告、无融资、无数据交易；App Store 隐私栏是**实打实的 "Data Not Collected"**。

> 把"用户对订阅的不信任"反过来做成**竞争壁垒**。

### 4.4 把"季度联名"做成增长引擎

!Camera 几乎每月更新，并**按季度推出艺术家联名 / 限定配色**作为持续的话题与拉新：

- 艺术家系列：**Lucas Zanotto（招牌 blobs）**、Sam Pietz、Moonshot、Retro !Camera、NYE 配色；
- 品牌联名：**Perplexity × !Boring 的 "Curiosity !Camera"**（与 AI 公司联名）。

**这相当于给一个工具 App 装上了"球鞋式限定发售"的运营节奏**——内容即营销，且几乎零边际成本。

---

## 5. 口碑与争议

**正面（外媒 / 评测人）**

- The Verge：好久以来用过最好玩的相机；Washington Post：iPhone 摄影首选；MKBHD：太好玩。
- **John Gruber（Daring Fireball）**：看起来像噱头但不是，"就是纯粹的好玩与异想天开"；用了几个月**好感不降反增**。但他诚实地补充：他的硬件 Camera Control 仍默认开苹果相机，!Camera 放在锁屏小组件上快速调用。
- **Epic Tutorials**：称其为 GOAT，认为是 2026 苹果设计奖"Delight and Fun"的有力竞争者、甚至年度 App 候选。
- **TapSmart**：一句精准定位——"**一个伪装成纯触感玩具的、真正的专业体验**"。

**普通用户（App Store）**

- "这是我**唯一**留过评的 App，就是这么好"；发到 Instagram 后被人建议"该去做摄影了"。
- 建设性意见：希望加**视频**、强反差下**更好的曝光控制**、不同**画幅比例**。

**争议 / 短板**

- **订阅抵触**：有 1 星差评抱怨"几乎所有功能都要付费、太贵"（后被开发者澄清其实是 $15/年）——说明**定价沟通不清**本身会损分。
- **审美不普适**：高饱和极繁风"很酷，但未必适合每天日常用"，开发者自己承认"不是给所有人的"。
- **流程摩擦**：拍后只给约 1 秒预览，要看成片得再跳去系统相册。
- **小团队带宽**：历史上有新机型前置摄像头、beta 黑边等 bug（均被快速修复）。

---

## 6. 竞争格局

苹果"You Might Also Like"给出的同场竞品，可看出它所处的象限：

| App | 定位 | 与 !Camera 的关系 |
|-----|------|------------------|
| **Halide Mark III**（Lux） | 克制专业、手动控制标杆 | 同走"反 AI、自然成像"，但**极简工具风**，无游戏化 |
| **Leica LUX** | 徕卡品牌 + 专业手动 | 靠品牌溢价；!Camera 靠**自有设计语言**溢价 |
| **Adobe Project Indigo** | Marc Levoy 团队，反 HDR 计算摄影 | 同反"smartphone look"，但工程取向、偏慢 |
| **Obscura / No Fusion / Spectre** | 各类 Pro Cam | 比"谁更专业" |
| **VSCO / Lampa / PeekLut** | 滤镜/胶片/LUT 编辑 | 比"谁的滤镜好看" |

**定位判断**：竞品在比"谁更克制专业"或"谁的滤镜更好看"；!Camera 开辟的是 **"专业能力 × 情绪价值（好玩/质感/拥有感）"** 的差异化象限——它不和你比参数，它让你**想拿起来拍**。

---

## 7. 对 App 开发者的借鉴（本报告核心）

把上面的事实翻译成可迁移的打法：

**① 在红海里用"体验"重新定价。**
相机免费且人人都有，他们却靠"好玩 + 质感 + 拥有感"让人付费。**情绪价值是可定价的差异化**，哪怕品类已被免费系统应用占满。问自己：我的品类里，被算法/竞品**抹平了什么真实价值**？把它重新做出来。

**② "好玩"是功能，不是装饰。**
Gruber 的好感"用了几个月不降反增"，靠的是 haptics、声音、动态光照带来的**反复把玩欲**。把"用起来爽"当成留存指标的一部分，而不只堆功能。

**③ 单品 + 套件双轨定价。**
"只要相机就买 Plus（$15/年），要全家桶就开会员"——既照顾轻度用户的低门槛，又用套件抬高重度用户 LTV。**运营多个 App 的团队尤其该评估"统一会员"而非"各卖各的"。**

**④ 用透明与克制对抗订阅疲劳。**
Price Lock、随时退款、买断选项、"Data Not Collected"——把用户对订阅的戒心，转化为品牌资产与**抗流失**机制。差评里"以为很贵"的案例也提醒：**定价文案要在付费墙前就说清楚**。

**⑤ 把留存模块在套件内复用。**
他们把同门 Habits 的**成就/连续打卡/年度活动网格**直接搬进相机，让"拍照"变成可视化习惯。**一次做好的留存系统，可以成为公司级可复用资产。**

**⑥ 把更新做成"限定发售"。**
近乎每月更新 + 每季艺术家联名/品牌联名（含 Perplexity 联名），用接近零边际成本的**内容运营**制造持续话题与拉新。工具 App 也能有"球鞋式"的发售节奏。

**⑦ 工艺即获客（earned media）。**
The Verge / WaPo / MKBHD / Gruber / 设计奖带来的是**赚来的流量**，不是买来的。极致工艺本身就是分发渠道——这是对"纯靠付费投放"的有力对照。

**⑧ 诚实地承认边界。**
2× / 8× 变焦下明说"SuperRAW 不可用"、创始人公开承认"不是给所有人的"。**清晰的边界比虚假的全能更能赢得专业用户的信任。**

**⑨ "小而慢"可以是战略。**
两人、不融资、每个 App 磨 3 年——克制 SKU、深耕单点，反而成就品牌。对"要不要做成多产品公司 / 注意力是否被摊薄"，这是一个**专注派**样本。

> **一句话迁移**：先想清楚"我的品类里被磨平了什么真实价值"，用更好的**体验**把它做回来，用**套件 + 信任**把它变成生意，用**联名 + 工艺**把它传播出去——然后**保持小**。

---

## 8. SWOT 速览

- **S（优势）**：独一无二的设计语言、SuperRAW 技术立场、获奖级工艺带来的免费媒体、强信任（Price Lock / 零数据收集）、套件复用与联名运营。
- **W（劣势）**：两人带宽有限、审美小众、缺视频、拍后流程有摩擦、定价沟通曾失分。
- **O（机会）**：LUT 创作者生态（UGC 可售内容）、跨 Mac/Vision Pro 延展、套件交叉销售。
- **T（威胁）**：苹果系统相机持续进步、Adobe Project Indigo 等大厂同叙事入场、整体订阅疲劳。

---

## 9. 信息来源

- App Store（新加坡区，定价/版本/隐私权威）：<https://apps.apple.com/sg/app/not-boring-camera/id6737783441>
- Not Boring 官方套餐页：<https://www.notboring.software/plans>
- Daring Fireball（John Gruber 评测）：<https://daringfireball.net/2025/10/not_boring_camera_and_adobe_project_indigo>
- Epic Tutorials 评测（含功能截图与技术拆解）：<https://epictutorials.com/blogs/articles/not-boring-camera-app-for-iphone-review-and-tutorial>
- TapSmart 评测：<https://www.tapsmart.com/apps/not-boring-camera-review/>
- The Story Behind Not Boring Software（Andy Allen 访谈，Medium）：<https://medium.com/@teslathewest/the-story-behind-not-boring-software-f52b48188336>
- UX Tools 播客（Andy Allen：3 年做一个 App / 反扩张）：<https://www.uxtools.co/episodes/why-this-designer-takes-3-years-to-build-apps>
- Fast Company（反极简主义宣言）：<https://www.fastcompany.com/90604970/>
- Apple Developer — Behind the Design: (Not Boring) Habits：<https://developer.apple.com/news/?id=9ab1g4r3>

> 说明：报告内功能截图来自 Epic Tutorials 评测（其自有拍摄与界面图），仅作研究性引用并已注明出处；定价以 App Store 与官方 Plans 页为准（各第三方聚合站口径常有出入，v1 报告的"$15/月"已在本版更正为"$15/年"）。
