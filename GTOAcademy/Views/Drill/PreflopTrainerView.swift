import SwiftUI
import SwiftData

/// 精编题与无尽 RFI 共用的题面载体。
private enum PreflopItem: Sendable {
    case curated(PreflopScenario)
    case endless(EndlessRFISpot)

    var id: String {
        switch self {
        case .curated(let scenario): scenario.id
        case .endless(let spot): spot.id
        }
    }

    var position: Position {
        switch self {
        case .curated(let scenario): scenario.position
        case .endless(let spot): spot.position
        }
    }

    var hand: HandClass {
        switch self {
        case .curated(let scenario): scenario.hand
        case .endless(let spot): spot.hand
        }
    }

    var facing: [FacingAction] {
        switch self {
        case .curated(let scenario): scenario.facing
        case .endless: []
        }
    }

    var correct: PreflopChoice {
        switch self {
        case .curated(let scenario): scenario.correct
        case .endless(let spot): spot.correct
        }
    }

    var lessonRef: String? {
        switch self {
        case .curated(let scenario): scenario.lessonRef
        case .endless: "l2-02-range-shapes"
        }
    }

    var availableChoices: [PreflopChoice] {
        switch self {
        case .curated(let scenario):
            return [.fold, .call, .raise, .threeBet].filter { choice in
                choice == scenario.correct
                    || scenario.acceptable.contains(choice)
                    || scenario.wrongChoices[choice.rawValue] != nil
            }
        case .endless:
            return [.fold, .raise]
        }
    }
}

/// 翻前训练器：精编（固定题组，先易后难）+ 无尽（范围表事实出题）。
struct PreflopTrainerView: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRecords: [AppSettings]
    private var fourColor: Bool { settingsRecords.first?.fourColorDeck ?? true }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let mode: DrillMode
    private let engine: ScenarioEngine
    @State private var session: DrillSessionViewModel<PreflopItem>
    @State private var selection: PreflopChoice?

    init(mode: DrillMode, engine: ScenarioEngine) {
        self.mode = mode
        self.engine = engine
        var generator = SystemRandomNumberGenerator()
        let items: [PreflopItem]
        switch mode {
        case .curated:
            items = engine.dailyPreflop().map(PreflopItem.curated)
        case .endless:
            items = engine.endlessRFISpot(index: 0, using: &generator)
                .map { [PreflopItem.endless($0)] } ?? []
        }
        _session = State(initialValue: DrillSessionViewModel(
            items: items, isEndless: mode == .endless))
    }

    var body: some View {
        Group {
            if session.finished {
                DrillSummaryView(
                    title: mode == .curated
                        ? LocalizedText(zh: "精编训练完成", en: "Curated set complete")
                        : LocalizedText(zh: "无尽训练结算", en: "Endless session recap"),
                    correct: session.correctCount,
                    acceptable: session.acceptableCount,
                    wrong: session.wrongCount,
                    xpEarned: session.xpEarned,
                    onDone: { dismiss() })
            } else if let item = session.currentItem {
                trainerBody(item)
            } else {
                Text(LocalizedText(zh: "暂无可用题目。", en: "No spots available.").localized)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.inkBackground)
            }
        }
        .navigationTitle(mode == .curated
            ? LocalizedText(zh: "翻前 · 精编", en: "Preflop · Curated").localized
            : LocalizedText(zh: "翻前 · 无尽", en: "Preflop · Endless").localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if mode == .endless, !session.finished, session.answeredCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        session.finishSession()
                    } label: {
                        Text(LocalizedText(zh: "结束", en: "End").localized)
                            .font(Typo.caption)
                    }
                }
            }
        }
    }

    // MARK: - 题面

    private func trainerBody(_ item: PreflopItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                progressHeader
                spotCard(item)

                HStack(spacing: Spacing.s12) {
                    ForEach(item.availableChoices, id: \.self) { choice in
                        choiceButton(choice, item: item)
                    }
                }

                if session.revealed {
                    feedbackSection(item)
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
        HStack {
            Text(mode == .curated
                 ? LocalizedText(zh: "第 \(session.currentIndex + 1) / \(session.items.count) 题",
                                 en: "Spot \(session.currentIndex + 1) of \(session.items.count)").localized
                 : LocalizedText(zh: "已答 \(session.answeredCount) 题",
                                 en: "\(session.answeredCount) answered").localized)
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
    }

    private func spotCard(_ item: PreflopItem) -> some View {
        VStack(spacing: Spacing.s16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(LocalizedText(zh: "你的位置", en: "Your seat").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(item.position.rawValue.uppercased())
                        .font(Typo.title)
                        .foregroundStyle(Theme.feltAccent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.s4) {
                    Text(LocalizedText(zh: "前面的行动", en: "Action so far").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(facingText(item).localized)
                        .font(Typo.body)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }

            HStack(spacing: Spacing.s8) {
                ForEach(item.hand.displayCards, id: \.code) { card in
                    CardView(card: card, fourColor: fourColor)
                }
            }

            Text(item.hand.notation)
                .font(Typo.caption)
                .monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func facingText(_ item: PreflopItem) -> LocalizedText {
        guard !item.facing.isEmpty else {
            return LocalizedText(zh: "前面全部弃牌，轮到你。", en: "Folded to you.")
        }
        let zh = item.facing.map { facing in
            "\(facing.position.rawValue.uppercased()) \(actionTitle(facing.action).zh)\(sizeText(facing.sizeBB, suffixZH: true))"
        }.joined(separator: "，")
        let en = item.facing.map { facing in
            "\(facing.position.rawValue.uppercased()) \(actionTitle(facing.action).en)\(sizeText(facing.sizeBB, suffixZH: false))"
        }.joined(separator: ", ")
        return LocalizedText(zh: zh, en: en)
    }

    private func actionTitle(_ action: PlayerAction) -> LocalizedText {
        switch action {
        case .fold: LocalizedText(zh: "弃牌", en: "folds")
        case .check: LocalizedText(zh: "过牌", en: "checks")
        case .call: LocalizedText(zh: "跟注", en: "calls")
        case .bet: LocalizedText(zh: "下注", en: "bets")
        case .raise: LocalizedText(zh: "加注至", en: "raises to")
        }
    }

    private func sizeText(_ sizeBB: Double?, suffixZH: Bool) -> String {
        guard let sizeBB else { return "" }
        let number = sizeBB == sizeBB.rounded()
            ? String(format: "%.0f", sizeBB)
            : String(format: "%.1f", sizeBB)
        return " \(number)bb"
    }

    // MARK: - 作答

    private func choiceButton(_ choice: PreflopChoice, item: PreflopItem) -> some View {
        Button {
            select(choice, item: item)
        } label: {
            Text(choice.title.localized)
                .font(Typo.headline)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s12)
                .background(choiceBackground(choice, item: item),
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(choiceBorder(choice, item: item), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(session.revealed)
    }

    private func choiceBackground(_ choice: PreflopChoice, item: PreflopItem) -> Color {
        guard session.revealed else { return Theme.surface }
        if choice == item.correct { return Theme.feltAccent.opacity(0.16) }
        if choice == selection {
            return session.lastGrade == .acceptable
                ? Theme.goldMoment.opacity(0.16)
                : Theme.danger.opacity(0.14)
        }
        return Theme.surface
    }

    private func choiceBorder(_ choice: PreflopChoice, item: PreflopItem) -> Color {
        guard session.revealed else { return .clear }
        if choice == item.correct { return Theme.feltAccent }
        if choice == selection {
            return session.lastGrade == .acceptable ? Theme.goldMoment : Theme.danger
        }
        return .clear
    }

    private func select(_ choice: PreflopChoice, item: PreflopItem) {
        guard !session.revealed else { return }
        selection = choice

        let grade: DrillGrade
        switch item {
        case .curated(let scenario):
            grade = DrillScoringEngine.grade(choice, for: scenario)
        case .endless(let spot):
            grade = choice == spot.correct ? .correct : .wrong
        }
        let xp = DrillScoringEngine.xp(for: grade, mode: mode, rules: deps.content.levels.xp)
        session.reveal(grade: grade, xp: xp)

        ProgressStore.recordDrillAnswer(
            scenarioID: item.id, trainer: "preflop",
            grade: grade, xp: xp,
            track: deps.content.levels, in: modelContext)
        if grade == .wrong {
            ProgressStore.logMistake(
                scenarioID: item.id, trainer: "preflop",
                userChoice: choice.rawValue,
                correctAnswer: item.correct.rawValue,
                reason: mistakeReason(item),
                lessonRef: item.lessonRef,
                srs: deps.content.srs, in: modelContext)
        }

        switch grade {
        case .correct: Haptics.correct()
        case .acceptable: Haptics.tap()
        case .wrong: Haptics.wrong()
        }
    }

    private func mistakeReason(_ item: PreflopItem) -> LocalizedText {
        switch item {
        case .curated(let scenario): scenario.explanation
        case .endless(let spot): endlessExplanation(spot)
        }
    }

    private func endlessExplanation(_ spot: EndlessRFISpot) -> LocalizedText {
        let percent = String(format: "%.0f", spot.rangePercent)
        let seat = spot.position.rawValue.uppercased()
        return spot.isInRange
            ? LocalizedText(
                zh: "\(spot.hand.notation) 在 \(seat) 约 \(percent)% 的开局基线范围内——标准加注。",
                en: "\(spot.hand.notation) sits inside the \(seat) ~\(percent)% opening baseline — a standard raise.")
            : LocalizedText(
                zh: "\(spot.hand.notation) 在 \(seat) 约 \(percent)% 的开局基线之外——弃牌。",
                en: "\(spot.hand.notation) falls outside the \(seat) ~\(percent)% opening baseline — fold.")
    }

    // MARK: - 反馈与推进

    @ViewBuilder
    private func feedbackSection(_ item: PreflopItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            if let grade = session.lastGrade {
                GradeBadge(grade: grade)
            }

            switch item {
            case .curated(let scenario):
                curatedFeedback(scenario)
            case .endless(let spot):
                ExplanationCard(
                    title: LocalizedText(zh: "范围事实", en: "Range fact"),
                    text: endlessExplanation(spot),
                    accent: session.lastGrade == .wrong ? Theme.danger : Theme.feltAccent)
            }
        }
    }

    @ViewBuilder
    private func curatedFeedback(_ scenario: PreflopScenario) -> some View {
        if session.lastGrade == .wrong,
           let selection,
           let wrongText = scenario.wrongChoices[selection.rawValue] {
            ExplanationCard(
                title: LocalizedText(zh: "问题出在哪", en: "What went wrong"),
                text: wrongText,
                accent: Theme.danger)
        }

        ExplanationCard(
            title: LocalizedText(zh: "正确思路 · \(scenario.correct.title.zh)",
                                 en: "The right idea · \(scenario.correct.title.en)"),
            text: scenario.explanation,
            accent: session.lastGrade == .acceptable ? Theme.goldMoment : Theme.feltAccent)

        if !scenario.acceptable.isEmpty {
            Text(LocalizedText(
                zh: "也可接受：" + scenario.acceptable.map(\.title.zh).joined(separator: "、"),
                en: "Also acceptable: " + scenario.acceptable.map(\.title.en).joined(separator: ", ")).localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.goldMoment)
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

    private var advanceButton: some View {
        Button {
            Haptics.tap()
            selection = nil
            withAnimation(Motion.entrance(reduceMotion: reduceMotion)) {
                if mode == .endless {
                    var generator = SystemRandomNumberGenerator()
                    let next = engine
                        .endlessRFISpot(index: session.answeredCount, using: &generator)
                        .map(PreflopItem.endless)
                    session.advance(appending: next)
                } else {
                    session.advance()
                }
            }
        } label: {
            Text(mode == .curated && session.isLastItem
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

#Preview("精编") {
    let library = try! ContentLoader.load()
    let dependencies = AppDependencies(content: library)
    return NavigationStack {
        PreflopTrainerView(
            mode: .curated,
            engine: ScenarioEngine(scenarios: dependencies.scenarios, ranges: dependencies.ranges))
    }
    .environment(dependencies)
    .modelContainer(
        for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
        inMemory: true)
}
