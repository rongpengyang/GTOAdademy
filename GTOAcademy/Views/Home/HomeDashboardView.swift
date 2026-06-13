import SwiftUI

/// M1 占位版主页：展示内容库加载结果，证明数据管线打通。
/// M5 阶段替换为完整仪表盘（今日训练 / 连续天数 / 推荐下一课 / 复习角标）。
struct HomeDashboardView: View {
    @Environment(AppDependencies.self) private var deps

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                header
                statRow
                milestoneCard
            }
            .padding(Spacing.s16)
            .readableWidth()
        }
        .background(Theme.inkBackground)
        .navigationTitle(L10n.tabHome)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("GTO Academy")
                .font(Typo.largeTitle)
                .foregroundStyle(Theme.textPrimary)
            Text(LocalizedText(zh: "内容版本", en: "Content version").localized
                 + " · " + deps.content.manifest.contentVersion)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var statRow: some View {
        HStack(spacing: Spacing.s12) {
            StatTile(value: deps.lessons.totalLessonCount,
                     label: LocalizedText(zh: "课程", en: "Lessons"))
            StatTile(value: deps.scenarios.totalCount,
                     label: LocalizedText(zh: "精编题", en: "Drills"))
            StatTile(value: deps.ranges.all.count,
                     label: LocalizedText(zh: "范围表", en: "Ranges"))
        }
    }

    private var milestoneCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Label {
                Text(LocalizedText(zh: "M1 骨架已就绪", en: "M1 skeleton ready").localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.feltAccent)
            }
            Text(LocalizedText(
                zh: "模型、内容管线与工程骨架已打通。课程系统（M2）与训练器（M3）将逐步替换各 Tab 占位页。",
                en: "Models, the content pipeline and the project skeleton are wired up. Lessons (M2) and trainers (M3) will replace the placeholder tabs.")
                .localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

private struct StatTile: View {
    let value: Int
    let label: LocalizedText

    var body: some View {
        VStack(spacing: Spacing.s4) {
            Text("\(value)")
                .font(Typo.statValue)
                .monospacedDigit()
                .foregroundStyle(Theme.feltAccent)
            Text(label.localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview {
    let library = try! ContentLoader.load()
    return NavigationStack { HomeDashboardView() }
        .environment(AppDependencies(content: library))
}
