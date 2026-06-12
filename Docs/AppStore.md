# App Store 提交资料 — GTO Academy（v1.0）

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
精编与无尽两种训练模式即时判分、逐项解释；12 张原创范围图表（GTO-inspired 教学近似）
覆盖开局、防守与 3-Bet；做错的题自动进入 1/3/7/14 天间隔复习的错题本；
等级、连续天数与正确率曲线记录你的每一步成长。完全离线，无账号、无广告、无真钱元素——
只有训练。

**English:**
GTO Academy is a poker gym in your pocket. Thirty bilingual lessons walk from hand
rankings to GTO equilibrium; curated and endless drills grade every answer with
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

1. Home 仪表盘 —— 等级、今日训练入口
2. Learn —— 4 轨道课程路径
3. Drill —— 答题 + 逐选项解释（金色「正确」时刻）
4. Tools —— 13×13 Range Matrix（波次点亮）
5. Profile —— XP 曲线 / 连续天数 / 错题本

## 9. 提交前检查清单

- [ ] `python3 tools/validate_content.py` 全绿（含禁用词扫描）
- [ ] Xcode ⌘U 全部测试通过
- [ ] 真机检查：触感开关、深/浅色、四色牌面、减弱动态降级
- [ ] 替换 bundleIdPrefix / DEVELOPMENT_TEAM
- [ ] 截图 5 张 + 图标 1024 已就位
