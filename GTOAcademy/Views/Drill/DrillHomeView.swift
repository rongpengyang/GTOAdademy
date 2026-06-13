import SwiftUI

/// Drill 入口：三个训练器。翻前提供「精编 / 无尽」双模式。
struct DrillHomeView: View {
    @Environment(AppDependencies.self) private var deps

    private enum Route: Hashable {
        case preflop(DrillMode)
        case postflop
        case playerType
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s16) {
                preflopCard
                NavigationLink(value: Route.postflop) {
                    trainerRow(
                        icon: "slider.horizontal.3",
                        title: LocalizedText(zh: "翻后下注训练", en: "Postflop Sizing"),
                        subtitle: LocalizedText(
                            zh: "每日 \(ScenarioEngine.dailySessionSize) 题 · 题库 \(deps.scenarios.postflop.count) · 尺寸与理由",
                            en: "Daily \(ScenarioEngine.dailySessionSize) · pool of \(deps.scenarios.postflop.count) · sizes and reasons"))
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.playerType) {
                    trainerRow(
                        icon: "person.text.rectangle",
                        title: LocalizedText(zh: "玩家类型判断", en: "Player Typing"),
                        subtitle: LocalizedText(
                            zh: "每日 \(ScenarioEngine.dailySessionSize) 题 · 题库 \(deps.scenarios.playerType.count) · 读数识人",
                            en: "Daily \(ScenarioEngine.dailySessionSize) · pool of \(deps.scenarios.playerType.count) · read the numbers"))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.s16)
            .readableWidth()
        }
        .background(Theme.inkBackground)
        .navigationTitle(L10n.tabDrill)
        .navigationDestination(for: Route.self) { route in
            let engine = ScenarioEngine(scenarios: deps.scenarios, ranges: deps.ranges)
            switch route {
            case .preflop(let mode):
                PreflopTrainerView(mode: mode, engine: engine)
            case .postflop:
                PostflopTrainerView(engine: engine)
            case .playerType:
                PlayerTypeTrainerView(engine: engine)
            }
        }
    }

    private var preflopCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            HStack(spacing: Spacing.s12) {
                iconCircle("arrow.triangle.branch")
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(LocalizedText(zh: "翻前训练", en: "Preflop Trainer").localized)
                        .font(Typo.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(LocalizedText(zh: "开局 · 防守 · 3-Bet",
                                       en: "Opens · defends · 3-bets").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: Spacing.s12) {
                NavigationLink(value: Route.preflop(.curated)) {
                    modePill(
                        title: LocalizedText(zh: "今日精编 \(ScenarioEngine.dailySessionSize) 题",
                                             en: "Daily \(ScenarioEngine.dailySessionSize) curated"),
                        icon: "list.number")
                }
                .buttonStyle(.plain)

                NavigationLink(value: Route.preflop(.endless)) {
                    modePill(
                        title: LocalizedText(zh: "无尽模式", en: "Endless"),
                        icon: "infinity")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func trainerRow(icon: String,
                            title: LocalizedText,
                            subtitle: LocalizedText) -> some View {
        HStack(spacing: Spacing.s12) {
            iconCircle(icon)
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(title.localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle.localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func iconCircle(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Theme.feltAccent)
            .frame(width: 40, height: 40)
            .background(Theme.feltAccent.opacity(0.12), in: Circle())
    }

    private func modePill(title: LocalizedText, icon: String) -> some View {
        Label(title.localized, systemImage: icon)
            .font(Typo.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.feltAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s8)
            .background(Theme.feltAccent.opacity(0.12), in: Capsule())
    }
}

#Preview {
    let library = try! ContentLoader.load()
    return NavigationStack { DrillHomeView() }
        .environment(AppDependencies(content: library))
        .modelContainer(
            for: [UserProgress.self, DrillRecord.self, MistakeReviewItem.self, AppSettings.self],
            inMemory: true)
}
