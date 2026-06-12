import SwiftUI
import SwiftData
import Charts

/// 我的：等级 / 连续训练 / 统计图表 / 错题本入口。
/// 纯只读展示；所有写入都在训练流程中经由 ProgressStore 完成。
struct ProfileView: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.modelContext) private var modelContext

    @Query private var progressRecords: [UserProgress]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var xpBarProgress: Double = 0
    @Query private var mistakes: [MistakeReviewItem]

    @State private var stats: [ProgressStore.TrainerStats] = []
    @State private var daily: [ProgressStore.DailyXP] = []
    @State private var now = Date.now

    /// 展示用快照；从未训练时显示默认值（不在视图里创建记录）。
    private var progress: UserProgress { progressRecords.first ?? UserProgress() }

    /// XP 进度条入场动效：从 0 充到当前进度；「减弱动态」自动降级为淡入。
    private func animateXPBar(to value: Double) {
        withAnimation(Motion.entrance(reduceMotion: reduceMotion)) {
            xpBarProgress = value
        }
    }

    private var dueCount: Int {
        mistakes.filter { $0.masteredAt == nil && $0.nextReviewAt <= now }.count
    }

    private var totalLessons: Int {
        deps.lessons.trackFiles.reduce(0) { $0 + $1.lessons.count }
    }

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    headerCard
                    chartCard
                    statsCard
                    settingsLink
                    mistakeBookLink
                    aboutCard
                }
                .padding(Spacing.s16)
            }
        }
        .navigationTitle(L10n.tabProfile)
        .onAppear { refresh() }
    }

    // MARK: - 等级与连续天数

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            if let info = ProgressStore.levelInfo(forXP: progress.xp,
                                                  track: deps.content.levels) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text("Lv \(info.current.id)")
                        .font(Typo.statValue)
                        .foregroundStyle(Theme.textPrimary)
                    Text(info.current.name.localized)
                        .font(Typo.headline)
                        .foregroundStyle(Theme.feltAccent)
                    Spacer()
                    Text("\(progress.xp) XP")
                        .font(Typo.headline.monospacedDigit())
                        .foregroundStyle(Theme.goldMoment)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceElevated)
                        Capsule().fill(Theme.feltAccent)
                            .frame(width: max(geometry.size.width * xpBarProgress,
                                              xpBarProgress > 0 ? 8 : 0))
                            .onAppear { animateXPBar(to: info.progress) }
                            .onChange(of: info.progress) {
                                animateXPBar(to: info.progress)
                            }
                    }
                }
                .frame(height: 8)

                Text(nextLevelText(info))
                    .font(Typo.caption)
                    .foregroundStyle(info.next == nil ? Theme.goldMoment : Theme.textSecondary)
            }

            HStack(spacing: Spacing.s8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.goldMoment)
                Text(streakText)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func nextLevelText(_ info: ProgressStore.LevelInfo) -> String {
        guard let next = info.next else {
            return LocalizedText(zh: "已达最高等级", en: "Max level reached").localized
        }
        let remaining = max(next.minXP - progress.xp, 0)
        return LocalizedText(zh: "距 \(next.name.localized) 还差 \(remaining) XP",
                             en: "\(remaining) XP to \(next.name.localized)").localized
    }

    private var streakText: String {
        progress.streakDays > 0
            ? LocalizedText(zh: "连续训练 \(progress.streakDays) 天",
                            en: "\(progress.streakDays)-day streak").localized
            : LocalizedText(zh: "今天开始你的连续训练",
                            en: "Start your streak today").localized
    }

    // MARK: - 近 14 天图表

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text(LocalizedText(zh: "近 14 天训练 XP", en: "XP · last 14 days").localized)
                .font(Typo.headline)
                .foregroundStyle(Theme.textPrimary)
            Chart(daily) { entry in
                BarMark(
                    x: .value("日", entry.day, unit: .day),
                    y: .value("XP", entry.xp))
                .foregroundStyle(Theme.feltAccent)
                .cornerRadius(3)
            }
            .chartYScale(domain: 0...max(daily.map(\.xp).max() ?? 0, 10))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 150)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    // MARK: - 训练统计

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack(spacing: Spacing.s12) {
                statTile(value: "\(progress.completedLessonIDs.count)/\(totalLessons)",
                         label: LocalizedText(zh: "课程完成", en: "Lessons"),
                         color: Theme.feltAccent)
                statTile(value: "\(stats.map(\.total).reduce(0, +))",
                         label: LocalizedText(zh: "累计答题", en: "Answers"),
                         color: Theme.textPrimary)
                statTile(value: "\(dueCount)",
                         label: LocalizedText(zh: "待复习", en: "Due"),
                         color: dueCount > 0 ? Theme.danger : Theme.textPrimary)
            }

            if !stats.isEmpty {
                Divider().overlay(Theme.surfaceElevated)
                ForEach(stats) { stat in
                    HStack {
                        Text(ReviewFormat.trainerLabel(stat.trainer))
                            .font(Typo.body)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(accuracyText(stat))
                            .font(Typo.caption.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func statTile(value: String, label: LocalizedText, color: Color) -> some View {
        VStack(spacing: Spacing.s4) {
            Text(value)
                .font(Typo.statValue.monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s8)
        .background(Theme.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func accuracyText(_ stat: ProgressStore.TrainerStats) -> String {
        let percent = Int(((stat.accuracy ?? 0) * 100).rounded())
        return LocalizedText(zh: "\(percent)% 正确 · \(stat.total) 题",
                             en: "\(percent)% · \(stat.total)").localized
    }

    // MARK: - 设置入口

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            HStack(spacing: Spacing.s12) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Theme.feltAccent)
                Text(LocalizedText(zh: "设置", en: "Settings").localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Spacing.s16)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 错题本入口

    private var mistakeBookLink: some View {
        NavigationLink {
            MistakeBookView()
        } label: {
            HStack(spacing: Spacing.s12) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Theme.feltAccent)
                Text(LocalizedText(zh: "错题本", en: "Mistake Book").localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if dueCount > 0 {
                    Text("\(dueCount)")
                        .font(Typo.caption.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.inkBackground)
                        .padding(.horizontal, Spacing.s8)
                        .padding(.vertical, 2)
                        .background(Theme.danger, in: Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Spacing.s16)
            .background(Theme.surface,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 关于

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Texas Holdem Trainer: GTO Academy")
                .font(Typo.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary)
            Text(LocalizedText(zh: "内容版本 \(deps.content.manifest.contentVersion)",
                               en: "Content \(deps.content.manifest.contentVersion)").localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(LocalizedText(zh: "范围与判定均为训练近似，仅用于教学；训练数据仅保存在本机。",
                               en: "Ranges and grading are training approximations for education only; your data stays on this device.").localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s16)
    }

    // MARK: - 数据

    private func refresh() {
        stats = ProgressStore.trainerStats(in: modelContext)
        daily = ProgressStore.dailyXP(days: 14, in: modelContext)
        now = .now
    }
}

#Preview {
    if let content = try? ContentLoader.load() {
        NavigationStack { ProfileView() }
            .environment(AppDependencies(content: content))
            .modelContainer(for: [UserProgress.self, DrillRecord.self,
                                  MistakeReviewItem.self, AppSettings.self],
                            inMemory: true)
            .preferredColorScheme(.dark)
    }
}
