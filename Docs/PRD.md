# PRD · Texas Holdem Trainer: GTO Academy（德州扑克训练学院）

| 字段 | 值 |
|---|---|
| 文档版本 | 1.0 |
| 日期 | 2026-06-11 |
| 状态 | 开发基线（§13 三个决策项确认后冻结） |
| 适用范围 | App v1.0（App Store 付费下载版） |

---

## 1. 产品定位

**一句话**：一款 100% 离线的德州扑克教学训练 App，把"新手 → GTO 思维玩家"的成长路径拆成 **课程学习 → 互动训练 → 错题复习** 三个闭环，让用户每天 10 分钟完成一次有反馈的刻意练习。

- **平台**：iOS 18+，iPhone 优先，iPad 自适应同一构建
- **技术**：原生 SwiftUI（无 WebView 套壳），SwiftData，Swift Charts
- **价格**：App Store 付费下载 USD $4.99；v1.0 **无 IAP、无订阅、无广告、无登录、无网络依赖**
- **商店类别**：Education（主）/ Card Games 相关（次）
- **默认牌局语境**：6-max No-Limit Texas Hold'em 现金局，100bb 有效筹码（题目明确标注例外情况除外）

### 1.1 红线（不可妥协，贯穿全部 14 个阶段）

1. 无真钱对局、真钱下注、奖品、抽奖、充值筹码、赌场/真钱平台导流。
2. App 内所有筹码、底池、胜率、分数均为**虚构教学单位**：不可兑换、不可提现、不可购买真实价值。
3. 不使用"保证盈利 / 稳赚 / 职业保证"类话术；GTO 相关表述一律使用 "GTO-inspired / solver-inspired / balanced strategy fundamentals"，不声称完美 solver 输出。
4. 不使用 WSOP、WPT、任何赌场或扑克品牌的商标、Logo、素材；全部视觉资源原创或明确可商用授权。
5. 不动态下载、安装、执行任何可改变功能的代码（未来仅允许同步纯内容 JSON）。

---

## 2. 目标用户与用户故事

| 画像 | 现状 | 核心痛点 | 主要使用模块 |
|---|---|---|---|
| P1 新手 | 知道基本规则或刚学会 | 不知道哪些牌能玩、位置是什么、术语看不懂 | Learn 新手课 → 翻前训练（简单档） |
| P2 休闲进阶 | 会玩，靠感觉，偶有盈利 | 入池太松/太紧没概念，翻后下注全凭直觉 | 指标计算器 → 翻前/翻后训练 → 玩家分类 |
| P3 学习型 Grinder | 想系统建立 GTO 框架 | 知道名词但串不成体系，缺训练反馈 | GTO 课程路径 → 翻后训练（进阶档）→ 错题本 |

**用户故事（验收时回查）**

- US-1（P1）：作为新手，我想按顺序学完"规则 → 位置 → 起手牌"，每课 5 分钟内完成并立刻做题验证。
- US-2（P2）：作为休闲玩家，我想输入自己或对手的 VPIP/PFR 数据，App 告诉我这是什么类型的玩家、该如何调整。
- US-3（P2）：作为休闲玩家，我想在翻前训练里看到"为什么这手牌在这个位置该 fold"，而不是只给对错。
- US-4（P3）：作为进阶玩家，我想用 13×13 Range Matrix 查看每个位置的开局范围，并点击任意格子看 combo 数和解释。
- US-5（P3）：作为进阶玩家，我想让错题自动进入复习队列，按间隔重复出现直到我连续做对。
- US-6（全部）：作为用户，我想在飞机上无网络也能完整使用全部功能。

---

## 3. 目标 / 非目标

### 3.1 v1.0 目标

- G1 完整学习路径：4 个课程轨道、8 个用户等级，从规则到 GTO 基础概念全覆盖（§5-F、§5-G）。
- G2 三类训练器：翻前决策、翻后下注、玩家类型判断，每题必带解释（§5-B/D/E）。
- G3 工具箱：Range Matrix、VPIP/PFR 计算器、Pot Odds/Equity 工具（§5-I）。
- G4 错题本 + 间隔复习闭环（§5-H）。
- G5 100% 离线可用，零数据收集（§8）。
- G6 通过 App Store 审核并以正确年龄分级上架（§9）。

### 3.2 v1.0 明确不做（防 scope creep，写入代码注释与 backlog）

- 整局 AI 对战引擎（v1.0 只做"决策点训练"：给定局面选动作，不模拟完整一手牌的多街博弈对局）。
- Solver 集成或实时 GTO 计算；不展示宣称精确的混合频率解。
- 多人对战、排行榜、社交功能。
- 账号系统、云同步（本地 SwiftData 即可；iCloud 同步列入 v1.x 评估）。
- 手牌历史导入、实时 HUD（涉及第三方平台条款风险，长期不做）。
- AI Coach 对话功能（若 v1.x 做：必须走自建后端代理，客户端不放任何第三方 AI key，并明确告知用户数据流向）。
- IAP / 订阅（v1.1 若卖高级题库：走 Apple IAP，新内容为纯 JSON 数据包）。
- Android / 其他平台。

---

## 4. 信息架构（5 Tab）

| Tab | 页面 | 关键模块 |
|---|---|---|
| 1 Home | HomeDashboardView | 今日训练入口（混合 5-10 题）、连续训练天数（streak）、当前等级与进度环、推荐下一课、错题待复习数角标 |
| 2 Learn | LearnPathView → LessonDetailView | 4 轨道课程路径图、课内"概念/例子/常见错误/训练题"四段结构、课末小测 |
| 3 Drill | DrillHubView → 三个训练器 | 翻前训练（题库模式 + 无尽模式）、翻后训练、玩家类型判断；难度与位置筛选 |
| 4 Tools | ToolsView | Range Matrix（按位置/动作查表，可点击、可缩放）、VPIP/PFR/3-Bet/AF 计算器、Pot Odds & Equity 工具 |
| 5 Profile | ProfileView | 等级与 XP、统计图表（Charts）、错题本、设置（主题/四色牌/动效/阈值配置）、免责声明、关于 |

导航规则：每个 Tab 独立 NavigationStack；任何训练可从 Home 一键直达；错题本可从 Profile 与 Home 角标进入。

---

## 5. 功能需求（FR-A ~ FR-I）

每条功能附验收标准（AC），QA 阶段逐条回查。

### FR-A 新手课程（Learn 轨道 1）

内容：手牌等级（高牌→皇家同花顺）、六个位置（UTG/HJ/CO/BTN/SB/BB）及其行动顺序、筹码深度概念（20bb/40bb/100bb 的策略差异概览）、底池赔率、隐含赔率、有效筹码、翻前主动权（initiative）。

- AC-A1 每课包含四段：概念、例子（含具体牌例）、常见错误、≥3 道训练题。
- AC-A2 位置课配交互式桌面图，点击座位高亮显示该位置说明。
- AC-A3 全部术语首次出现时给中英对照（如"翻前主动权 initiative"）。

### FR-B 翻前训练（Preflop Trainer）

**题型（v1.0 三类）**

1. RFI（前面无人入池）：给定位置 + 手牌 → 选 raise / fold（SB 额外含 limp 选项的教学说明，但默认答案体系为 raise-or-fold）。
2. vs RFI（面对前位 open）：给定位置 + 手牌 + 前位动作 → 选 fold / call / 3-bet。
3. BB 防守：BB 面对各位置 open → fold / call / 3-bet。

**模式**

- 题库模式：精编题（含完整解释、错误选项逐一说明、关联课程链接）。
- 无尽模式：引擎按位置随机发手牌，正确答案由内置 RangeChart 查表得出，解释自动生成（"A5s 在 BTN 的 RFI 范围内：可被压制时仍有同花/顺子潜力 + blocker 价值"风格的模板化解释）。

- AC-B1 每道精编题包含：正确答案、为什么、为什么其他选项不对、学习目标、关联课程 id。
- AC-B2 覆盖全部 6 个位置；难度三档（明显题 / 边缘题 / 陷阱题）。
- AC-B3 答题后可一键打开当前位置的 Range Matrix 对照。
- AC-B4 范围数据标注"训练近似（GTO-inspired approximation）"，UI 与文档均不得宣称 solver 精确解。

### FR-C 指标教学与计算器

公式（教学与计算器统一使用，写入 `Content/config` 并在课程中展示）：

```
VPIP = voluntarily_put_money_in_pot / preflop_opportunities × 100
PFR  = preflop_raise_count / preflop_opportunities × 100
3Bet = three_bet_count / three_bet_opportunities × 100
AF   = (bets + raises) / calls
```

- AC-C1 用户输入样本（手数、入池次数、加注次数、3bet 次数/机会、bet/raise/call 次数）→ 输出四项指标 + 玩家类型判断 + 解释。
- AC-C2 样本量 < 30 手时显著标注"样本不足，仅供参考"（阈值可配置）。
- AC-C3 计算器内嵌"这个指标意味着什么"的教学折叠区。

### FR-D 玩家类型判断

默认阈值（6-max 现金局，全部存于 `Content/config/classifier.json`，**不硬编码在 UI 或逻辑里**）：

| 类型 | VPIP | PFR | 附加条件 | 典型画像 |
|---|---|---|---|---|
| Maniac | > 40 | > 30 | AF 高（≥3 若有数据） | 疯狂施压 |
| Passive Fish | > 35 | < 10 | AF < 1.5 | 松弱被动 |
| Calling Station | > 30 | < 12 | Fold to C-bet 低（< 40% 若有数据） | 什么都跟 |
| Nit | < 18 | < 14 | — | 过紧 |
| TAG | 18–25 | 15–22 | — | 紧凶 |
| LAG | 26–35 | ≥ 22 | — | 松凶 |

**关键设计**：上表区间存在重叠（如 VPIP 38 / PFR 8 同时命中 Passive Fish 与 Calling Station），分类器必须按**有序规则表**判定（先判极端型，后判常规型，顺序即上表行序），并输出：类型 + 置信度（按样本量与命中边界距离）+ 解释文案 + "如何针对该类型调整"建议。未命中任何规则 → 输出"边界型"并给出最接近的两个类型。

- AC-D1 全部阈值、规则顺序、样本量下限可经配置文件调整，改配置不改代码。
- AC-D2 玩家类型训练题（给一组数据选类型）≥ 25 题，每题含解释。
- AC-D3 每个类型附"针对策略"教学卡（如：对 Calling Station 减少 bluff、加大 value bet 尺寸）。

### FR-E 翻后下注训练（Postflop Trainer）

**场景字段**：Hero 位置、Hero 手牌、公共牌（翻牌/转牌/河牌街可选）、底池大小、有效筹码、对手类型（FR-D 六类之一或"未知"）、前序动作。

**用户选择**：动作 fold / check / call / bet / raise + 尺寸 25% / 33% / 50% / 75% / 100% / overbet（125–150%）。

**解释分类法（每题的 explanation 必须归入并解释其一或多项）**：Value bet（被更差的牌跟注）、Bluff（让更好的牌弃牌）、Protection、Thin value、Check back（摊牌价值/控池）、C-bet（范围优势/坚果优势/牌面结构）、Donk bet、Probe bet、Delayed c-bet。

- AC-E1 v1.0 精编场景 ≥ 45 个，翻牌街为主（≥30），转牌/河牌各 ≥ 7。
- AC-E2 评分支持"最优 / 可接受 / 错误"三档：尺寸相邻档（如最优 33%，选 50%）可记可接受并说明差异。
- AC-E3 每题标注对手类型对答案的影响（同一局面对 Nit 与对 Calling Station 的动作差异，是 exploit 教学的核心素材）。

### FR-F GTO 学习路径（Learn 轨道 4）

定位表述（全 App 统一）："GTO-inspired training / GTO fundamentals"。课程：Range vs hand 思维 → Range vs range → Combo counting → Equity realization → MDF 最小防守频率 → Bluff/Value ratio → Blocker 与 unblocker → Polarized vs merged range → Exploitative deviation（如何依据对手类型偏离均衡）。

- AC-F1 每个概念课配 1 个可交互小工具或图示（如 MDF 课内嵌 `1 − bet/(bet+pot)` 计算条）。
- AC-F2 Exploitative deviation 课与 FR-D 的"针对策略"卡片互链。

### FR-G 训练成长系统

| 等级 | 名称 | 解锁条件（通过该级 checkpoint 测验 ≥ 80%） |
|---|---|---|
| 1 | Beginner | 默认 |
| 2 | Preflop Rookie | 完成新手课轨道 |
| 3 | Aggression Builder | 完成 VPIP/PFR/3-bet 课程组 |
| 4 | Postflop Student | 完成翻后基础课程组 |
| 5 | Range Thinker | 完成 range/combo/blocker 课程组 |
| 6 | Exploit Player | 玩家类型训练正确率 ≥ 80%（近 30 题） |
| 7 | GTO Apprentice | 完成 MDF/平衡课程组 + checkpoint |
| 8 | GTO Grinder | 全部课程 + 综合测验 |

XP 规则（可配置）：完成课程 +20，精编题答对 +5，无尽模式答对 +2，可接受档 +2，错题复习通过 +3，每日首训 +10；streak 按"当天完成 ≥1 次训练"计。

- AC-G1 等级、XP 数值表全部在 `Content/config/levels.json`。
- AC-G2 Home 与 Profile 的进度展示一致（同一数据源）。

### FR-H 错题本（含间隔复习）

每条错题记录：场景 id、用户选择、正确答案、错误原因（题目 explanation 引用）、关联课程链接、下次复习时间、当前复习阶段。

复习调度（SRS，可配置）：答错入库 stage 0 → 复习正确依次进入 +1 天 / +3 天 / +7 天 / +14 天 → stage 4 后移出队列（标记"已掌握"）；任意复习再错 → 回 stage 0。

- AC-H1 Home 显示今日到期复习数；错题本支持按训练器类型筛选。
- AC-H2 复习题使用原场景重新作答，不允许直接看答案标记掌握。

### FR-I 工具箱

1. **Range Matrix（13×13）**：AA→32o 全 169 格；区分 pair / suited / offsuit；按位置 + 动作（RFI、vs-open 等）切换图表；点击格子显示 combo 数、是否在范围内、频率与一句解释；双指缩放 + 平移；图例常驻。
2. **VPIP/PFR 计算器**：即 FR-C 的工具入口。
3. **Pot Odds & Equity 工具**：输入底池与需跟注额 → 所需胜率；outs → 2/4 法则估算 equity；对照表（常见听牌 outs）。

- AC-I1 Matrix 在 iPhone 15/16 尺寸下不缩放即可点准任意格（命中区 ≥ 36pt 或提供放大态）。
- AC-I2 全部工具离线可用、即时计算、无网络请求。

---

## 6. 内容范围（v1.0 数量基线）

| 内容 | 数量 | 说明 |
|---|---|---|
| 课程 | 30 课 / 4 轨道 | 新手 7 · 翻前与指标 7 · 翻后 7 · GTO 9 |
| 精编训练题 | ≥ 160 | 翻前 90 · 翻后 45 · 玩家类型 25 |
| 无尽模式 | 不限 | 由 RangeChart 引擎生成 |
| Range 图表 | 12 张 | RFI×6 · BB 防守 vs UTG/CO/BTN/SB ×4 · 3-bet（SB vs BTN、BTN vs CO）×2 |
| Checkpoint 测验 | 8 套 | 对应 8 个等级门槛 |
| 语言 | zh-Hans + en | 内容 JSON 双语字段，UI 走 String Catalog（§13-D1） |

所有 ranges 为**原创整理的 GTO-inspired 训练近似**（基于公开扑克理论常识自行构建），不复制任何付费 solver 产品或训练网站的图表，规避版权与"虚假 solver 宣传"双重风险。

---

## 7. 设计要求（"高级感"的可执行定义）

**方向**：专业训练工具的克制质感，而非赌场氛围。参照系是"职业牌手的学习软件"，不是"老虎机大厅"。

- **色彩**：深色优先。墨色底（近黑的冷灰蓝）+ 桌面毛毡绿仅作强调色 + 金色仅用于成就/等级时刻；浅色主题同 token 体系映射。禁止霓虹、闪烁金币、辣妹荷官类视觉。
- **签名元素（全 App 记忆点）**：Range Matrix 的"点亮"——格子按频率以毛毡绿不同饱和度渲染，进入页面时按对角线波次点亮（尊重"减弱动态"设置时直接呈现）。
- **排版**：系统字体（SF Pro），数字统一 `monospacedDigit`（筹码、赔率、百分比对齐不跳动）；牌面字符用大号粗重字重。
- **动效**：发牌滑入、翻牌 3D flip、答案揭示 spring、XP 数字滚动；全部接入 `accessibilityReduceMotion` 降级为淡入。
- **触感（Haptics）**：答对 success、答错 error（轻，不惩罚感）、翻牌 light、升级 heavy + 成就页。
- **四色牌选项**：设置中可开启 four-color deck（♠黑 ♥红 ♦蓝 ♣绿），提升可读性与色弱友好度。
- **可访问性**：Dynamic Type 支持至 XXL 不破版；VoiceOver 为牌面提供完整朗读（"黑桃 A、红心 K"）、Matrix 格子朗读（"A K suited，开局加注"）；前景/背景对比 ≥ 4.5:1。
- **版权**：花色、牌面、桌面、图标全部原创绘制；App Icon 草案在阶段 11 给 3 个方向。

---

## 8. 非功能需求

| 项 | 要求 |
|---|---|
| 离线 | 全功能 100% 离线；v1.0 不申请任何网络访问（仅 StoreKit 评分弹窗走系统） |
| 性能 | 冷启动 < 1.5s（iPhone 12 基准）；训练答题交互 60fps；Matrix 缩放无卡顿 |
| 包体 | < 50MB（内容为文本 JSON，主要体积来自图像资产） |
| 隐私 | 零收集：无 analytics SDK、无 ATT、无登录；学习数据仅存本机 SwiftData；隐私标签 = "Data Not Collected"；崩溃数据仅 Apple 系统级 opt-in 渠道 |
| 本地化 | UI：String Catalog（zh-Hans、en）；内容：JSON 双语字段；新增语言不改代码 |
| 设备 | iPhone（iOS 18+）全机型；iPad 同构建自适应（宽屏下 Learn/Tools 用双栏），不允许拉伸截断 |
| 稳定性 | 零编译错误、零警告目标；crash-free（Apple opt-in 口径）≥ 99.5% |

---

## 9. App Store 合规要求

### 9.1 App Review Notes（提交时原文使用，附中文备注版）

> This app is a poker education and strategy training simulator. It does not offer real-money gaming, wagering, contests, prizes, lotteries, purchasable chips, cash-out functionality, or links to gambling operators. All chips and pots are fictional training units. The app works fully offline, collects no user data, and contains no in-app purchases in v1.0.

### 9.2 年龄分级

App Store Connect 分级问卷**如实勾选"模拟赌博"相关项**。本 App 每道训练题都包含模拟下注情境，属于"频繁"档；按 Apple 现行（2025 年改版后）分级体系，预期落在 **18+**（旧体系对应 17+）。这会损失部分曝光，但虚报分级是拒审与下架风险，不做规避。免责声明页同步注明"本 App 面向成年人，内容仅供教学"。

### 9.3 对应审核指南要点

- 5.3（赌博）：无真钱要素，备注中明确自证；不链接任何真钱运营方。
- 2.5.2：无动态可执行代码下载；未来内容更新仅限数据 JSON。
- 3.1.1：v1.0 无任何应用内购买；未来数字内容解锁必须走 Apple IAP。
- 2.3（元数据）：名称、副标题、截图、描述如实反映"教学训练模拟器"，不出现盈利承诺、赌场暗示。
- 隐私：提交 Privacy Nutrition Label = Data Not Collected；提供隐私政策 URL（说明"不收集"本身也需政策页承载）。

### 9.4 免责声明页（DisclaimerView）要点

教学用途、虚构筹码、不构成财务建议、不鼓励赌博、所在地法律自查提示、未成年人不适用、负责任游戏资源提示（文案在阶段 14 出全文）。

### 9.5 禁用话术清单（写入 ComplianceChecklist 扫描）

"保证盈利"、"稳赚"、"提现"、"真钱"、"职业保证"、"perfect GTO"、"solver-exact" 等词不得出现在 UI 文案、商店元数据与课程正文（教学中解释概念时的引述除外，由人工复核）。

---

## 10. 成功指标与质量门槛

商店侧：上架后评分目标 ≥ 4.5；退款率监控；截图 A/B（上架后迭代）。

工程质量门槛（每阶段 QA 检查）：编译零错误零警告；题目 explanation 覆盖率 100%（无"只有答案"的题）；课程四段结构完整率 100%；核心服务单测覆盖（HandEvaluator / RangeParser / PlayerClassifier / DrillScoringEngine / SRS 全部有边界用例）；可访问性抽查（Dynamic Type XXL、VoiceOver 关键路径）。

产品效果以用户本机统计呈现（个人正确率趋势、等级进度），v1.0 不上传任何聚合数据。

---

## 11. 里程碑（对应你给的 14 步）

| 里程碑 | 覆盖步骤 | 交付物 |
|---|---|---|
| M0 文档 | 1–2 | PRD、技术架构（本阶段） |
| M1 骨架与数据 | 3–4 | 可编译工程骨架、全部 Models、JSON Schema + 首批内容样例 |
| M2 课程系统 | 5 | Learn 轨道、LessonDetail、checkpoint 测验、首批课程内容 |
| M3 训练器 | 6–8 | Preflop Trainer（含无尽模式）、PlayerClassifier + 训练、Postflop Trainer |
| M4 范围与工具 | 9 | Range Matrix、12 张 range 数据、计算器 |
| M5 进度闭环 | 10 | 等级/XP/streak、错题本 + SRS、统计图表 |
| M6 视觉打磨 | 11 | 设计系统落地、动效、深浅主题、App Icon 草案 ×3 |
| M7 测试与构建 | 12–13 | 全部单测、构建/测试指引（你本地或 Claude Code 执行） |
| M8 上架包 | 14 | 上架清单、截图清单、审核备注、隐私政策草案、分级问卷答案 |

---

## 12. 风险与对策

| 风险 | 等级 | 对策 |
|---|---|---|
| 内容量大（30 课 + 160 题双语）是 v1.0 最大工程量 | 高 | 内容随 M2–M4 分批产出；schema 先行；模板化生成 + 人工口径校对清单 |
| 18+ 分级降低曝光 | 中 | 不可规避，如实申报；靠元数据与截图把"教学工具"定位讲清 |
| Range 数据准确性争议 | 中 | 全部标注"训练近似"；区分 exploit 与 GTO-inspired 建议；阈值与范围开放配置 |
| 构建验证不在我侧 | 中 | 代码以零警告为目标交付；每阶段附构建步骤；推荐用 Claude Code 自动执行步骤 13 |
| 审核被归入赌博类细查 | 中 | 审核备注自证 + 免责声明页 + 零网络零 IAP 降低复杂度 |
| iPad 适配工时膨胀 | 低 | v1.0 标准为"自适应不破版"，双栏仅 Learn/Tools 两处 |

---

## 13. 待你确认的决策（已设默认值，不阻塞开工）

| # | 决策 | 默认值 | 说明 |
|---|---|---|---|
| D1 | v1.0 语言范围 | zh-Hans + en 双语 | 名称是英文、付费 App 需要全球市场；内容 JSON 双语字段一次生成。若只要中文，内容工作量约减 40% |
| D2 | 主屏显示名 | GTO Academy | 完整名 "Texas Holdem Trainer: GTO Academy" 作商店名；主屏放不下长名 |
| D3 | Bundle ID | com.yourcompany.gtoacademy | 占位，建项目前替换为你的开发者账号域名 |
