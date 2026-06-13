# App Store 提交资料 — GTO Academy（v1.1 终稿）

> 本文为提交 App Store Connect 时的填写底稿与合规清单。最终以 Connect 表单为准。

## 1. 基本信息

| 字段 | 值 |
| --- | --- |
| App 名称（en，≤30 字符） | `GTO Academy: Holdem Trainer` |
| App 名称（zh） | `GTO 学院：德州扑克训练` |
| 副标题（en） | `Learn poker the smart way` |
| 副标题（zh） | `从规则到 GTO 的系统训练营` |
| 主类别 | 教育（Education） |
| 副类别 | 游戏 › 卡牌（Games › Card） |
| 价格 | $4.99 付费下载 · 无内购 · 无订阅 |
| Bundle ID | `com.yourcompany.gtoacademy`（提交前替换） |

## 2. 描述

**中文：**
GTO 学院是一座装进口袋的德州扑克训练馆。30 节双语课程从手牌等级讲到 GTO 均衡；
**160 道精编题**（翻前 90 · 翻后 45 · 类型识别 25）以每日 12 题智能抽样推送，配合无尽模式即时判分、逐项解释；12 张原创范围图表（GTO-inspired 教学近似）
覆盖开局、防守与 3-Bet；做错的题自动进入 1/3/7/14 天间隔复习的错题本；
等级、连续天数与正确率曲线记录你的每一步成长。完全离线，无账号、无广告、无真钱元素——
只有训练。

**English:**
GTO Academy is a poker gym in your pocket. Thirty bilingual lessons walk from hand
rankings to GTO equilibrium; 160 curated spots (90 preflop · 45 postflop · 25 player-typing)
arrive as a smart daily-12 session, plus endless drills — every answer graded with
per-choice explanations; twelve original range charts (GTO-inspired training
approximations) cover opens, defends and 3-bets; mistakes flow into a spaced-repetition
review book (1/3/7/14 days); levels, streaks and accuracy curves track your progress.
Fully offline. No accounts, no ads, no real money — just reps.

## 3. 关键词（≤100 字符）

`poker,holdem,GTO,trainer,preflop,range,chart,strategy,quiz,study,card,texas`

## 4. 年龄分级（Age Rating）

- Connect 问卷「模拟赌博」勾选 **偶尔/轻度（Infrequent/Mild Simulated Gambling）** → 预期 **12+**。
- 依据：应用展示扑克下注概念用于策略教学；**无真实货币、无筹码购买、无赌博服务链接、
  无输赢结算**。定位等同棋类教学。
- 最终分级以 App Store Connect 问卷结果为准。

## 5. 隐私（App Privacy）

- 声明：**Data Not Collected（不收集任何数据）**。
- 应用无网络请求、无账号体系、无第三方 SDK、无追踪。
- `PrivacyInfo.xcprivacy` 已随包提供（NSPrivacyTracking = false，无 Required Reason API）。

## 6. 出口合规

- `ITSAppUsesNonExemptEncryption = NO`（已写入 project.yml，使用系统标准加密之外无自带加密）。

## 7. 审核备注（App Review Notes 建议文案）

> This is a fully offline educational app that teaches Texas Hold'em strategy,
> comparable to a chess tutor. It contains no real-money play, no in-app purchases,
> no accounts, no gambling links, and makes no network requests. All range charts are
> original GTO-inspired training approximations authored for this app.

## 8. 截图清单（6.7" 必备，建议 5 张）

| # | 画面 | 配字（zh） | Caption (en) |
| --- | --- | --- | --- |
| 1 | Home 仪表盘 | 你的口袋扑克训练馆 | Your poker gym, pocket-sized |
| 2 | Learn 学习路径 | 30 节双语课程，从规则到 GTO | 30 bilingual lessons, rules to GTO |
| 3 | Drill 答题 + 解释 | 每日 12 题，错在哪里讲到懂 | Daily 12 — every miss explained |
| 4 | Tools 范围矩阵 | 12 张原创范围表，逐格点查 | 12 original range charts, cell by cell |
| 5 | Profile 成长曲线 | 等级、连续天数与错题本 | Levels, streaks and your mistake book |

**真机截屏流程（无 Mac）**：TestFlight 装好后用 iPhone 直接截图——6.7"/6.9" 机型任一即可，
App Store Connect 会自动适配小尺寸；五张统一竖屏、统一深色或浅色。

## 9. 提交前检查清单

- [ ] `python3 tools/validate_content.py` 全绿（含禁用词扫描）
- [ ] GitHub CI 全绿（17 组 101 用例）
- [ ] 按 `Docs/QA-Checklist.md` 真机走查通过
- [ ] What's New（1.1.0）文案已填（见 §10）
- [ ] 构建版本已在 Connect 选定 TestFlight 最新 build
- [ ] 真机检查：触感开关、深/浅色、四色牌面、减弱动态降级
- [ ] 替换 bundleIdPrefix / DEVELOPMENT_TEAM
- [ ] 截图 5 张 + 图标 1024 已就位

## 10. What's New（1.1.0 提审文案）

**中文：**
精编题库满编 160 道（翻前 90 · 翻后 45 · 类型识别 25），训练改为每日 12 题智能抽样——
同一天稳定、跨天轮换、先易后难；错题复习卡补上完整行动历史；iPad 大屏阅读体验优化。

**English:**
The curated library is now complete at 160 spots (90 preflop · 45 postflop · 25 player-typing),
served as a smart daily-12 session — stable within a day, rotating across days, easy to hard.
Review cards now show the full action history, and reading layout is optimized for iPad.

## 11. Connect 提审八步走

1. Connect → 我的 App → GTO Academy → 「1.1.0 准备提交」（首次提审即以 1.1.0 作为首发版本）。
2. 上传 §8 的 5 张截图。
3. 粘贴 §1–§3 的名称 / 副标题 / 描述 / 关键词。
4. 粘贴 §10 What's New。
5. 「构建版本」选 TestFlight 中最新一条 build。
6. 年龄分级问卷按 §4 口径作答（模拟赌博 = 偶尔/轻度）。
7. App 隐私 = 不收集任何数据（§5）。
8. 审核备注贴 §7 → 提交。审核通常 1–3 天；被拒就把回信原文贴回来定位。
