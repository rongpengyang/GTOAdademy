import SwiftUI
import SwiftData

/// 课末测验：逐题作答 → 即时反馈 + 逐选项解释 → 完成颁发 XP（重复完成不重复计）。
struct CheckpointQuizView: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let lesson: Lesson
    @State private var viewModel: CheckpointQuizViewModel
    @State private var earnedXP: Int?

    init(lesson: Lesson, repository: LessonRepository) {
        self.lesson = lesson
        _viewModel = State(initialValue: CheckpointQuizViewModel(
            lesson: lesson, repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.finished {
                    resultView
                } else if let question = viewModel.currentQuestion {
                    questionView(question)
                } else {
                    Text(LocalizedText(zh: "本课暂无测验。", en: "No quiz in this lesson.").localized)
                        .font(Typo.body)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.inkBackground)
                }
            }
            .navigationTitle(lesson.title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - 答题

    private func questionView(_ question: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                progressHeader

                Text(question.prompt.localized)
                    .font(Typo.title)
                    .foregroundStyle(Theme.textPrimary)

                VStack(spacing: Spacing.s12) {
                    ForEach(question.choices.indices, id: \.self) { index in
                        choiceButton(question: question, index: index)
                    }
                }

                if viewModel.revealed {
                    explanationSection(question)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(Spacing.s16)
            .readableWidth()
        }
        .background(Theme.inkBackground)
        .safeAreaInset(edge: .bottom) {
            if viewModel.revealed {
                advanceButton
            }
        }
        .animation(Motion.entrance(reduceMotion: reduceMotion), value: viewModel.revealed)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(LocalizedText(
                zh: "第 \(viewModel.currentIndex + 1) / \(viewModel.questions.count) 题",
                en: "Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)").localized)
                .font(Typo.caption)
                .monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
            ProgressView(
                value: Double(viewModel.currentIndex + (viewModel.revealed ? 1 : 0)),
                total: Double(max(viewModel.questions.count, 1)))
                .tint(Theme.feltAccent)
        }
    }

    private func choiceButton(question: QuizQuestion, index: Int) -> some View {
        Button {
            guard !viewModel.revealed else { return }
            viewModel.select(index)
            let isCorrect = index == question.correctIndex
            ProgressStore.recordQuizAnswer(
                questionID: question.id, correct: isCorrect,
                track: deps.content.levels, in: modelContext)
            if isCorrect { Haptics.correct() } else { Haptics.wrong() }
        } label: {
            HStack(spacing: Spacing.s12) {
                Text(question.choices[index].localized)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if let icon = trailingIcon(question: question, index: index) {
                    Image(systemName: icon.name)
                        .foregroundStyle(icon.color)
                }
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground(question: question, index: index),
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(rowBorder(question: question, index: index), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.revealed)
    }

    private func rowBackground(question: QuizQuestion, index: Int) -> Color {
        guard viewModel.revealed else { return Theme.surface }
        if index == question.correctIndex { return Theme.feltAccent.opacity(0.16) }
        if index == viewModel.selection { return Theme.danger.opacity(0.14) }
        return Theme.surface
    }

    private func rowBorder(question: QuizQuestion, index: Int) -> Color {
        guard viewModel.revealed else { return .clear }
        if index == question.correctIndex { return Theme.feltAccent }
        if index == viewModel.selection { return Theme.danger }
        return .clear
    }

    private func trailingIcon(question: QuizQuestion,
                              index: Int) -> (name: String, color: Color)? {
        guard viewModel.revealed else { return nil }
        if index == question.correctIndex {
            return ("checkmark.circle.fill", Theme.feltAccent)
        }
        if index == viewModel.selection {
            return ("xmark.circle.fill", Theme.danger)
        }
        return nil
    }

    @ViewBuilder
    private func explanationSection(_ question: QuizQuestion) -> some View {
        if let selection = viewModel.selection {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                explanationCard(
                    title: selection == question.correctIndex
                        ? LocalizedText(zh: "为什么对", en: "Why it is right")
                        : LocalizedText(zh: "问题出在哪", en: "What went wrong"),
                    text: question.choiceExplanations[selection],
                    accent: selection == question.correctIndex ? Theme.feltAccent : Theme.danger)

                if selection != question.correctIndex {
                    explanationCard(
                        title: LocalizedText(zh: "正确思路", en: "The right idea"),
                        text: question.choiceExplanations[question.correctIndex],
                        accent: Theme.feltAccent)
                }

                Label {
                    Text(question.objective.localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                } icon: {
                    Image(systemName: "scope")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func explanationCard(title: LocalizedText,
                                 text: LocalizedText,
                                 accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(title.localized)
                .font(Typo.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accent)
            Text(text.localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var advanceButton: some View {
        Button {
            Haptics.tap()
            withAnimation(Motion.entrance(reduceMotion: reduceMotion)) {
                viewModel.advance()
            }
        } label: {
            Text(viewModel.isLastQuestion
                 ? LocalizedText(zh: "查看结果", en: "See results").localized
                 : LocalizedText(zh: "下一题", en: "Next question").localized)
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

    // MARK: - 结果

    private var resultView: some View {
        VStack(spacing: Spacing.s16) {
            Spacer()

            Image(systemName: viewModel.isPerfectScore ? "checkmark.seal.fill" : "flag.pattern.checkered")
                .font(.system(size: 52))
                .foregroundStyle(viewModel.isPerfectScore ? Theme.goldMoment : Theme.feltAccent)

            Text(viewModel.isPerfectScore
                 ? LocalizedText(zh: "满分通过！", en: "Perfect score!").localized
                 : LocalizedText(zh: "测验完成", en: "Quiz complete").localized)
                .font(Typo.title)
                .foregroundStyle(Theme.textPrimary)

            Text("\(viewModel.correctCount) / \(viewModel.questions.count)")
                .font(Typo.statValue)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)

            if let earnedXP, earnedXP > 0 {
                Text("+\(earnedXP) XP")
                    .font(Typo.headline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.goldMoment)
                    .padding(.horizontal, Spacing.s16)
                    .padding(.vertical, Spacing.s8)
                    .background(Theme.goldMoment.opacity(0.12), in: Capsule())
            } else {
                Text(LocalizedText(zh: "本课已完成过，不重复计 XP。",
                                   en: "Already completed — XP is awarded once.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            if !viewModel.isPerfectScore {
                Text(LocalizedText(zh: "可重新测验巩固薄弱项。",
                                   en: "Retake anytime to shore up weak spots.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(LocalizedText(zh: "完成", en: "Done").localized)
                    .font(Typo.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.feltAccent)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.inkBackground)
        .onAppear {
            guard earnedXP == nil else { return }
            let xp = ProgressStore.completeLesson(
                lesson.id,
                track: deps.content.levels,
                in: modelContext)
            earnedXP = xp
            if xp > 0 { Haptics.levelUp() } else { Haptics.correct() }
        }
    }
}

#Preview {
    let library = try! ContentLoader.load()
    let dependencies = AppDependencies(content: library)
    return CheckpointQuizView(
        lesson: dependencies.lessons.lessons(inTrack: "track1").first!,
        repository: dependencies.lessons)
        .environment(dependencies)
        .modelContainer(
            for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
            inMemory: true)
}
