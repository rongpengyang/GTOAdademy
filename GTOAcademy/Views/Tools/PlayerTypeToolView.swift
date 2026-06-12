import SwiftUI

/// 玩家类型判断：滑杆描述对手数据 → PlayerClassifier 实时给出画像与应对思路。
struct PlayerTypeToolView: View {
    @State private var viewModel: PlayerTypeToolViewModel

    init(viewModel: PlayerTypeToolViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.s16) {
                    resultCard
                    slidersCard
                    optionalCard
                }
                .padding(Spacing.s16)
            }
        }
        .navigationTitle(LocalizedText(zh: "玩家类型判断", en: "Player Type").localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.vpip) { viewModel.clampPFR() }
        .onChange(of: viewModel.pfr) { viewModel.clampPFR() }
    }

    // MARK: - 判定结果

    @ViewBuilder
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            switch viewModel.classification {
            case .insufficientSample(let minimum):
                header(icon: "hourglass",
                       title: LocalizedText(zh: "样本不足", en: "Not enough hands"))
                Text(LocalizedText(
                    zh: "统计画像至少需要 \(minimum) 手（当前 \(Int(viewModel.hands)) 手）。小样本下先按未知对手打稳。",
                    en: "A statistical read needs at least \(minimum) hands (now \(Int(viewModel.hands))). Until then, play a solid default.").localized)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textPrimary)

            case .classified(let type, let borderline):
                HStack(spacing: Spacing.s8) {
                    Text(type.title.localized)
                        .font(Typo.title)
                        .foregroundStyle(Theme.feltAccent)
                    if borderline {
                        Text(LocalizedText(zh: "贴近边界", en: "Borderline").localized)
                            .font(Typo.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkBackground)
                            .padding(.horizontal, Spacing.s8)
                            .padding(.vertical, Spacing.s4)
                            .background(Theme.goldMoment, in: Capsule())
                    }
                    Spacer()
                }
                Text(blurb(for: type).localized)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textPrimary)
                if borderline {
                    Text(LocalizedText(zh: "有统计值贴近分类边界——降低置信度，多看几手再下结论。",
                                       en: "A stat sits near the boundary—treat this read with lower confidence.").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

            case .unclassified:
                header(icon: "questionmark.circle",
                       title: LocalizedText(zh: "未匹配典型画像", en: "No clean match"))
                Text(LocalizedText(
                    zh: "数据落在常见画像之间。别硬贴标签——按对手的具体行动逐步修正判断。",
                    en: "These stats sit between common profiles. Don't force a label—update on specific actions.").localized)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .animation(Motion.standard, value: viewModel.classification)
    }

    private func header(icon: String, title: LocalizedText) -> some View {
        HStack(spacing: Spacing.s8) {
            Image(systemName: icon)
                .foregroundStyle(Theme.textSecondary)
            Text(title.localized)
                .font(Typo.headline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    // MARK: - 输入

    private var slidersCard: some View {
        VStack(spacing: Spacing.s16) {
            sliderRow(label: "VPIP",
                      value: $viewModel.vpip, range: 0...100, step: 0.5,
                      display: String(format: "%.1f%%", viewModel.vpip))
            sliderRow(label: "PFR",
                      value: $viewModel.pfr, range: 0...100, step: 0.5,
                      display: String(format: "%.1f%%", viewModel.pfr))
            sliderRow(label: LocalizedText(zh: "样本手数", en: "Sample size").localized,
                      value: $viewModel.hands, range: 0...1000, step: 10,
                      display: "\(Int(viewModel.hands))")
        }
        .padding(Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var optionalCard: some View {
        VStack(spacing: Spacing.s16) {
            Toggle(isOn: $viewModel.includeAF) {
                toggleLabel(
                    title: LocalizedText(zh: "提供 AF（激进因子）", en: "Provide AF (aggression)"),
                    hint: LocalizedText(zh: "区分疯鱼与跟注站等被动型",
                                        en: "Separates maniacs from passive types"))
            }
            .tint(Theme.feltAccent)

            if viewModel.includeAF {
                sliderRow(label: "AF",
                          value: $viewModel.af, range: 0...10, step: 0.1,
                          display: String(format: "%.1f", viewModel.af))
            }

            Toggle(isOn: $viewModel.includeFoldToCbet) {
                toggleLabel(
                    title: LocalizedText(zh: "提供 Fold to C-Bet", en: "Provide fold-to-c-bet"),
                    hint: LocalizedText(zh: "辅助识别跟注站", en: "Helps spot calling stations"))
            }
            .tint(Theme.feltAccent)

            if viewModel.includeFoldToCbet {
                sliderRow(label: "Fold to C-Bet",
                          value: $viewModel.foldToCbet, range: 0...100, step: 1,
                          display: String(format: "%.0f%%", viewModel.foldToCbet))
            }
        }
        .padding(Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .animation(Motion.quick, value: viewModel.includeAF)
        .animation(Motion.quick, value: viewModel.includeFoldToCbet)
    }

    private func sliderRow(label: String,
                           value: Binding<Double>,
                           range: ClosedRange<Double>,
                           step: Double,
                           display: String) -> some View {
        VStack(spacing: Spacing.s8) {
            HStack {
                Text(label)
                    .font(Typo.body)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(display)
                    .font(Typo.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.feltAccent)
            }
            Slider(value: value, in: range, step: step)
                .tint(Theme.feltAccent)
        }
    }

    private func toggleLabel(title: LocalizedText, hint: LocalizedText) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textPrimary)
            Text(hint.localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - 六型应对思路（教学近似）

    private func blurb(for type: PlayerType) -> LocalizedText {
        switch type {
        case .nit:
            LocalizedText(
                zh: "范围很紧、很少加注。他的主动进攻通常代表真实强牌——尊重大注，多偷他的盲注。",
                en: "Very tight, rarely raises. Aggression usually means real strength—respect big bets and steal those blinds.")
        case .tag:
            LocalizedText(
                zh: "紧凶：入池少但进攻坚决，是教科书式的扎实风格。对抗时减少边缘对抗，争取位置。",
                en: "Tight-aggressive: selective but assertive—the textbook solid style. Avoid marginal spots; fight for position.")
        case .lag:
            LocalizedText(
                zh: "松凶：范围宽且持续施压。多用强牌让他付出代价，少被边缘牌逼弃。",
                en: "Loose-aggressive: wide and relentless. Let strong hands pay them off; don't get bullied off marginal holdings.")
        case .maniac:
            LocalizedText(
                zh: "极度激进：下注频率远超合理范围。用中强牌跟住，让方差替你工作。",
                en: "Hyper-aggressive: bets far beyond a balanced range. Call down lighter with solid hands and let variance work for you.")
        case .callingStation:
            LocalizedText(
                zh: "跟注站：很少弃牌也很少加注。多用价值下注，几乎不要诈唬。",
                en: "Calling station: folds little, raises little. Value bet relentlessly and almost never bluff.")
        case .passiveFish:
            LocalizedText(
                zh: "松弱被动：入池过宽、缺乏主动。持续价值下注宽范围，他的加注往往是强牌。",
                en: "Loose-passive: plays too many hands with little initiative. Value bet wide; their raises usually mean it.")
        }
    }
}

#Preview {
    if let content = try? ContentLoader.load() {
        NavigationStack {
            PlayerTypeToolView(viewModel: PlayerTypeToolViewModel(config: content.classifier))
        }
        .preferredColorScheme(.dark)
    }
}
