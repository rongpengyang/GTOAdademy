import SwiftUI
import SwiftData

// MARK: - 复习卡（值快照）

/// 一道复习题。尽量从当前内容还原原题；原题已下线时退化为快照自测卡。
struct ReviewCard: Identifiable, Hashable, Sendable {
    enum Question: Hashable, Sendable {
        case preflop(PreflopScenario)
        case postflop(PostflopScenario)
        case playerType(PlayerTypeScenario)
        /// 原题不在当前内容版本中：凭双语快照自测。
        case snapshotOnly
    }

    /// scenarioID（与错题记录一一对应）。
    let id: String
    let trainer: String
    let question: Question
    let lastWrongChoice: String
    let correctAnswer: String
    let reason: LocalizedText

    static func make(from item: MistakeReviewItem,
                     scenarios: ScenarioRepository) -> ReviewCard {
        let question: Question = switch item.trainer {
        case "preflop":
            scenarios.preflop.first { $0.id == item.scenarioID }
                .map(Question.preflop) ?? .snapshotOnly
        case "postflop":
            scenarios.postflop.first { $0.id == item.scenarioID }
                .map(Question.postflop) ?? .snapshotOnly
        case "playerType":
            scenarios.playerType.first { $0.id == item.scenarioID }
                .map(Question.playerType) ?? .snapshotOnly
        default:
            .snapshotOnly
        }
        return ReviewCard(id: item.scenarioID,
                          trainer: item.trainer,
                          question: question,
                          lastWrongChoice: item.userChoice,
                          correctAnswer: item.correctAnswer,
                          reason: LocalizedText(zh: item.reasonZH, en: item.reasonEN))
    }
}

// MARK: - 共享格式化（错题本 / 复习 / Profile 共用）

enum ReviewFormat {
    static func trainerLabel(_ trainer: String) -> String {
        switch trainer {
        case "preflop": LocalizedText(zh: "翻前训练", en: "Preflop").localized
        case "postflop": LocalizedText(zh: "翻后训练", en: "Postflop").localized
        case "playerType": LocalizedText(zh: "读人训练", en: "Player reads").localized
        case "quiz": LocalizedText(zh: "课程测验", en: "Lesson quiz").localized
        case "review": LocalizedText(zh: "错题复习", en: "Review").localized
        default: trainer
        }
    }

    static func actionLabel(_ action: PlayerAction) -> String {
        switch action {
        case .fold: LocalizedText(zh: "弃牌", en: "folds").localized
        case .check: LocalizedText(zh: "过牌", en: "checks").localized
        case .call: LocalizedText(zh: "跟注", en: "calls").localized
        case .bet: LocalizedText(zh: "下注", en: "bets").localized
        case .raise: LocalizedText(zh: "加注", en: "raises").localized
        }
    }

    static func postflopLabel(_ choice: PostflopChoice) -> String {
        switch choice.action {
        case .check: LocalizedText(zh: "过牌", en: "Check").localized
        case .fold: LocalizedText(zh: "弃牌", en: "Fold").localized
        case .call: LocalizedText(zh: "跟注", en: "Call").localized
        case .bet:
            LocalizedText(zh: "下注 \(choice.sizePct ?? 0)%",
                          en: "Bet \(choice.sizePct ?? 0)%").localized
        case .raise:
            LocalizedText(zh: "加注 \(choice.sizePct ?? 0)%",
                          en: "Raise \(choice.sizePct ?? 0)%").localized
        }
    }

    /// 把持久化的答案键（"3bet" / "bet33" / "maniac"…）还原成人话。
    static func answerLabel(trainer: String, raw: String) -> String {
        switch trainer {
        case "preflop":
            PreflopChoice(rawValue: raw)?.title.localized ?? raw
        case "postflop":
            PostflopChoice(key: raw).map(postflopLabel) ?? raw
        case "playerType":
            PlayerType(rawValue: raw)?.title.localized ?? raw
        default:
            raw
        }
    }
}

// MARK: - 复习会话

/// SRS 复习：复用 DrillSessionViewModel。通过（含可接受）→ 阶段晋级 + reviewPass XP；
/// 答错 → 阶段归零明日再来。落账经由 ProgressStore.recordReviewOutcome。
struct ReviewSessionView: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRecords: [AppSettings]
    private var fourColor: Bool { settingsRecords.first?.fourColorDeck ?? true }

    @Environment(\.dismiss) private var dismiss

    @State private var session: DrillSessionViewModel<ReviewCard>
    @State private var selectedKey: String?

    init(cards: [ReviewCard]) {
        _session = State(initialValue: DrillSessionViewModel(items: cards))
    }

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            if session.finished {
                DrillSummaryView(
                    title: LocalizedText(zh: "复习完成", en: "Review complete"),
                    correct: session.correctCount,
                    acceptable: session.acceptableCount,
                    wrong: session.wrongCount,
                    xpEarned: session.xpEarned,
                    onDone: { dismiss() })
            } else if let card = session.currentItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s16) {
                        header(card)
                        questionSection(card)
                        optionSection(card)
                        if session.revealed { feedbackSection(card) }
                    }
                    .padding(Spacing.s16)
                    .readableWidth()
                }
                .animation(Motion.standard, value: session.revealed)
            }
        }
        .navigationTitle(LocalizedText(
            zh: "复习 \(session.currentIndex + 1)/\(session.items.count)",
            en: "Review \(session.currentIndex + 1)/\(session.items.count)").localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 题面

    private func header(_ card: ReviewCard) -> some View {
        HStack {
            Text(ReviewFormat.trainerLabel(card.trainer))
                .font(Typo.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.feltAccent)
                .padding(.horizontal, Spacing.s12)
                .padding(.vertical, Spacing.s4)
                .background(Theme.feltAccent.opacity(0.12), in: Capsule())
            Spacer()
        }
    }

    @ViewBuilder
    private func questionSection(_ card: ReviewCard) -> some View {
        switch card.question {
        case .preflop(let scenario):
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(facingLine(scenario))
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text(scenario.hand.notation)
                        .font(Typo.statValue)
                        .foregroundStyle(Theme.textPrimary)
                    Text(scenario.position.displayName)
                        .font(Typo.headline)
                        .foregroundStyle(Theme.goldMoment)
                }
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

        case .postflop(let scenario):
            VStack(alignment: .leading, spacing: Spacing.s12) {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    ForEach(scenario.history, id: \.self) { line in
                        Text(line.localized)
                            .font(Typo.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                HStack(spacing: 6) {
                    ForEach(scenario.board, id: \.self) { CardView(card: $0, width: 38, fourColor: fourColor) }
                }
                HStack(spacing: Spacing.s12) {
                    HStack(spacing: 6) {
                        CardView(card: scenario.heroHand.first, width: 44, fourColor: fourColor)
                        CardView(card: scenario.heroHand.second, width: 44, fourColor: fourColor)
                    }
                    VStack(alignment: .leading, spacing: Spacing.s4) {
                        Text(LocalizedText(zh: "底池 \(bb(scenario.potBB))bb",
                                           en: "Pot \(bb(scenario.potBB))bb").localized)
                        Text(LocalizedText(zh: "有效 \(bb(scenario.effStackBB))bb",
                                           en: "Eff. \(bb(scenario.effStackBB))bb").localized)
                    }
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

        case .playerType(let scenario):
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(LocalizedText(zh: "这位对手是什么类型？", en: "What type is this villain?").localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(statsLine(scenario.stats))
                    .font(Typo.body.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

        case .snapshotOnly:
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(LocalizedText(zh: "原题已随内容更新下线。",
                                   en: "The original spot left this content version.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(LocalizedText(zh: "回忆一下：这个局面的正确思路是什么？",
                                   en: "From memory: what was the right play here?").localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }

    // MARK: 选项

    @ViewBuilder
    private func optionSection(_ card: ReviewCard) -> some View {
        VStack(spacing: Spacing.s8) {
            switch card.question {
            case .preflop(let scenario):
                ForEach(preflopOptions(scenario), id: \.self) { choice in
                    optionButton(choice.title.localized,
                                 key: choice.rawValue,
                                 grade: DrillScoringEngine.grade(choice, for: scenario)) {
                        answer(card, grade: DrillScoringEngine.grade(choice, for: scenario),
                               key: choice.rawValue)
                    }
                }
            case .postflop(let scenario):
                ForEach(postflopOptions(scenario), id: \.self) { choice in
                    optionButton(ReviewFormat.postflopLabel(choice),
                                 key: choice.key,
                                 grade: DrillScoringEngine.grade(choice, for: scenario)) {
                        answer(card, grade: DrillScoringEngine.grade(choice, for: scenario),
                               key: choice.key)
                    }
                }
            case .playerType(let scenario):
                ForEach(PlayerType.allCases, id: \.self) { type in
                    optionButton(type.title.localized,
                                 key: type.rawValue,
                                 grade: DrillScoringEngine.grade(type, for: scenario)) {
                        answer(card, grade: DrillScoringEngine.grade(type, for: scenario),
                               key: type.rawValue)
                    }
                }
            case .snapshotOnly:
                optionButton(LocalizedText(zh: "我记得正确思路", en: "I remember it").localized,
                             key: "recall-pass", grade: .correct) {
                    answer(card, grade: .correct, key: "recall-pass")
                }
                optionButton(LocalizedText(zh: "想不起来了", en: "I forgot").localized,
                             key: "recall-fail", grade: .wrong) {
                    answer(card, grade: .wrong, key: "recall-fail")
                }
            }
        }
    }

    private func optionButton(_ label: String,
                              key: String,
                              grade: DrillGrade,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.s12) {
                Text(label)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if session.revealed {
                    switch grade {
                    case .correct:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.feltAccent)
                    case .acceptable:
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Theme.goldMoment)
                    case .wrong:
                        if selectedKey == key {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.danger)
                        }
                    }
                }
            }
            .padding(Spacing.s12)
            .background(optionBackground(key: key, grade: grade),
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(session.revealed)
    }

    private func optionBackground(key: String, grade: DrillGrade) -> Color {
        guard session.revealed else { return Theme.surface }
        switch grade {
        case .correct: return Theme.feltAccent.opacity(0.16)
        case .acceptable: return Theme.goldMoment.opacity(0.14)
        case .wrong: return selectedKey == key ? Theme.danger.opacity(0.14) : Theme.surface
        }
    }

    // MARK: 反馈与推进

    @ViewBuilder
    private func feedbackSection(_ card: ReviewCard) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            if let grade = session.lastGrade {
                GradeBadge(grade: grade)
            }
            ExplanationCard(
                title: LocalizedText(
                    zh: "正确思路 · \(ReviewFormat.answerLabel(trainer: card.trainer, raw: card.correctAnswer))",
                    en: "The right idea · \(ReviewFormat.answerLabel(trainer: card.trainer, raw: card.correctAnswer))"),
                text: card.reason,
                accent: Theme.feltAccent)
            Text(LocalizedText(
                zh: "上次你的选择：\(ReviewFormat.answerLabel(trainer: card.trainer, raw: card.lastWrongChoice))",
                en: "Your last pick: \(ReviewFormat.answerLabel(trainer: card.trainer, raw: card.lastWrongChoice))").localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)

            Button {
                selectedKey = nil
                session.advance()
            } label: {
                Text(session.isLastItem
                     ? LocalizedText(zh: "完成复习", en: "Finish review").localized
                     : LocalizedText(zh: "下一题", en: "Next").localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.inkBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
                    .background(Theme.feltAccent,
                                in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func answer(_ card: ReviewCard, grade: DrillGrade, key: String) {
        guard !session.revealed else { return }
        selectedKey = key
        // 复习的「通过」含可接受档：思路在框内即可晋级，避免对边缘题过度惩罚。
        let passed = grade != .wrong
        let xp = passed ? deps.content.levels.xp.reviewPass : 0
        session.reveal(grade: passed ? .correct : .wrong, xp: xp)
        ProgressStore.recordReviewOutcome(scenarioID: card.id,
                                          passed: passed,
                                          srs: deps.content.srs,
                                          track: deps.content.levels,
                                          in: modelContext)
        passed ? Haptics.correct() : Haptics.wrong()
    }

    // MARK: 文案小工具

    private func preflopOptions(_ scenario: PreflopScenario) -> [PreflopChoice] {
        var allowed: Set<PreflopChoice> = [scenario.correct]
        allowed.formUnion(scenario.acceptable)
        allowed.formUnion(scenario.wrongChoices.keys.compactMap(PreflopChoice.init(rawValue:)))
        return PreflopChoice.allCases.filter(allowed.contains)
    }

    private func postflopOptions(_ scenario: PostflopScenario) -> [PostflopChoice] {
        var keys = [scenario.correct.key]
        keys += scenario.acceptable.map(\.key)
        keys += scenario.wrongChoices.keys
        return Set(keys)
            .compactMap(PostflopChoice.init(key:))
            .sorted {
                (actionOrder($0.action), $0.sizePct ?? 0)
                    < (actionOrder($1.action), $1.sizePct ?? 0)
            }
    }

    private func actionOrder(_ action: PlayerAction) -> Int {
        switch action {
        case .check: 0
        case .fold: 1
        case .call: 2
        case .bet: 3
        case .raise: 4
        }
    }

    private func facingLine(_ scenario: PreflopScenario) -> String {
        guard !scenario.facing.isEmpty else {
            return LocalizedText(zh: "前面全部弃牌，轮到你行动", en: "Folds to you").localized
        }
        return scenario.facing.map { facing in
            var text = "\(facing.position.displayName) \(ReviewFormat.actionLabel(facing.action))"
            if let size = facing.sizeBB { text += " \(bb(size))bb" }
            return text
        }
        .joined(separator: " · ")
    }

    private func statsLine(_ stats: PlayerStats) -> String {
        var parts = ["VPIP \(bb(stats.vpip))", "PFR \(bb(stats.pfr))"]
        if let af = stats.af { parts.append("AF \(String(format: "%.1f", af))") }
        if let ftc = stats.foldToCbet { parts.append("FtC \(bb(ftc))%") }
        parts.append(LocalizedText(zh: "样本 \(stats.hands) 手",
                                   en: "\(stats.hands) hands").localized)
        return parts.joined(separator: " · ")
    }

    private func bb(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

#Preview {
    if let content = try? ContentLoader.load(),
       let scenario = content.preflop.first {
        NavigationStack {
            ReviewSessionView(cards: [
                ReviewCard(id: scenario.id,
                           trainer: "preflop",
                           question: .preflop(scenario),
                           lastWrongChoice: "fold",
                           correctAnswer: scenario.correct.rawValue,
                           reason: scenario.explanation),
            ])
        }
        .environment(AppDependencies(content: content))
        .modelContainer(for: [UserProgress.self, DrillRecord.self,
                              MistakeReviewItem.self, AppSettings.self],
                        inMemory: true)
        .preferredColorScheme(.dark)
    }
}
