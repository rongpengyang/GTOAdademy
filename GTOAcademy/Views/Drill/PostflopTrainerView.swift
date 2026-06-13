import SwiftUI
import SwiftData

/// 翻后下注训练：精编题，按「动作 + 尺寸」三档判分（correct / acceptable / wrong）。
struct PostflopTrainerView: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRecords: [AppSettings]
    private var fourColor: Bool { settingsRecords.first?.fourColorDeck ?? true }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: DrillSessionViewModel<PostflopScenario>
    @State private var selection: PostflopChoice?

    init(engine: ScenarioEngine) {
        _session = State(initialValue: DrillSessionViewModel(
            items: engine.dailyPostflop()))
    }

    var body: some View {
        Group {
            if session.finished {
                DrillSummaryView(
                    title: LocalizedText(zh: "翻后训练完成", en: "Postflop drill complete"),
                    correct: session.correctCount,
                    acceptable: session.acceptableCount,
                    wrong: session.wrongCount,
                    xpEarned: session.xpEarned,
                    onDone: { dismiss() })
            } else if let scenario = session.currentItem {
                questionView(scenario)
            }
        }
        .navigationTitle(LocalizedText(zh: "翻后下注", en: "Postflop").localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 题面

    private func questionView(_ scenario: PostflopScenario) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                progressHeader
                spotCard(scenario)
                choiceGrid(scenario)
                if session.revealed {
                    feedbackSection(scenario)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(Spacing.s16)
            .readableWidth()
        }
        .background(Theme.inkBackground)
        .safeAreaInset(edge: .bottom) {
            if session.revealed { advanceButton }
        }
        .animation(Motion.entrance(reduceMotion: reduceMotion), value: session.revealed)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack {
                Text(LocalizedText(
                    zh: "第 \(session.currentIndex + 1) / \(session.items.count) 题",
                    en: "Spot \(session.currentIndex + 1) of \(session.items.count)").localized)
                    .font(Typo.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("✓ \(session.correctCount)")
                    .font(Typo.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.feltAccent)
                if session.wrongCount > 0 {
                    Text("✗ \(session.wrongCount)")
                        .font(Typo.caption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.danger)
                }
            }
            ProgressView(
                value: Double(session.currentIndex + (session.revealed ? 1 : 0)),
                total: Double(max(session.items.count, 1)))
                .tint(Theme.feltAccent)
        }
    }

    private func spotCard(_ scenario: PostflopScenario) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack(spacing: Spacing.s8) {
                infoPill(streetTitle(scenario.street))
                infoPill("\(scenario.heroPosition.rawValue.uppercased()) vs \(scenario.villainPosition.rawValue.uppercased())")
                if let type = scenario.villainType {
                    infoPill(type.title.localized)
                }
            }
            HStack(spacing: Spacing.s8) {
                infoPill(LocalizedText(zh: "底池 \(bb(scenario.potBB))",
                                       en: "Pot \(bb(scenario.potBB))").localized)
                infoPill(LocalizedText(zh: "有效 \(bb(scenario.effStackBB))",
                                       en: "Eff \(bb(scenario.effStackBB))").localized)
            }

            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(LocalizedText(zh: "公共牌", en: "Board").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: Spacing.s8) {
                    ForEach(scenario.board, id: \.self) { card in
                        CardView(card: card, width: 44, fourColor: fourColor)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(LocalizedText(zh: "你的手牌", en: "Your hand").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: Spacing.s12) {
                    HStack(spacing: Spacing.s4) {
                        CardView(card: scenario.heroHand.first, width: 44, fourColor: fourColor)
                        CardView(card: scenario.heroHand.second, width: 44, fourColor: fourColor)
                    }
                    if let rank = madeHand(scenario) {
                        Text(rank.category.title.localized)
                            .font(Typo.caption)
                            .foregroundStyle(Theme.feltAccent)
                            .padding(.horizontal, Spacing.s12)
                            .padding(.vertical, Spacing.s4)
                            .background(Theme.feltAccent.opacity(0.12), in: Capsule())
                    }
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: Spacing.s4) {
                ForEach(scenario.history, id: \.self) { line in
                    Text(line.localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(Typo.caption)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s4)
            .background(Theme.surfaceElevated, in: Capsule())
    }

    private func madeHand(_ scenario: PostflopScenario) -> HandRank? {
        guard let board = Board(cards: scenario.board) else { return nil }
        return HandEvaluator.evaluate(hole: scenario.heroHand, board: board)
    }

    private func streetTitle(_ street: BettingRound) -> String {
        switch street {
        case .preflop: LocalizedText(zh: "翻前", en: "Preflop").localized
        case .flop: LocalizedText(zh: "翻牌", en: "Flop").localized
        case .turn: LocalizedText(zh: "转牌", en: "Turn").localized
        case .river: LocalizedText(zh: "河牌", en: "River").localized
        }
    }

    private func bb(_ value: Double) -> String {
        let number = value == value.rounded()
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return number + " bb"
    }

    // MARK: - 选项

    /// 正确 + 可接受 + 错误三集合并去重，按动作序与尺寸升序稳定排列。
    private func choices(for scenario: PostflopScenario) -> [PostflopChoice] {
        var seen = Set<String>()
        var result: [PostflopChoice] = []
        let all = [scenario.correct] + scenario.acceptable
            + scenario.wrongChoices.keys.compactMap(PostflopChoice.init(key:))
        for choice in all where seen.insert(choice.key).inserted {
            result.append(choice)
        }
        return result.sorted { lhs, rhs in
            let lhsIndex = PlayerAction.allCases.firstIndex(of: lhs.action) ?? 0
            let rhsIndex = PlayerAction.allCases.firstIndex(of: rhs.action) ?? 0
            if lhsIndex != rhsIndex { return lhsIndex < rhsIndex }
            return (lhs.sizePct ?? 0) < (rhs.sizePct ?? 0)
        }
    }

    private func choiceGrid(_ scenario: PostflopScenario) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s8), count: 3),
            spacing: Spacing.s8) {
            ForEach(choices(for: scenario), id: \.key) { choice in
                choiceButton(choice, scenario: scenario)
            }
        }
    }

    private func choiceButton(_ choice: PostflopChoice,
                              scenario: PostflopScenario) -> some View {
        Button {
            select(choice, scenario: scenario)
        } label: {
            Text(choiceLabel(choice))
                .font(Typo.headline)
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s12)
                .background(choiceBackground(choice, scenario: scenario),
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(choiceBorder(choice, scenario: scenario), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(session.revealed)
    }

    private func choiceLabel(_ choice: PostflopChoice) -> String {
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

    private func choiceBackground(_ choice: PostflopChoice,
                                  scenario: PostflopScenario) -> Color {
        guard session.revealed else { return Theme.surface }
        if choice.key == scenario.correct.key { return Theme.feltAccent.opacity(0.16) }
        if choice.key == selection?.key {
            return session.lastGrade == .acceptable
                ? Theme.goldMoment.opacity(0.16)
                : Theme.danger.opacity(0.14)
        }
        return Theme.surface
    }

    private func choiceBorder(_ choice: PostflopChoice,
                              scenario: PostflopScenario) -> Color {
        guard session.revealed else { return .clear }
        if choice.key == scenario.correct.key { return Theme.feltAccent }
        if choice.key == selection?.key {
            return session.lastGrade == .acceptable ? Theme.goldMoment : Theme.danger
        }
        return .clear
    }

    // MARK: - 判分与反馈

    private func select(_ choice: PostflopChoice, scenario: PostflopScenario) {
        guard !session.revealed else { return }
        selection = choice

        let grade = DrillScoringEngine.grade(choice, for: scenario)
        let xp = DrillScoringEngine.xp(for: grade, mode: .curated, rules: deps.content.levels.xp)
        session.reveal(grade: grade, xp: xp)

        ProgressStore.recordDrillAnswer(
            scenarioID: scenario.id, trainer: "postflop",
            grade: grade, xp: xp,
            track: deps.content.levels, in: modelContext)
        if grade == .wrong {
            ProgressStore.logMistake(
                scenarioID: scenario.id, trainer: "postflop",
                userChoice: choice.key,
                correctAnswer: scenario.correct.key,
                reason: scenario.explanation,
                lessonRef: scenario.lessonRef,
                srs: deps.content.srs, in: modelContext)
        }

        switch grade {
        case .correct: Haptics.correct()
        case .acceptable: Haptics.tap()
        case .wrong: Haptics.wrong()
        }
    }

    @ViewBuilder
    private func feedbackSection(_ scenario: PostflopScenario) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            if let grade = session.lastGrade {
                GradeBadge(grade: grade)
            }

            if session.lastGrade == .wrong,
               let selection,
               let why = scenario.wrongChoices[selection.key] {
                ExplanationCard(
                    title: LocalizedText(zh: "问题出在哪", en: "What went wrong"),
                    text: why,
                    accent: Theme.danger)
            }

            ExplanationCard(
                title: LocalizedText(
                    zh: "正确思路 · \(choiceLabel(scenario.correct))",
                    en: "The right idea · \(choiceLabel(scenario.correct))"),
                text: scenario.explanation,
                accent: session.lastGrade == .acceptable ? Theme.goldMoment : Theme.feltAccent)

            if !scenario.acceptable.isEmpty {
                Text(LocalizedText(
                    zh: "也可接受：" + scenario.acceptable.map(choiceLabel).joined(separator: "、"),
                    en: "Also acceptable: " + scenario.acceptable.map(choiceLabel).joined(separator: ", ")).localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: Spacing.s8) {
                ForEach(scenario.reasonTags, id: \.self) { tag in
                    Text("#" + tag)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, Spacing.s8)
                        .padding(.vertical, Spacing.s4)
                        .background(Theme.surfaceElevated, in: Capsule())
                }
            }

            Label {
                Text(scenario.objective.localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            } icon: {
                Image(systemName: "scope")
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var advanceButton: some View {
        Button {
            Haptics.tap()
            selection = nil
            withAnimation(Motion.entrance(reduceMotion: reduceMotion)) {
                session.advance()
            }
        } label: {
            Text(session.isLastItem
                 ? LocalizedText(zh: "查看结果", en: "See results").localized
                 : LocalizedText(zh: "下一题", en: "Next spot").localized)
                .font(Typo.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s12)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.feltAccent)
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s8)
        .background(Theme.inkBackground.opacity(0.95))
    }
}

#Preview {
    let library = try! ContentLoader.load()
    let dependencies = AppDependencies(content: library)
    return NavigationStack {
        PostflopTrainerView(engine: ScenarioEngine(
            scenarios: dependencies.scenarios, ranges: dependencies.ranges))
    }
    .environment(dependencies)
    .modelContainer(
        for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
        inMemory: true)
}
