import SwiftUI
import SwiftData

/// 学习路径：按轨道分组的课程列表，带完成态与轨道进度。
struct LearnPathView: View {
    @Environment(AppDependencies.self) private var deps
    @Query private var progressRecords: [UserProgress]

    private var completedIDs: Set<String> {
        Set(progressRecords.first?.completedLessonIDs ?? [])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                ForEach(deps.lessons.tracks) { track in
                    trackSection(track)
                }
            }
            .padding(Spacing.s16)
            .readableWidth()
        }
        .background(Theme.inkBackground)
        .navigationTitle(L10n.tabLearn)
        .navigationDestination(for: Lesson.self) { lesson in
            LessonDetailView(lesson: lesson)
        }
    }

    private func trackSection(_ track: LessonTrack) -> some View {
        let lessons = deps.lessons.lessons(inTrack: track.id)
        let doneCount = lessons.filter { completedIDs.contains($0.id) }.count
        let trackDone = !lessons.isEmpty && doneCount == lessons.count

        return VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(track.title.localized)
                        .font(Typo.title)
                        .foregroundStyle(Theme.textPrimary)
                    if let subtitle = track.subtitle {
                        Text(subtitle.localized)
                            .font(Typo.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Text("\(doneCount)/\(lessons.count)")
                    .font(Typo.caption)
                    .monospacedDigit()
                    .foregroundStyle(trackDone ? Theme.goldMoment : Theme.textSecondary)
                    .padding(.horizontal, Spacing.s12)
                    .padding(.vertical, Spacing.s4)
                    .background(Theme.surface, in: Capsule())
            }

            VStack(spacing: Spacing.s8) {
                ForEach(lessons) { lesson in
                    NavigationLink(value: lesson) {
                        LessonRowView(lesson: lesson,
                                      completed: completedIDs.contains(lesson.id))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct LessonRowView: View {
    let lesson: Lesson
    let completed: Bool

    var body: some View {
        HStack(spacing: Spacing.s12) {
            ZStack {
                Circle()
                    .fill(completed ? Theme.feltAccent.opacity(0.18) : Theme.surfaceElevated)
                    .frame(width: 34, height: 34)
                if completed {
                    Image(systemName: "checkmark")
                        .font(.system(.footnote, weight: .bold))
                        .foregroundStyle(Theme.feltAccent)
                } else {
                    Text("\(lesson.order)")
                        .font(Typo.caption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(lesson.title.localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(LocalizedText(
                    zh: "\(lesson.minutes) 分钟 · \(lesson.quizIDs.count) 题",
                    en: "\(lesson.minutes) min · \(lesson.quizIDs.count) questions").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.s12)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview {
    let library = try! ContentLoader.load()
    return NavigationStack { LearnPathView() }
        .environment(AppDependencies(content: library))
        .modelContainer(
            for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
            inMemory: true)
}
