import SwiftUI
import SwiftData

/// 错题本：到期复习 → 排队中 → 已掌握。复习会话从这里发起。
struct MistakeBookView: View {
    @Environment(AppDependencies.self) private var deps
    @Query(sort: \MistakeReviewItem.nextReviewAt) private var items: [MistakeReviewItem]
    @State private var now = Date.now

    /// 单次复习会话题量上限（保持节奏，剩余的下次再来）。
    private let sessionCap = 12

    private var due: [MistakeReviewItem] {
        items.filter { $0.masteredAt == nil && $0.nextReviewAt <= now }
    }

    private var upcoming: [MistakeReviewItem] {
        items.filter { $0.masteredAt == nil && $0.nextReviewAt > now }
    }

    private var mastered: [MistakeReviewItem] {
        items.filter { $0.masteredAt != nil }
    }

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s16) {
                        startReviewSection
                        if !due.isEmpty {
                            section(LocalizedText(zh: "到期复习", en: "Due now"), rows: due)
                        }
                        if !upcoming.isEmpty {
                            section(LocalizedText(zh: "排队中", en: "Scheduled"), rows: upcoming)
                        }
                        if !mastered.isEmpty {
                            section(LocalizedText(zh: "已掌握", en: "Mastered"), rows: mastered)
                        }
                    }
                    .padding(Spacing.s16)
                }
            }
        }
        .navigationTitle(LocalizedText(zh: "错题本", en: "Mistake Book").localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { now = .now }
    }

    // MARK: - 复习入口

    @ViewBuilder
    private var startReviewSection: some View {
        if due.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Label(LocalizedText(zh: "今天没有到期的复习", en: "Nothing due today").localized,
                      systemImage: "checkmark.seal")
                    .font(Typo.headline)
                    .foregroundStyle(Theme.feltAccent)
                Text(LocalizedText(
                    zh: "错题会按 \(intervalsText) 天的间隔回来找你，直到掌握。",
                    en: "Misses come back on a \(intervalsText)-day schedule until mastered.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        } else {
            NavigationLink {
                ReviewSessionView(cards: dueCards)
            } label: {
                HStack(spacing: Spacing.s8) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                    Text(LocalizedText(zh: "开始复习（\(min(due.count, sessionCap)) 道到期）",
                                       en: "Start review (\(min(due.count, sessionCap)) due)").localized)
                        .font(Typo.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(Theme.inkBackground)
                .padding(Spacing.s16)
                .background(Theme.feltAccent,
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })

            if due.count > sessionCap {
                Text(LocalizedText(zh: "为保持节奏，单次复习最多 \(sessionCap) 道；剩余的稍后继续。",
                                   en: "Sessions cap at \(sessionCap); the rest will wait.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var dueCards: [ReviewCard] {
        due.prefix(sessionCap).map { ReviewCard.make(from: $0, scenarios: deps.scenarios) }
    }

    private var intervalsText: String {
        deps.content.srs.intervalsDays.map(String.init).joined(separator: " / ")
    }

    // MARK: - 列表

    private func section(_ title: LocalizedText, rows: [MistakeReviewItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text("\(title.localized) · \(rows.count)")
                .font(Typo.headline)
                .foregroundStyle(Theme.textPrimary)
            ForEach(rows) { row($0) }
        }
    }

    private func row(_ item: MistakeReviewItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(spacing: Spacing.s8) {
                Text(ReviewFormat.trainerLabel(item.trainer))
                    .font(Typo.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.feltAccent)
                stageDots(item)
                Spacer()
                Text(statusText(item))
                    .font(Typo.caption)
                    .foregroundStyle(statusColor(item))
            }
            Text(LocalizedText(
                zh: "正确思路：\(ReviewFormat.answerLabel(trainer: item.trainer, raw: item.correctAnswer))",
                en: "Right idea: \(ReviewFormat.answerLabel(trainer: item.trainer, raw: item.correctAnswer))").localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textPrimary)
            Text(LocalizedText(zh: item.reasonZH, en: item.reasonEN).localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
        }
        .padding(Spacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    /// SRS 阶段点：走过的间隔点亮。
    private func stageDots(_ item: MistakeReviewItem) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<deps.content.srs.intervalsDays.count, id: \.self) { index in
                Circle()
                    .fill(index < item.stage
                          ? (item.masteredAt == nil ? Theme.feltAccent : Theme.goldMoment)
                          : Theme.surfaceElevated)
                    .frame(width: 5, height: 5)
            }
        }
    }

    private func statusText(_ item: MistakeReviewItem) -> String {
        if item.masteredAt != nil {
            return LocalizedText(zh: "已掌握", en: "Mastered").localized
        }
        if item.nextReviewAt <= now {
            return LocalizedText(zh: "到期", en: "Due").localized
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: item.nextReviewAt)).day ?? 0
        return days <= 0
            ? LocalizedText(zh: "今天稍后", en: "Later today").localized
            : LocalizedText(zh: "\(days) 天后", en: "In \(days)d").localized
    }

    private func statusColor(_ item: MistakeReviewItem) -> Color {
        if item.masteredAt != nil { return Theme.goldMoment }
        return item.nextReviewAt <= now ? Theme.danger : Theme.textSecondary
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: Spacing.s12) {
            Image(systemName: "book.closed")
                .font(.system(size: 44))
                .foregroundStyle(Theme.feltAccent)
            Text(LocalizedText(zh: "还没有错题", en: "No mistakes yet").localized)
                .font(Typo.title)
                .foregroundStyle(Theme.textPrimary)
            Text(LocalizedText(zh: "训练里答错的题会自动收进来，按间隔复习直到掌握。",
                               en: "Misses from training land here and resurface on schedule.").localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.s24)
    }
}

#Preview {
    if let content = try? ContentLoader.load() {
        NavigationStack { MistakeBookView() }
            .environment(AppDependencies(content: content))
            .modelContainer(for: [UserProgress.self, DrillRecord.self,
                                  MistakeReviewItem.self, AppSettings.self],
                            inMemory: true)
            .preferredColorScheme(.dark)
    }
}
