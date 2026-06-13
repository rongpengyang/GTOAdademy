# GTO Academy — 德州扑克训练学院（iOS）

6-max NLHE 现金局教学训练器。**纯教学模拟器：无真钱、无奖品、无内购、无网络、无账号。**
所有筹码与数值均为虚构训练单位。

- 技术栈：SwiftUI · SwiftData · Swift Charts · XCTest
- 目标：iOS 18.0+ · Swift 6（strict concurrency = complete）· 零第三方依赖
- 文档：`docs/PRD.md`（产品需求）· `docs/ARCHITECTURE.md`（架构与 Schema）
- 当前进度：**M10 — 上架就绪：每日 12 题抽样 · iPad 阅读宽度 · 真机 QA 清单 · 提审物料终稿 —— 17 组 101 用例**

---

## 1. 打开工程（三选一）

### 路线 B（推荐）：XcodeGen 一键生成

```bash
brew install xcodegen
cd GTOAcademy        # 仓库根目录（含 project.yml）
xcodegen generate
open GTOAcademy.xcodeproj
```

`project.yml` 已配置 app target、测试 target（含 TEST_HOST）、scheme 与全部构建设置。

### 路线 A：手动创建 Xcode 工程

1. Xcode → New Project → iOS App，Product Name 填 `GTOAcademy`，Interface = SwiftUI，
   Storage = None（SwiftData 容器已在代码中手动配置），勾选 Include Tests。
2. 删除模板生成的 `ContentView.swift` 与 `GTOAcademyApp.swift`、测试模板文件。
3. 把仓库里的 `GTOAcademy/` 文件夹内容拖入 app target（勾选 *Copy items if needed* 可不选，
   *Create groups*），把 `GTOAcademyTests/` 内容拖入测试 target。
4. Build Settings：iOS Deployment Target = 18.0；Swift Language Version = 6；
   Strict Concurrency Checking = Complete。
5. 测试 target 的 **Host Application** 选择 GTOAcademy（让 `Bundle.main` 指向 App，
   内容校验测试依赖这一点）。

### 路线 C：交给 Claude Code

仓库已内置 `.claude/skills/`（四个项目技能会被自动加载）。在仓库根运行 Claude Code，
直接说"构建并跑全部测试，把报错修到全绿"即可执行 步骤13 的 build→test→fix 循环。

---

## 2. 运行与测试

- **⌘R** 运行：应看到加载页 → 5-Tab 主界面。Home 显示内容版本 `1.1.0`
  与课程 / 精编题 / 范围表计数（30 / 160 / 12），证明 JSON 管线打通。
  Learn 已上线完整课程链路：学习路径 → 课程详情 → 课末测验（答完自动记录完成态 + XP）。
  Drill 三训练器、Tools 三工具与 Profile（等级 / 连续天数 / 图表 / 错题本）均为真实页面——五个 Tab 占位清零。
- **⌘U** 测试：十七组共 101 个用例 ——
  `ContentValidationTests`（内容完整性 / 引用 / PRD 配额 / 禁用话术）、
  `RangeParserTests`（范围记法解析 + UTG/BTN 组合数）、
  `ModelCodingTests`（紧凑编码往返 / 归一化 / 169 格完整性）、
  `ProgressServiceTests`（完成态 / XP 幂等 / 流水写入）、
  `CheckpointQuizViewModelTests`（测验状态机）、
  `HandEvaluatorTests`（7 张评牌）、`PlayerClassifierTests`（分类规则 ↔ 内容一致）、
  `ScenarioEngineTests`（无尽出题 / 每日抽样 / 范围表事实）、`DrillScoringEngineTests`（判分 + XP）、
  `DrillProgressServiceTests`（流水 / 错题快照）、`DrillSessionViewModelTests`（会话状态机）、
  `RangeLibraryTests`（范围表组合数 / 位置单调性）、`HandMatrixTests`（13×13 矩阵几何）、
  `StatCalculatorViewModelTests`（VPIP / PFR / AF 计算）、`PlayerTypeToolViewModelTests`（输入 → 分类联动）、
  `ProgressStoreTests`（等级门槛 / 连续天数 / 每日奖励 / SRS 调度）、`SettingsStoreTests`（设置单例 / 主题映射 / 触感总闸）。
- 内容改动后可在仓库根额外运行 `python3 tools/validate_content.py` 做离线校验。

---

## 3. 目录结构

| 路径 | 职责 |
| --- | --- |
| `GTOAcademy/App/` | 入口、启动引导（AppBootstrap）、依赖容器、5-Tab 根视图 |
| `GTOAcademy/Models/Core/` | 扑克领域：Card · HandClass(169) · HoleCards · Board · HandRank · Position · 动作 |
| `GTOAcademy/Models/Training/` | 内容侧：Lesson · Scenario×3 · Range · PlayerStats · 各 Config · LocalizedText |
| `GTOAcademy/Models/Persistence/` | SwiftData：UserProgress · DrillRecord · MistakeReviewItem · AppSettings |
| `GTOAcademy/Services/` | 纯逻辑：RangeParser · HandEvaluator · ScenarioEngine · DrillScoringEngine · PlayerClassifier 等 |
| `GTOAcademy/Repositories/` | ContentLoader（manifest 驱动）+ 三个只读查询仓库 |
| `GTOAcademy/DesignSystem/` | Theme 色板 · Typo 字体 · Spacing/Radius · Haptics · Motion |
| `GTOAcademy/Views/` | 页面：五 Tab 全量 + 设置页（占位清零） |
| `GTOAcademy/Content/` | 全部内容 JSON（manifest · lessons · scenarios · ranges · config） |
| `GTOAcademyTests/` | 单元测试 |
| `docs/` | PRD 与架构文档 |

**分层铁律**：内容（bundle JSON，只读）与状态（SwiftData，读写）分离；
Views 不直接解码 JSON、不直接做扑克运算。

---

## 4. 内容创作指南（速查）

改完内容后 **必须 ⌘U** —— `ContentValidationTests` 会兜住引用断裂、解释缺失与禁用话术。

- **加一课**：在 `Content/lessons/<track>.json` 的 `lessons` 追加；blocks 类型为
  `concept / example / mistake / tip / quizRef`；每课至少 1 个 `concept`、1 个 `mistake`、
  1 个 `quizRef`。测验题写进同文件 `questions`，`choiceExplanations` 必须与 `choices` 等长。
- **加翻前题**：`scenarios/preflop.json`。`correct`/`acceptable` 取
  `fold | call | raise | 3bet`；`wrongChoices` 的键 = 选项字符串，**不得**包含
  correct/acceptable；`lessonRef` 必须是真实课程 id。**批量扩充优先用 `python3 tools/generate_preflop.py`**（范围表同源推导答案；幂等，只重建 `pf-g-*` 生成题，手写题不动；改过范围表后必须重跑并 ⌘U）。
- **加翻后题**：`scenarios/postflop.json`。`wrongChoices` 键格式 = 动作+尺寸：
  `check`、`bet33`、`bet75`、`raise100`（与 `PostflopChoice.key` 对应）。
  `board` 用紧凑牌码数组：`["Kd","7s","2c"]`。
- **加范围表**：`ranges/<id>.json` 用 `notation` 人类记法
  （`"22+, ATs+, KTs-K7s, A5s:0.5"`），混合频率格可用 `cells` 显式覆盖；
  然后把文件名加进 `manifest.json` 的 `rangeFiles`。
- **新文件务必登记进 `Content/manifest.json`**，Loader 只认 manifest。

---

## 5. M1 状态清单

- [x] XcodeGen 工程定义（app + tests + scheme，Swift 6 strict，iOS 18）
- [x] 全部领域模型 / 内容模型 / SwiftData 模型（约 950 行）
- [x] RangeParser（含 13 个解析用例）
- [x] ContentLoader 管线 + 三个仓库；启动失败显式报错页
- [x] 设计 token（自适应深浅色 / Dynamic Type 字体 / 触感 / 动效规范）
- [x] 5-Tab 骨架 + Home 数据验证页（含 Preview）
- [x] 首批双语内容：2 课 · 4 测验题 · 6 翻前 + 2 翻后 + 3 玩家类型题 · 2 张 RFI 范围
- [x] 27 个单元测试 · 隐私清单 PrivacyInfo.xcprivacy

### M2 新增

- [x] Learn Tab 全链路：学习路径（轨道进度 / 完成态）→ 课程详情（概念 / 例子 / 错误 / 技巧 分块卡片）→ 课末测验（即时反馈 + 逐选项解释 + 学习目标）
- [x] 课程完成写入 SwiftData（completedLessonIDs + XP），重复完成不重复计；每次作答记入 DrillRecord 流水
- [x] 内容扩充：Track 1 补全至 7 课，新增 Track 2「翻前训练营」3 课——共 10 课 · 20 测验题；翻前精编题改挂 Track 2 课程
- [x] ViewModels 层启用（CheckpointQuizViewModel，纯逻辑可单测）；tools/validate_content.py 离线校验器入仓
- [x] 新增 7 个用例，合计 34 个

### M3 新增

- [x] 引擎四件套：HandEvaluator（7 张评牌）· ScenarioEngine（精编排序 + 无尽 RFI 出题）· DrillScoringEngine（三档判分 + XP）· DrillProgressService（流水 + 错题快照）
- [x] 统一泛型会话状态机 DrillSessionViewModel（三训练器与无尽模式共用，纯逻辑可单测）；CardView / GradeBadge / ExplanationCard / DrillSummaryView 组件
- [x] Drill Tab 三训练器上线：翻前（精编 / 无尽 RFI 双模式，无尽答案由范围表事实自动判定）· 翻后下注尺寸（成手徽章 + #理由标签）· 玩家类型判断（六型全覆盖）
- [x] 内容扩充至 23 道精编题（翻前 12 / 翻后 5 / 玩家类型 6），版本 `0.3.0-m3`
- [x] 错题双语快照自本阶段开始累积（M5 错题本数据源）；新增 32 个用例，合计 66 个

### M4 新增

- [x] Tools Tab 上线：范围矩阵（13×13，对角线波次入场签名动效，逐格点查组合数与频率）· VPIP / PFR / AF 计算器（原始计数 → 百分比，含自洽提醒）· 玩家类型判断工具（滑杆实时驱动 PlayerClassifier，含边界置信提示）
- [x] 范围表扩至 6 张：UTG / HJ / CO / BTN / SB 开局 + BB 防守跟注；无尽 RFI 自动扩至五个位置
- [x] 计算器一键把数据带入类型判断（PlayerStats 直通）；校验器为全部 6 张表固化组合数窗口
- [x] 内容版本 `0.4.0-m4`；新增 18 个用例，合计 84 个

### M5 新增

- [x] Profile 个人页上线：等级（8 级 minXP 门槛）· 连续训练天数与每日首训 +10 XP · 近 14 天训练 XP 图表（Swift Charts）· 分训练器正确率 · 错题本入口
- [x] SRS 错题复习闭环：到期队列按 1 / 3 / 7 / 14 天间隔晋级，越过末档标记掌握；通过（含可接受）发放 reviewPass XP，答错阶段归零；原题下线自动退化为快照自测卡
- [x] 统一写入口 ProgressStore 收编课程 / 训练写入：视图层零直连旧服务，等级与连续天数随每笔写入自动同步
- [x] 五个 Tab 全部真实页面，占位组件清零；新增 10 个用例，合计 94 个

### M6 新增（收官）

- 设置页接通 `AppSettings`：四色牌面（实时卡面预览）、主题（系统 / 深 / 浅）、触感总闸 `Haptics.isEnabled`，在根视图统一生效。
- 课程 10 → **30**（4 轨道：新手 7 · 翻前与指标 7 · 翻后核心 7 · GTO 之路 9，课内题 60）。
- 范围 6 → **12**（RFI ×5 + BB 防守跟注 ×4 + 3-Bet ×3；其中 BB vs BTN 为同局面「跟注 + 3-Bet」双动作图）。组合数全部经校验器同源解析审计并固化窗口。
- App 图标（程序化生成：墨底 / 毛毡绿黑桃 / 金色细节）、`Docs/AppStore.md` 商店物料（名称 / 描述 / 分级 / 隐私 / 审核备注 / 检查清单）、Profile XP 条入场动效（尊重「减弱动态」）。内容版本升至 **1.0.0**；新增 SettingsStoreTests 4 用例。
- CI 首跑修复：移除全部 5 处 `nonisolated init`（Swift 6 下 `@Observable` 存储属性 setter 为 MainActor 隔离，nonisolated init 无法对其赋值；iOS 18 SDK 中 `View`/`App` 协议已整体 `@MainActor`，调用侧 @State 初始化天然在主 actor，无需 nonisolated）。
- CI 修复 2：修正 2 个文件共 3 处误用 rawValue 写法的 case 引用（`.calling_station` / `.passive_fish` → `.callingStation` / `.passiveFish`）。枚举本体自 M1 即含此两型（驼峰 case 名 + snake_case rawValue），无需也不可增补 case——强行增补会触发 rawValue 重复的编译错误。
- CI 修复 3：两个 @MainActor 测试类（RangeLibraryTests / PlayerTypeToolViewModelTests）移除 `setUpWithError` 与隐式解包存储属性，改为测试体内 `loadLibrary()` / `loadConfig()`——`setUpWithError` 的 override 继承父类的 nonisolated 隔离，无法对 @MainActor 属性赋值。非 @MainActor 的 PlayerClassifierTests / DrillScoringEngineTests 属性与类同隔离，保留原写法。

### M7 新增（v1.1 第一棒）

- 翻后精编 5 → **45**（翻牌 31 · 转牌 7 · 河牌 7，达标 PRD AC-E1）：c-bet 家族 / 3-Bet 底池 / 大盲防守 / IP 跟注位 / 转牌双重开火与刹车 / 河牌薄价值与弃牌纪律；底池数字与行动叙事按家族常量同源推算。
- 玩家类型题 6 → **25**（达标 PRD AC-D2，六型 4/4/4/4/4/5）：生成时在 python 内复刻 `classifier.json` 先到先得规则逐题自检，CI 上由 `PlayerClassifierTests` 反向背书；含规则顺位边界题与小样本教学题。
- 错题复习题面补上**完整行动历史**（翻后题逐街叙事，与训练器同源渲染），已知缺口表对应行清零。
- 校验器钉死内容配额（翻后 45 = 31/7/7、类型 ≥25、street 与公共牌张数一致）；`ContentValidationTests` 新增 `testScenarioQuotasMeetPRD`，用例 98 → **99**；内容版本 `1.0.0` → **`1.1.0`**。

### M8 新增（v1.1 第二棒）

- 翻前精编 12 → **90**（PRD §215 满编 160 = 翻前 90 · 翻后 45 · 类型 25）：新增常驻工具 `tools/generate_preflop.py`——答案从 12 张范围表机械推导（与 Tools 矩阵、无尽模式判定永远同源），运行时与校验器固化的组合数逐表对账防解析漂移；解释按 20 个「家族 × 判定类」模板渲染（确定性变体），覆盖 RFI 五位置、BB 四对位防守（vs BTN 三选项制）、SB/BTN 的 3-Bet-or-Fold。幂等重跑只重建 `pf-g-*`，手写 12 题保留。
- 校验器新增翻前配额（≥90）；`testScenarioQuotasMeetPRD` 补翻前断言（用例数仍 17 组 99）。
- TestFlight 发布管线：`.github/workflows/release-testflight.yml`（手动触发两段式：Ubuntu 内容校验 → macOS 云端 `xcodebuild` 自动签名 archive 并直传 App Store Connect，构建号 = 工作流 run number 单调递增）+ `Docs/TestFlight.md` 中文配置手册（App 记录 / API Key / 五个 Secrets / 排障表）。

### M9 新增（体验打磨）

- **每日 12 题精编会话**：三训练器的精编模式改接 `ScenarioEngine.dailyPreflop/Postflop/PlayerType()`——同一天结果稳定（中断重进同套题）、跨天确定性轮换（年月日 → splitmix64 种子 → 同参 LCG），抽样后保持难度升序曲线；池子不足自动全量。`ScenarioEngineTests` +2（同日稳定 / 跨天轮换），合计 **17 组 101 用例**。
- **iPad 阅读宽度**：新增 `readableWidth()`（680pt 居中列，DesignSystem/Layout.swift），统一挂在 9 个内容页的滚动容器（Home / 学习路径 / 课程详情 / 测验 / Drill 首页 / 三训练器 / 错题复习）；Tools 的 13×13 矩阵**有意保持全宽**。iPhone 上无感知。
- **L10n → xcstrings 迁移有意推迟至 v1.2**：提审前冻结字符串管线是标准做法；现有 LocalizedText 单点已完整覆盖双语，迁移属内部改造、零用户可见收益。

### 构建排障：Multiple commands produce（已修复）

XcodeGen 默认把 `sources: GTOAcademy` 递归成**分组**（逐文件引用），`Content/` 下
`config / lessons / scenarios / ranges` 四个子目录的 JSON 在 `createIntermediateGroups`
扁平化时会让多条 copy-resource 命令指向同一输出目录而冲突。修法（已写入 `project.yml`）：

1. App target 的 Swift 源码树 `excludes: [Content]`，把内容目录从分组里摘出去；
2. `Content` 单独以 **folder reference**（`type: folder` + `buildPhase: resources`）整目录拷贝——
   蓝色文件夹一次拷贝、保留子目录、零 per-file 冲突；
3. `ContentLoader.url(for:)` 的 `subdirectory` 兜底（`Content`、`Content/config` …）正好匹配
   folder-reference 的 bundle 内路径，24 个 JSON 全部命中（已离线模拟验证）。

云端 Mac 操作：`rm -rf GTOAcademy.xcodeproj ~/Library/Developer/Xcode/DerivedData/* && xcodegen generate && open GTOAcademy.xcodeproj`，⌘R 直接 Run。

### M10 新增（上架冲刺）

- `Docs/QA-Checklist.md`：真机走查清单——TestFlight 装机后逐项打勾，覆盖启动、五 Tab 全链路、每日抽样、SRS 晋级降级、设置与系统集成（深浅色 / 动态字体 / 减弱动态 / iPad 旋转）、进度持久化。
- `Docs/AppStore.md` 升至 **v1.1 终稿**：描述补 160 满编与每日抽样、5 张截图配定稿双语文案 + 无 Mac 真机截屏流程、What's New（1.1.0）、Connect 提审八步走、检查清单改挂 CI 101 用例与 QA 清单。

## 没有 Mac？在云端编译与测试（GitHub Actions）

仓库已内置 `.github/workflows/ci.yml`，推送到 GitHub 后无需任何本地 macOS：

1. 在 GitHub 新建仓库，把本目录整个推上去（Windows 用 Git for Windows 即可）。
2. 打开仓库 **Actions** 标签——每次 push / PR 自动运行，也可点 **Run workflow** 手动触发。
3. 流水线两段：Ubuntu 上秒级跑 `tools/validate_content.py`（内容先把关，省 macOS 分钟数）；通过后 macOS 云跑机执行 `xcodegen generate` + `xcodebuild test`（自动挑选可用 iPhone 模拟器，免签名，跑满 17 组 101 用例）。失败会把 `TestResults.xcresult` 作为 artifact 上传，可在 Windows 下载留存。
4. Windows 本地随时可自助校验内容：`python tools\validate_content.py`（注意 Windows 下命令是 `python`）。

公开仓库的 Actions 免费；私有仓库注意 macOS 分钟按更高倍率计费。发 TestFlight 用仓库内置的 `release-testflight.yml`（手动触发：内容校验 → 云端自动签名 → 直传 App Store Connect），配置步骤见 `Docs/TestFlight.md`。

## 6. 已知缺口（按计划推进）

| 缺口 | 处理 |
| --- | --- |
| 代码在本环境未经真实 Xcode 编译，可能需一轮小修 | 把 build 报错贴回来，或交 Claude Code 自动修到全绿 |
| TestFlight 管线未实跑（待 Apple 账号侧 Secrets 配置） | 按 `Docs/TestFlight.md` 五步配置后手动触发 |
| Localizable.xcstrings 迁移 | 有意推迟至 v1.2：提审前冻结字符串管线（LocalizedText 单点已覆盖双语） |
