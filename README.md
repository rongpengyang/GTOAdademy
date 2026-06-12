# GTO Academy — 德州扑克训练学院（iOS）

6-max NLHE 现金局教学训练器。**纯教学模拟器：无真钱、无奖品、无内购、无网络、无账号。**
所有筹码与数值均为虚构训练单位。

- 技术栈：SwiftUI · SwiftData · Swift Charts · XCTest
- 目标：iOS 18.0+ · Swift 6（strict concurrency = complete）· 零第三方依赖
- 文档：`docs/PRD.md`（产品需求）· `docs/ARCHITECTURE.md`（架构与 Schema）
- 当前进度：**M6 — 收官：设置接线 / 内容补全（30 课 · 12 范围）/ App 图标 / 商店物料 —— 14 步全部完成**

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

- **⌘R** 运行：应看到加载页 → 5-Tab 主界面。Home 显示内容版本 `1.0.0`
  与课程 / 精编题 / 范围表计数（10 / 23 / 6），证明 JSON 管线打通。
  Learn 已上线完整课程链路：学习路径 → 课程详情 → 课末测验（答完自动记录完成态 + XP）。
  Profile 为里程碑占位页；Drill 三训练器与 Tools 工具页均已上线。
- **⌘U** 测试：十七组共 98 个用例 ——
  `ContentValidationTests`（内容完整性 / 引用 / 禁用话术）、
  `RangeParserTests`（范围记法解析 + UTG/BTN 组合数）、
  `ModelCodingTests`（紧凑编码往返 / 归一化 / 169 格完整性）、
  `ProgressServiceTests`（完成态 / XP 幂等 / 流水写入）、
  `CheckpointQuizViewModelTests`（测验状态机）、
  `HandEvaluatorTests`（7 张评牌）、`PlayerClassifierTests`（分类规则 ↔ 内容一致）、
  `ScenarioEngineTests`（无尽出题与范围表事实）、`DrillScoringEngineTests`（判分 + XP）、
  `DrillProgressServiceTests`（流水 / 错题快照）、`DrillSessionViewModelTests`（会话状态机）、
  `RangeLibraryTests`（范围表组合数 / 位置单调性）、`HandMatrixTests`（13×13 矩阵几何）、
  `StatCalculatorViewModelTests`（VPIP / PFR / AF 计算）、`PlayerTypeToolViewModelTests`（输入 → 分类联动）、
  `ProgressStoreTests`、`SettingsStoreTests`（设置单例 / 主题映射 / 触感总闸）（等级门槛 / 连续天数 / 每日奖励 / SRS 调度）。
- 内容改动后可在仓库根额外运行 `python3 tools/validate_content.py` 做离线校验。

---

## 3. 目录结构

| 路径 | 职责 |
| --- | --- |
| `GTOAcademy/App/` | 入口、启动引导（AppBootstrap）、依赖容器、5-Tab 根视图 |
| `GTOAcademy/Models/Core/` | 扑克领域：Card · HandClass(169) · HoleCards · Board · HandRank · Position · 动作 |
| `GTOAcademy/Models/Training/` | 内容侧：Lesson · Scenario×3 · Range · PlayerStats · 各 Config · LocalizedText |
| `GTOAcademy/Models/Persistence/` | SwiftData：UserProgress · DrillRecord · MistakeReviewItem · AppSettings |
| `GTOAcademy/Services/` | 纯逻辑（当前：RangeParser；M3 起加入引擎与分类器） |
| `GTOAcademy/Repositories/` | ContentLoader（manifest 驱动）+ 三个只读查询仓库 |
| `GTOAcademy/DesignSystem/` | Theme 色板 · Typo 字体 · Spacing/Radius · Haptics · Motion |
| `GTOAcademy/Views/` | 页面（M1 为 Home 数据页 + 占位页） |
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
  correct/acceptable；`lessonRef` 必须是真实课程 id。
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

## 没有 Mac？在云端编译与测试（GitHub Actions）

仓库已内置 `.github/workflows/ci.yml`，推送到 GitHub 后无需任何本地 macOS：

1. 在 GitHub 新建仓库，把本目录整个推上去（Windows 用 Git for Windows 即可）。
2. 打开仓库 **Actions** 标签——每次 push / PR 自动运行，也可点 **Run workflow** 手动触发。
3. 流水线两段：Ubuntu 上秒级跑 `tools/validate_content.py`（内容先把关，省 macOS 分钟数）；通过后 macOS 云跑机执行 `xcodegen generate` + `xcodebuild test`（自动挑选可用 iPhone 模拟器，免签名，跑满 17 组 98 用例）。失败会把 `TestResults.xcresult` 作为 artifact 上传，可在 Windows 下载留存。
4. Windows 本地随时可自助校验内容：`python tools\validate_content.py`（注意 Windows 下命令是 `python`）。

公开仓库的 Actions 免费；私有仓库注意 macOS 分钟按更高倍率计费。后续要发 TestFlight，可在此工作流上追加 fastlane 签名与上传。

## 6. 已知缺口（按计划推进）

| 缺口 | 处理 |
| --- | --- |
| 代码在本环境未经真实 Xcode 编译，可能需一轮小修 | 把 build 报错贴回来，或交 Claude Code 自动修到全绿 |
| App 图标为空占位 | M6 视觉打磨阶段交付 |
| 复习题面为紧凑信息版（无完整行动历史） | v1.1 增强 |
| UI 框架文案走 `L10n` 内联双语 | M6 迁移到 Localizable.xcstrings |
| 精编场景 23 / 45（PRD AC-E1，翻牌街目标 ≥30） | v1.1 内容扩充 |
| L10n 迁移 Localizable.xcstrings（UI 串已全经 LocalizedText 单点） | v1.1 |
