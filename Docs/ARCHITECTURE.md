# 技术架构 · GTO Academy v1.0

配套文档：`docs/PRD.md`（功能口径以 PRD 为准，本文定义实现方式）。

---

## 1. 技术栈与版本

| 项 | 选型 | 说明 |
|---|---|---|
| IDE / SDK | Xcode 26.x（iOS 26 SDK） | 当前稳定版 |
| 语言 | Swift 6，Strict Concurrency = Complete | 编译期并发安全 |
| UI | SwiftUI（iOS 18 Tab API、NavigationStack） | 无 UIKit 页面、无 WebView |
| 持久化 | SwiftData（仅用户状态） | 内容不入库，见 §2 原则 1 |
| 图表 | Swift Charts | Profile 统计 |
| 状态 | @Observable（Observation 框架） | 不用 ObservableObject |
| 测试 | XCTest（遵循项目 skill 约定） | 不引入 Swift Testing |
| 最低部署 | iOS 18.0 / iPadOS 18.0 | Universal 单一 target |
| 第三方依赖 | **0** | 全部第一方框架 |

## 2. 架构总览

```
┌─ Views (SwiftUI) ──────────────────────────────┐
│  仅渲染与手势；不含业务规则                        │
└──────────────▲─────────────────────────────────┘
               │ @Observable
┌─ ViewModels ─┴─────────────────────────────────┐
│  屏幕状态机；组合 Service 调用；可单测             │
└──────────────▲─────────────────────────────────┘
               │
┌─ Services ───┴───────────┐  ┌─ Repositories ───┐
│ 纯逻辑（不 import SwiftUI）│  │ 内容加载与缓存      │
│ HandEvaluator / Range…   │  │ Lesson/Scenario/  │
│ Classifier / Scoring / SRS│  │ Range Repository  │
└──────────────▲───────────┘  └────────▲─────────┘
               │                        │
        ┌──────┴──────┐         ┌──────┴───────┐
        │  SwiftData   │         │ Bundle JSON  │
        │ （用户状态）   │         │（只读内容，带版本）│
        └─────────────┘         └──────────────┘
```

三条不可破坏的原则：

1. **内容与状态分离**：课程/题库/ranges/配置 = 只读、带 `schemaVersion` 的 Bundle JSON；用户产生的一切（进度、错题、设置、答题记录）= SwiftData。内容升级永不迁移用户数据。
2. **纯逻辑下沉**：所有可判定对错的规则（牌力评估、范围解析、分类、评分、复习调度）都在 Services 层，零 UI 依赖，100% 可单元测试。
3. **单向依赖 + 注入**：View → ViewModel → Service/Repository → 数据。依赖经 `AppDependencies` 组装，`.environment` 注入；测试与 Preview 用 `PreviewDeps.sample` 替身。

## 3. 目录结构

```
GTOAcademy/
├── docs/
│   ├── PRD.md
│   └── ARCHITECTURE.md
├── GTOAcademy/                          # App target 源码
│   ├── App/
│   │   ├── GTOAcademyApp.swift          # @main，SwiftData container，内容加载
│   │   ├── AppRootView.swift            # 5-Tab 根视图 + 首启 Onboarding 路由
│   │   └── AppDependencies.swift        # 组装 Services/Repositories
│   ├── Models/
│   │   ├── Core/                        # 纯值类型，全部 Sendable + Codable
│   │   │   ├── Card.swift               # Card / Rank / Suit（"As" 紧凑编码）
│   │   │   ├── HoleCards.swift          # 两张具体牌
│   │   │   ├── HandClass.swift          # 169 格抽象牌型（AKs/AKo/TT）+ comboCount
│   │   │   ├── PokerHand.swift          # 5–7 张牌集合
│   │   │   ├── HandRank.swift           # 评估结果：类别 + kickers，Comparable
│   │   │   ├── Board.swift
│   │   │   ├── Position.swift           # utg/hj/co/btn/sb/bb + 行动顺序
│   │   │   ├── PlayerAction.swift       # fold/check/call/bet/raise(+sizing)
│   │   │   └── BettingRound.swift       # preflop/flop/turn/river
│   │   ├── Training/                    # 内容侧模型（Decodable from JSON）
│   │   │   ├── Lesson.swift             # 四段结构块
│   │   │   ├── QuizQuestion.swift
│   │   │   ├── TrainingScenario.swift   # preflop / postflop 两种 payload
│   │   │   ├── RangeChart.swift / RangeCell.swift / ActionWeight.swift
│   │   │   ├── PlayerStats.swift        # vpip/pfr/af/foldToCbet/hands
│   │   │   ├── PlayerType.swift
│   │   │   └── ClassifierConfig.swift / LevelConfig.swift
│   │   └── Persistence/                 # SwiftData @Model
│   │       ├── UserProgress.swift       # xp/level/streak/完成课程 id 集
│   │       ├── DrillRecord.swift        # 每次答题流水（统计图表数据源）
│   │       ├── MistakeReviewItem.swift  # 错题 + SRS stage + nextReviewAt
│   │       └── AppSettings.swift        # 主题/四色牌/动效/阈值覆盖
│   ├── Services/
│   │   ├── HandEvaluator.swift
│   │   ├── RangeParser.swift
│   │   ├── ScenarioEngine.swift         # 题库模式 + 无尽模式出题
│   │   ├── PlayerClassifier.swift
│   │   ├── DrillScoringEngine.swift
│   │   ├── SpacedRepetitionScheduler.swift
│   │   ├── ProgressStore.swift          # actor；XP/等级/streak 唯一写入口
│   │   ├── EquityTools.swift            # pot odds / 2-4 法则
│   │   └── ComplianceChecklist.swift    # Debug 自检（§13）
│   ├── Repositories/
│   │   ├── ContentManifest.swift        # 清单 + schemaVersion 校验
│   │   ├── LessonRepository.swift
│   │   ├── ScenarioRepository.swift
│   │   └── RangeRepository.swift
│   ├── ViewModels/                      # 每屏一个，@Observable
│   ├── Views/
│   │   ├── Onboarding/OnboardingView.swift · DisclaimerView.swift
│   │   ├── Home/HomeDashboardView.swift
│   │   ├── Learn/LearnPathView.swift · LessonDetailView.swift · CheckpointQuizView.swift
│   │   ├── Drill/DrillHubView.swift · PreflopTrainerView.swift ·
│   │   │        PostflopTrainerView.swift · PlayerTypeTrainerView.swift ·
│   │   │        AnswerRevealView.swift
│   │   ├── Tools/ToolsView.swift · RangeMatrixView.swift ·
│   │   │        VPIPCalculatorView.swift · PotOddsCalculatorView.swift
│   │   ├── Profile/ProfileView.swift · MistakeBookView.swift ·
│   │   │        StatsChartsView.swift · SettingsView.swift
│   │   └── Components/CardView.swift · TableSeatMap.swift · ChipBadge.swift ·
│   │                  ActionButtonRow.swift · ProgressRing.swift · StatTile.swift
│   ├── DesignSystem/
│   │   ├── Theme.swift                  # 色彩 token（深/浅两套映射）
│   │   ├── Typography.swift · Spacing.swift
│   │   ├── Haptics.swift                # 触感事件映射
│   │   └── Motion.swift                 # 标准 spring + reduceMotion 降级
│   ├── Content/                         # 只读内容（Bundle 资源）
│   │   ├── manifest.json
│   │   ├── lessons/{track1..track4}.json
│   │   ├── scenarios/preflop.json · postflop.json · playertype.json
│   │   ├── ranges/rfi_*.json · bbdef_*.json · 3bet_*.json   # 共 12 张
│   │   └── config/classifier.json · levels.json · srs.json · banned_phrases.json
│   └── Resources/
│       ├── Assets.xcassets              # 图标、原创花色矢量
│       ├── Localizable.xcstrings        # UI 文案 zh-Hans / en
│       └── PrivacyInfo.xcprivacy
└── GTOAcademyTests/
    ├── HandEvaluatorTests.swift
    ├── RangeParserTests.swift
    ├── PlayerClassifierTests.swift
    ├── DrillScoringEngineTests.swift
    ├── SpacedRepetitionTests.swift
    ├── ContentValidationTests.swift     # 全量 JSON 解码 + 引用完整性
    └── Fixtures/
```

## 4. 领域模型要点

最关键的一个区分：**HoleCards（两张具体牌，如 A♠K♠）≠ HandClass（169 格抽象，如 AKs）**。训练题、Matrix、范围按 HandClass 思考；发牌、牌力评估按具体牌。`HandClass.comboCount`：对子 6、suited 4、offsuit 12——combo counting 课程直接复用该模型。

```swift
struct Card: Hashable, Codable, Sendable { let rank: Rank; let suit: Suit }  // "As" ↔ Card
enum Position: String, CaseIterable, Codable, Sendable { case utg, hj, co, btn, sb, bb }

struct HandClass: Hashable, Codable, Sendable {
    let high: Rank; let low: Rank; let kind: Kind   // pair / suited / offsuit
    var comboCount: Int { kind == .pair ? 6 : kind == .suited ? 4 : 12 }
}

struct RangeCell: Codable, Sendable {               // 支持混合频率
    let hand: HandClass
    let actions: [ActionWeight]                      // [(raise, 1.0)] 或 [(call,.5),(threeBet,.5)]
}

struct HandRank: Comparable, Sendable {              // 评估输出
    let category: Category                           // highCard…royalFlush 九类
    let tiebreakers: [Rank]                          // 按位比较，处理 kicker
}
```

SwiftData 模型只存用户状态（字段见目录注释），其中 `MistakeReviewItem` 字段与 PRD FR-H 一一对应：`scenarioID / userChoice / correctAnswer / reason / lessonRef / stage / nextReviewAt / masteredAt?`。

## 5. 内容 JSON Schema（v1）

通用规则：每个文件含 `schemaVersion`（int，当前 1）；所有面向用户的文本为双语对象 `{"zh": "…", "en": "…"}`；id 全局唯一 kebab-case；跨文件引用（题→课、课→题）在 `ContentValidationTests` 中做完整性校验，缺引用即测试失败。

`manifest.json`：

```json
{ "schemaVersion": 1, "contentVersion": "1.0.0",
  "files": { "lessons": 4, "scenarioSets": 3, "ranges": 12 } }
```

翻前场景（`scenarios/preflop.json` 单条）：

```json
{
  "id": "pf-rfi-btn-a5s",
  "kind": "rfi",
  "position": "btn",
  "facing": [],
  "hand": "A5s",
  "correct": "raise",
  "acceptable": [],
  "explanation": { "zh": "A5s 在 BTN 属于标准开局：A blocker、同花坚果潜力、位置优势。",
                   "en": "A5s is a standard BTN open: ace blocker, nut-flush potential, position." },
  "wrongChoices": { "fold": { "zh": "过紧——BTN 开局范围约 44%+，A5s 远在其中。", "en": "…" } },
  "objective": { "zh": "识别 BTN 宽开局范围中的 suited ace。", "en": "…" },
  "lessonRef": "l2-04-rfi-by-position",
  "difficulty": 1, "tags": ["rfi", "suited-ace"]
}
```

范围文件（`ranges/rfi_btn.json`）：

```json
{ "schemaVersion": 1, "id": "rfi-btn-100bb", "position": "btn", "stack": 100,
  "action": "rfi", "source": "original GTO-inspired approximation",
  "cells": [ { "h": "A5s", "a": [["raise", 1.0]] }, { "h": "K9o", "a": [["raise", 1.0]] } ] }
```

分类器配置（`config/classifier.json`，节选）——**rules 数组顺序即判定优先级**：

```json
{ "schemaVersion": 1, "sampleMin": 30,
  "rules": [
    { "type": "maniac",  "vpip": { "gt": 40 }, "pfr": { "gt": 30 }, "af": { "gte": 3, "optional": true } },
    { "type": "passiveFish", "vpip": { "gt": 35 }, "pfr": { "lt": 10 }, "af": { "lt": 1.5, "optional": true } },
    { "type": "callingStation", "vpip": { "gt": 30 }, "pfr": { "lt": 12 }, "foldToCbet": { "lt": 40, "optional": true } },
    { "type": "nit", "vpip": { "lt": 18 }, "pfr": { "lt": 14 } },
    { "type": "tag", "vpip": { "gte": 18, "lte": 25 }, "pfr": { "gte": 15, "lte": 22 } },
    { "type": "lag", "vpip": { "gte": 26, "lte": 35 }, "pfr": { "gte": 22 } }
  ] }
```

课程块结构：`blocks: [{type: concept|example|mistake|tip|quizRef, …}]`，渲染层按 type 套模板，新增块类型不破坏旧解析（unknown type 安全跳过）。

## 6. 核心服务设计

**HandEvaluator** — 输入 5–7 张牌，输出最佳五张的 `HandRank`。实现：直方图统计（对/三/四条）+ 花色桶（flush）+ 顺子位掩码（含 wheel A-2-3-4-5）；7 张牌直接对 21 种五张组合取 max（训练场景量级 < 1ms，无需查表优化）。边界用例写入测试矩阵：kicker 平局、板面成牌（play the board）、同花顺 vs 葫芦、wheel vs 6-high straight。

**RangeParser** — 把人类记法解析为 `Set<HandClass>`（含可选频率）。语法：

```
expr   := token ("," token)*
token  := pair | pairRange("99-66") | pairPlus("77+")
        | hand("AKs"|"AJo") | handPlus("ATs+") | handRange("KTs-K7s")
        | weighted(token ":" freq)        // "A5s:0.5"
```

非法 token 抛带位置信息的 `RangeParseError`，不静默吞错。Matrix 与无尽模式共用其输出。

**PlayerClassifier** — 输入 `PlayerStats`，按 config 的有序规则表逐条匹配，首个命中即类型；附 `confidence`（样本量 ≥ sampleMin 且与最近边界距离 ≥ 2 个百分点为 high，否则降档）；全不命中 → `.borderline(closest: [type])`。解释文案由规则元数据生成，含"针对策略"卡引用。

**ScenarioEngine** — 题库模式：按筛选条件（训练器/位置/难度/未做优先）抽精编题。无尽模式：随机 `(position, HoleCards)` → 折算 HandClass → 查 `RangeRepository` 对应图表 → 正确动作 + 模板化解释（频率 < 1.0 的格子在无尽模式中**不出题**，避免"混合频率算你错"的教学噪声——见 ADR-4）。

**DrillScoringEngine** — 三档：correct（命中 correct）/ acceptable（命中 acceptable 列表，如相邻 sizing）/ wrong；wrong 且属预设"blunder 集"（如 BTN fold AA）额外标记，用于错题本权重。输出 `ScoreResult { grade, xp, blunder }`，XP 数值查 `levels.json`。

**SpacedRepetitionScheduler** — 纯函数：`(stage, answeredCorrectly, now) → (newStage, nextReviewAt?)`；间隔 `[1, 3, 7, 14]` 天读自 `config/srs.json`；stage 越界即 mastered。

**ProgressStore** — `actor`，唯一可写 XP/等级/streak 的入口，保证并发下流水与汇总一致；对外暴露只读快照供 Home/Profile 共用（PRD AC-G2）。

**ComplianceChecklist** — Debug-only 面板与单测：扫描 `banned_phrases.json` 词表命中（UI 文案 + 内容 JSON）、断言工程无网络相关 entitlement、断言 Disclaimer 路由可达、断言所有题目 explanation 非空。

## 7. 设计系统（DesignSystem/）

依据 PRD §7，token 先行，视图只引用 token 不写裸色值。

| Token | Dark | Light | 用途 |
|---|---|---|---|
| inkBackground | #0B0E12 | #F7F8F9 | 页面底 |
| surface | #151B23 | #FFFFFF | 卡片 |
| surfaceElevated | #1C2430 | #F1F3F5 | 弹层/选中 |
| feltAccent | #2E9E6B | #1E7A50 | 强调/正确/Matrix 渲染主色 |
| goldMoment | #D9A441 | #B8860B | 仅成就与升级时刻 |
| danger | #E5484D | #D33036 | 错误反馈 |
| textPrimary / textSecondary | #E6EDF3 / #93A1B0 | #14181D / #5B6672 | 文本 |
| suit♠ ♥ ♦ ♣（四色模式） | #E6EDF3 / #FF5C5C / #4D9FFF / #3FB950 | 同左加深 | 牌面 |

排版：系统 SF Pro；角色表 LargeTitle(34/bold) · Title(22/semibold) · Body(17) · Caption(13)；全部经 `.dynamicTypeSize(... .xxLarge)` 验证；数值组件强制 `.monospacedDigit()`。间距 4pt 网格（8/12/16/24）；圆角 12（卡片）/16（弹层）/连续曲率。

动效：标准曲线 `spring(response: 0.35, dampingFraction: 0.8)`；签名动效 = Matrix 对角线波次点亮（每格延迟 = (row+col)×12ms）；`reduceMotion` 时全部降级为 0.15s 淡入。Haptics 映射集中在 `Haptics.swift`：correct→success、wrong→error、deal→light、levelUp→heavy。

## 8. 导航与状态管理

`AppRootView` 用 iOS 18 `Tab` API 建 5 个 Tab，各自持有 `NavigationStack(path:)`；路由为每个 Tab 一个 `enum Route: Hashable`，支持 Home 跨 Tab 直达训练（经共享 `AppNavigator`）。每屏一个 `@Observable` ViewModel，由 View 持有（`@State`），依赖从 `AppDependencies` 取；Preview 与测试注入 `PreviewDeps.sample`（内置小型内容固件）。

## 9. 并发模型

Swift 6 strict：Services 为无共享态的 `Sendable struct`（可自由跨任务），仅 `ProgressStore` 为 `actor`；SwiftData 操作固定 `@MainActor`（训练 App 写入量低，无需后台 context）；启动时 `task` 异步加载 + 校验全部内容 JSON，失败进入显式错误屏（内容损坏不允许半残运行）。

## 10. 测试策略（XCTest）

| Target | 必测用例 |
|---|---|
| HandEvaluatorTests | 九类牌型各 ≥2 例；kicker 平局；play-the-board；wheel；同花顺边界；7 选 5 正确性 |
| RangeParserTests | pair/suited/offsuit 单项；`77+`、`99-66`、`ATs+`、`KTs-K7s`；带频率；非法 token 报错位置；combo 总数核对（如 "22+" = 78） |
| PlayerClassifierTests | 每条规则边界 ±0.1（如 VPIP 17.9/18.0/18.1）；重叠区按顺序判定（VPIP 38/PFR 8 → passiveFish）；样本不足降置信；borderline 输出 |
| DrillScoringEngineTests | correct / acceptable / wrong / blunder 四态；XP 对照 levels.json |
| SpacedRepetitionTests | 0→1→…→mastered 全链路；中途答错回 0；nextReviewAt 计算 |
| ContentValidationTests | 全量 JSON 可解码；id 唯一；题↔课引用完整；explanation 100% 非空；banned phrases 零命中 |

Preview 约定：每个主要屏幕 `#Preview`（dark + light 各一），数据来自 Fixtures，保证设计走查不依赖真机数据。

## 11. 工程创建与运行（第 3 阶段执行细则）

**路线 A（推荐，零额外工具）**：Xcode → New → iOS App，Product Name `GTOAcademy`，Interface SwiftUI、Language Swift、不勾选 Core Data/Tests 模板（测试 target 手动建以匹配文件结构）→ 删除模板文件 → 把我交付的 `GTOAcademy/` 与 `GTOAcademyTests/` 整体拖入（勾选 Create groups + target membership）→ Build Settings：iOS Deployment Target 18.0、Swift Language Version 6、Strict Concurrency Complete → `⌘B` / `⌘U`。

**路线 B（可复现工程文件）**：我在阶段 3 同时交付 `project.yml`，你 `brew install xcodegen && xcodegen generate` 一步生成 `.xcodeproj`。

**Claude Code 路线**：仓库根目录已含 `.claude/skills/`（你定义的 4 个）；在 Mac 上 `claude` 打开本仓库，阶段 13 的 build/test/修错循环可由它自动执行，QA skill 的 7 步报告同样适用。

## 12. 性能与可访问性实现要点

Range Matrix：169 格用 `Grid` 一次性布局（数据量小，无需懒加载），格子视图 `Equatable` 化避免整面重绘；缩放用 `ScrollView` + `MagnifyGesture` 限幅 1.0–2.5×；iPhone 默认态即满足 36pt 命中（PRD AC-I1），或单击进入放大态。VoiceOver：`CardView`、Matrix 格、动作按钮全部自定义 `accessibilityLabel`（本地化），训练流程可全程 VO 完成。Dynamic Type 至 XXL 的破版检查列入每阶段 QA。

## 13. 合规技术项

- `PrivacyInfo.xcprivacy`：声明 UserDefaults 使用理由 CA92.1；NSPrivacyTracking = false；无收集类别。
- `ITSAppUsesNonExemptEncryption = NO`（无自定义加密）。
- 不集成 ATT、analytics、任何网络 SDK；工程不含 outgoing 网络代码（ComplianceChecklist 断言）。
- App 内 Settings → 法务区：免责声明、隐私政策（描述"不收集"）、开源许可（v1.0 为空，保留入口）。

## 14. 关键决策记录（ADR）

1. **零第三方依赖**：训练 App 全部需求第一方框架可覆盖；省去许可审查、供应链与审核风险（对应 skill 的依赖与许可证规则）。
2. **内容用 JSON 而非预置数据库**：可读可 diff、便于双语校对与未来"纯内容更新"，加载后常驻内存（< 数 MB）。
3. **坚持 XCTest**：遵循项目 skill 既定约定，避免双测试框架混用。
4. **RangeCell 支持混合频率，但 v1.0 出题避开混频格**：模型为未来 solver 数据预留表达力；教学上"57% raise"对答题判定是噪声，混频格仅在 Matrix 查看模式展示。
5. **不做整局对战引擎**：决策点训练的单位时间反馈密度更高，且把 v1.0 工程量控制在可交付范围（PRD §3.2）。
6. **ProgressStore 用 actor 单写入口**：XP/streak 来源多（课程、训练、复习），单一序列化写入是最简单的正确性方案。
