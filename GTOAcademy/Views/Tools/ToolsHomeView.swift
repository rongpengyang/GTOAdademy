import SwiftUI

/// 工具页导航值。playerType 可携带数据计算器算出的初始统计（直通分类器）。
enum ToolsRoute: Hashable {
    case rangeMatrix
    case statCalculator
    case playerType(initial: PlayerStats?)
}

/// Tools 首页：范围矩阵 / 数据计算器 / 玩家类型判断 三个入口。
struct ToolsHomeView: View {
    @Environment(AppDependencies.self) private var deps

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.s12) {
                    NavigationLink(value: ToolsRoute.rangeMatrix) {
                        toolRow(
                            icon: "square.grid.3x3.fill",
                            title: LocalizedText(zh: "范围矩阵", en: "Range Matrix"),
                            subtitle: LocalizedText(
                                zh: "13×13 起手牌格 · \(deps.ranges.all.count) 张范围表",
                                en: "13×13 grid · \(deps.ranges.all.count) charts"))
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: ToolsRoute.statCalculator) {
                        toolRow(
                            icon: "percent",
                            title: LocalizedText(zh: "数据计算器", en: "Stat Calculator"),
                            subtitle: LocalizedText(zh: "原始计数 → VPIP / PFR / AF",
                                                    en: "Raw counts → VPIP / PFR / AF"))
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: ToolsRoute.playerType(initial: nil)) {
                        toolRow(
                            icon: "person.text.rectangle",
                            title: LocalizedText(zh: "玩家类型判断", en: "Player Type Tool"),
                            subtitle: LocalizedText(zh: "数据画像 → 六类型实时判定",
                                                    en: "Stats → live six-type read"))
                    }
                    .buttonStyle(.plain)

                    Text(LocalizedText(
                        zh: "范围与判定均为训练近似，帮助建立直觉，而非逐局精确解。",
                        en: "Ranges and reads are training approximations to build intuition, not per-hand solutions.").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.s8)
                }
                .padding(Spacing.s16)
            }
        }
        .navigationTitle(L10n.tabTools)
        .navigationDestination(for: ToolsRoute.self) { route in
            switch route {
            case .rangeMatrix:
                RangeMatrixView(charts: deps.ranges.all)
            case .statCalculator:
                StatCalculatorView()
            case .playerType(let initial):
                PlayerTypeToolView(viewModel: PlayerTypeToolViewModel(
                    config: deps.content.classifier, initial: initial))
            }
        }
    }

    private func toolRow(icon: String,
                         title: LocalizedText,
                         subtitle: LocalizedText) -> some View {
        HStack(spacing: Spacing.s12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.feltAccent)
                .frame(width: 40, height: 40)
                .background(Theme.feltAccent.opacity(0.14), in: Circle())

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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

#Preview {
    if let content = try? ContentLoader.load() {
        NavigationStack { ToolsHomeView() }
            .environment(AppDependencies(content: content))
            .preferredColorScheme(.dark)
    }
}
