import SwiftUI

/// 数据计算器：原始计数 → VPIP / PFR / AF，可一键把结果带入玩家类型判断。
struct StatCalculatorView: View {
    @State private var viewModel = StatCalculatorViewModel()
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case hands, vpip, pfr, betsRaises, calls
    }

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.s16) {
                    inputCard
                    resultCard
                    if viewModel.hasOrderingIssue { orderingWarning }
                    handoffLink
                }
                .padding(Spacing.s16)
            }
        }
        .navigationTitle(LocalizedText(zh: "数据计算器", en: "Stat Calculator").localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LocalizedText(zh: "完成", en: "Done").localized) {
                    focusedField = nil
                }
            }
        }
    }

    // MARK: - 输入

    private var inputCard: some View {
        VStack(spacing: Spacing.s12) {
            inputRow(label: LocalizedText(zh: "观察手数", en: "Hands observed"),
                     value: $viewModel.hands, field: .hands)
            inputRow(label: LocalizedText(zh: "主动入池次数（VPIP）",
                                          en: "Voluntary pots entered (VPIP)"),
                     value: $viewModel.vpipCount, field: .vpip)
            inputRow(label: LocalizedText(zh: "翻前加注次数（PFR）",
                                          en: "Preflop raises (PFR)"),
                     value: $viewModel.pfrCount, field: .pfr)
            inputRow(label: LocalizedText(zh: "下注 + 加注次数", en: "Bets + raises"),
                     value: $viewModel.betsAndRaises, field: .betsRaises)
            inputRow(label: LocalizedText(zh: "跟注次数", en: "Calls"),
                     value: $viewModel.calls, field: .calls)
        }
        .padding(Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func inputRow(label: LocalizedText,
                          value: Binding<Int>,
                          field: Field) -> some View {
        HStack(spacing: Spacing.s12) {
            Text(label.localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: field)
                .multilineTextAlignment(.trailing)
                .font(Typo.body.monospacedDigit())
                .foregroundStyle(Theme.feltAccent)
                .frame(width: 88)
                .padding(.vertical, Spacing.s8)
                .padding(.horizontal, Spacing.s12)
                .background(Theme.surfaceElevated,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - 结果

    private var resultCard: some View {
        HStack(spacing: Spacing.s16) {
            resultColumn(title: "VPIP",
                         value: percentText(viewModel.vpipPercent),
                         formula: LocalizedText(zh: "入池 ÷ 手数", en: "entered ÷ hands"))
            divider
            resultColumn(title: "PFR",
                         value: percentText(viewModel.pfrPercent),
                         formula: LocalizedText(zh: "加注 ÷ 手数", en: "raises ÷ hands"))
            divider
            resultColumn(title: "AF",
                         value: afText,
                         formula: LocalizedText(zh: "(注+加) ÷ 跟", en: "(bets+raises) ÷ calls"))
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.surfaceElevated)
            .frame(width: 1, height: 44)
    }

    private func resultColumn(title: String,
                              value: String,
                              formula: LocalizedText) -> some View {
        VStack(spacing: Spacing.s4) {
            Text(title)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(Typo.statValue)
                .foregroundStyle(Theme.feltAccent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(formula.localized)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func percentText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f", value)
    }

    private var afText: String {
        if viewModel.afIsInfinite { return "∞" }
        guard let af = viewModel.af else { return "—" }
        return String(format: "%.2f", af)
    }

    // MARK: - 提醒与直通

    private var orderingWarning: some View {
        HStack(alignment: .top, spacing: Spacing.s8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.danger)
            Text(LocalizedText(zh: "数据自洽提醒：应满足 PFR ≤ VPIP ≤ 手数。",
                               en: "Consistency check: PFR ≤ VPIP ≤ hands.").localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(Spacing.s12)
        .background(Theme.danger.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var handoffLink: some View {
        NavigationLink(value: ToolsRoute.playerType(initial: viewModel.stats)) {
            HStack(spacing: Spacing.s8) {
                Image(systemName: "person.text.rectangle")
                Text(LocalizedText(zh: "用这组数据判断玩家类型",
                                   en: "Read player type with these stats").localized)
                    .font(Typo.headline)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(viewModel.stats == nil ? Theme.textSecondary : Theme.inkBackground)
            .padding(Spacing.s16)
            .background(viewModel.stats == nil ? Theme.surface : Theme.feltAccent,
                        in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.stats == nil)
    }
}

#Preview {
    NavigationStack { StatCalculatorView() }
        .preferredColorScheme(.dark)
}
