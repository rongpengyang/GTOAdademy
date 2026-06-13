import SwiftUI
import SwiftData

/// 课程详情：分块阅读流（概念 / 例子 / 常见错误 / 技巧）+ 底部测验入口。
struct LessonDetailView: View {
    @Environment(AppDependencies.self) private var deps
    @Query private var progressRecords: [UserProgress]

    let lesson: Lesson
    @State private var showQuiz = false

    private var isCompleted: Bool {
        progressRecords.first?.completedLessonIDs.contains(lesson.id) ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                metaRow
                ForEach(Array(lesson.blocks.enumerated()), id: \.offset) { _, block in
                    LessonBlockView(block: block)
                }
            }
            .padding(Spacing.s16)
            .readableWidth()
        }
        .background(Theme.inkBackground)
        .navigationTitle(lesson.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { quizButton }
        .fullScreenCover(isPresented: $showQuiz) {
            CheckpointQuizView(lesson: lesson, repository: deps.lessons)
        }
    }

    private var metaRow: some View {
        HStack(spacing: Spacing.s8) {
            metaPill(icon: "clock",
                     text: LocalizedText(zh: "\(lesson.minutes) 分钟",
                                         en: "\(lesson.minutes) min").localized,
                     tint: Theme.textSecondary)
            metaPill(icon: "questionmark.circle",
                     text: LocalizedText(zh: "\(lesson.quizIDs.count) 题",
                                         en: "\(lesson.quizIDs.count) questions").localized,
                     tint: Theme.textSecondary)
            if isCompleted {
                metaPill(icon: "checkmark.seal.fill",
                         text: LocalizedText(zh: "已完成", en: "Completed").localized,
                         tint: Theme.feltAccent)
            }
            Spacer()
        }
    }

    private func metaPill(icon: String, text: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(Typo.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s4)
            .background(Theme.surface, in: Capsule())
    }

    private var quizButton: some View {
        Button {
            Haptics.tap()
            showQuiz = true
        } label: {
            Text(quizButtonTitle)
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

    private var quizButtonTitle: String {
        let count = lesson.quizIDs.count
        return isCompleted
            ? LocalizedText(zh: "重新测验（\(count) 题）", en: "Retake quiz (\(count))").localized
            : LocalizedText(zh: "开始测验（\(count) 题）", en: "Start quiz (\(count) questions)").localized
    }
}

/// 单个内容块卡片。quizRef / unknown 不在阅读流中渲染。
private struct LessonBlockView: View {
    let block: LessonBlock

    var body: some View {
        switch block {
        case .concept(let text):
            blockCard(icon: "lightbulb.fill",
                      label: LocalizedText(zh: "概念", en: "Concept"),
                      text: text, accent: Theme.feltAccent)
        case .example(let text):
            blockCard(icon: "rectangle.and.text.magnifyingglass",
                      label: LocalizedText(zh: "例子", en: "Example"),
                      text: text, accent: Theme.textSecondary)
        case .mistake(let text):
            blockCard(icon: "exclamationmark.triangle.fill",
                      label: LocalizedText(zh: "常见错误", en: "Common mistake"),
                      text: text, accent: Theme.danger)
        case .tip(let text):
            blockCard(icon: "sparkles",
                      label: LocalizedText(zh: "技巧", en: "Tip"),
                      text: text, accent: Theme.goldMoment)
        case .quizRef, .unknown:
            EmptyView()
        }
    }

    private func blockCard(icon: String,
                           label: LocalizedText,
                           text: LocalizedText,
                           accent: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Label {
                Text(label.localized)
                    .font(Typo.caption)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: icon)
            }
            .foregroundStyle(accent)

            Text(text.localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview {
    let library = try! ContentLoader.load()
    let dependencies = AppDependencies(content: library)
    return NavigationStack {
        LessonDetailView(lesson: dependencies.lessons.lessons(inTrack: "track1").first!)
    }
    .environment(dependencies)
    .modelContainer(
        for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
        inMemory: true)
}
