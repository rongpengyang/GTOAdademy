import SwiftUI
import SwiftData

/// 玩家类型判断训练：读数据面板，六选一（二元判分）。
struct PlayerTypeTrainerView: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: DrillSessionViewModel<PlayerTypeScenario>
    @State private var selection: PlayerType?

    init(engine: ScenarioEngine) {
        _session = State(initialValue: DrillSessionViewModel(
            items: engine.dailyPlayerType()))
    }

    var body: some View {
        Group {
            if session.finished {
                DrillSummaryView(
                    title: LocalizedText(zh: "类型判断完成", en: "Type drill complete"),
                    correct: session.correctCount,
                    acceptable: session.acceptableCount,
                    wrong: session.wrongCount,
                    xpEarned: session.xpEarned,
                    onDone: { dismiss() })
            } else if let scenario = session.currentItem {
                questionView(scenario)
            }
        }
        .navigationTitle(LocalizedText(zh: "玩家类型", en: "Player Types").localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 题面

    private func questionView(_ scenario: PlayerTypeScenario) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                progressHeader

                Text(LocalizedText(zh: "根据数据面板，这是哪类玩家？",
                                   en: "Read the panel — what type is this player?").localized)
                    .font(Typo.title)
                    .foregroundStyle(Theme.textPrimary)

                statsCard(scenario)
                typeGrid(scenario)

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
                    en: "Read \(session.currentIndex + 1) of \(session.items.count)").localized)
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

    private func statsCard(_ scenario: PlayerTypeScenario) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack(spacing: Spacing.s32) {
                bigStat(label: "VPIP", value: percent(scenario.stats.vpip))
                bigStat(label: "PFR", value: percent(scenario.stats.pfr))
                Spacer()
            }

            Divider()
                .overlay(Theme.surfaceElevated)

            statRow(label: LocalizedText(zh: "激进度 AF", en: "Aggression (AF)"),
                    value: number(scenario.stats.af))
            statRow(label: LocalizedText(zh: "面对 C-Bet 弃牌率", en: "Fold to C-Bet"),
                    value: optionalPercent(scenario.stats.foldToCbet))
            statRow(label: LocalizedText(zh: "样本", en: "Sample"),
                    value: LocalizedText(zh: "\(scenario.stats.hands) 手",
                                         en: "\(scenario.stats.hands) hands").localized)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func bigStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(label)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(Typo.statValue)
                .monospacedDigit()
                .foregroundStyle(Theme.feltAccent)
        }
    }

    private func statRow(label: LocalizedText, value: String) -> some View {
        HStack {
            Text(label.localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Typo.body)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func format(_ value: Double) -> String {
        value == value.rounded()
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private func percent(_ value: Double) -> String { format(value) + "%" }

    private func optionalPercent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return percent(value)
    }

    private func number(_ value: Double?) -> String {
        guard let value else { return "—" }
        return format(value)
    }

    // MARK: - 选项

    private func typeGrid(_ scenario: PlayerTypeScenario) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s8), count: 2),
            spacing: Spacing.s8) {
            ForEach(PlayerType.allCases, id: \.self) { type in
                typeButton(type, scenario: scenario)
            }
        }
    }

    private func typeButton(_ type: PlayerType,
                            scenario: PlayerTypeScenario) -> some View {
        Button {
            select(type, scenario: scenario)
        } label: {
            Text(type.title.localized)
                .font(Typo.headline)
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s12)
                .background(buttonBackground(type, scenario: scenario),
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(buttonBorder(type, scenario: scenario), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(session.revealed)
    }

    private func buttonBackground(_ type: PlayerType,
                                  scenario: PlayerTypeScenario) -> Color {
        guard session.revealed else { return Theme.surface }
        if type == scenario.correct { return Theme.feltAccent.opacity(0.16) }
        if type == selection { return Theme.danger.opacity(0.14) }
        return Theme.surface
    }

    private func buttonBorder(_ type: PlayerType,
                              scenario: PlayerTypeScenario) -> Color {
        guard session.revealed else { return .clear }
        if type == scenario.correct { return Theme.feltAccent }
        if type == selection { return Theme.danger }
        return .clear
    }

    // MARK: - 判分与反馈

    private func select(_ type: PlayerType, scenario: PlayerTypeScenario) {
        guard !session.revealed else { return }
        selection = type

        let grade = DrillScoringEngine.grade(type, for: scenario)
        let xp = DrillScoringEngine.xp(for: grade, mode: .curated, rules: deps.content.levels.xp)
        session.reveal(grade: grade, xp: xp)

        ProgressStore.recordDrillAnswer(
            scenarioID: scenario.id, trainer: "playerType",
            grade: grade, xp: xp,
            track: deps.content.levels, in: modelContext)
        if grade == .wrong {
            ProgressStore.logMistake(
                scenarioID: scenario.id, trainer: "playerType",
                userChoice: type.rawValue,
                correctAnswer: scenario.correct.rawValue,
                reason: scenario.explanation,
                lessonRef: scenario.lessonRef,
                srs: deps.content.srs, in: modelContext)
        }

        if grade == .correct { Haptics.correct() } else { Haptics.wrong() }
    }

    @ViewBuilder
    private func feedbackSection(_ scenario: PlayerTypeScenario) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            if let grade = session.lastGrade {
                GradeBadge(grade: grade)
            }

            ExplanationCard(
                title: LocalizedText(
                    zh: "正确答案 · \(scenario.correct.title.zh)",
                    en: "Answer · \(scenario.correct.title.en)"),
                text: scenario.explanation,
                accent: Theme.feltAccent)

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
                 : LocalizedText(zh: "下一题", en: "Next read").localized)
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
        PlayerTypeTrainerView(engine: ScenarioEngine(
            scenarios: dependencies.scenarios, ranges: dependencies.ranges))
    }
    .environment(dependencies)
    .modelContainer(
        for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
        inMemory: true)
}
