import SwiftUI

/// 13×13 范围矩阵：选表 → 对角线波次入场 → 逐格点查组合数与频率。
struct RangeMatrixView: View {
    let charts: [RangeChart]

    @State private var selectedChartID: String?
    /// 与 selectedChartID 一致时矩阵可见；切表先清空再延迟回填，触发波次动画。
    @State private var revealedChartID: String?
    @State private var selectedHand: HandClass?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// RFI 按位置顺序在前，防守表在后。
    private var orderedCharts: [RangeChart] {
        charts.sorted {
            ($0.action == .raise ? 0 : 1, $0.position.preflopOrder, $0.id)
                < ($1.action == .raise ? 0 : 1, $1.position.preflopOrder, $1.id)
        }
    }

    private var selectedChart: RangeChart? {
        orderedCharts.first { $0.id == selectedChartID } ?? orderedCharts.first
    }

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s16) {
                    chartPicker
                    if let chart = selectedChart {
                        matrix(for: chart)
                        legend
                        infoCard(for: chart)
                    }
                }
                .padding(Spacing.s16)
            }
        }
        .navigationTitle(LocalizedText(zh: "范围矩阵", en: "Range Matrix").localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedChartID == nil { selectedChartID = orderedCharts.first?.id }
            reveal()
        }
        .onChange(of: selectedChartID) {
            selectedHand = nil
            reveal()
        }
    }

    /// 对角线波次入场：先隐藏全部格，停一拍后整体回填，
    /// 每格按 (row + col) 递增延迟出现。系统减弱动态时立即呈现。
    private func reveal() {
        guard let id = selectedChart?.id else { return }
        guard !reduceMotion else {
            revealedChartID = id
            return
        }
        revealedChartID = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            if selectedChart?.id == id {
                revealedChartID = id
            }
        }
    }

    // MARK: - 选表

    private var chartPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s8) {
                ForEach(orderedCharts) { chart in
                    chip(for: chart)
                }
            }
        }
    }

    private func chip(for chart: RangeChart) -> some View {
        let isSelected = chart.id == selectedChart?.id
        return Button {
            guard !isSelected else { return }
            Haptics.tap()
            selectedChartID = chart.id
        } label: {
            Text(chipTitle(for: chart))
                .font(Typo.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Theme.inkBackground : Theme.textPrimary)
                .padding(.horizontal, Spacing.s12)
                .padding(.vertical, Spacing.s8)
                .background(isSelected ? Theme.feltAccent : Theme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func chipTitle(for chart: RangeChart) -> String {
        chart.action == .raise
            ? "\(chart.position.displayName) RFI"
            : "\(chart.position.displayName) " + LocalizedText(zh: "防守", en: "Defend").localized
    }

    // MARK: - 矩阵

    private func matrix(for chart: RangeChart) -> some View {
        let visible = revealedChartID == chart.id
        return VStack(spacing: 2) {
            ForEach(0..<13, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<13, id: \.self) { col in
                        cell(HandMatrix.grid[row][col], chart: chart,
                             row: row, col: col, visible: visible)
                    }
                }
            }
        }
        .padding(Spacing.s8)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func cell(_ hand: HandClass, chart: RangeChart,
                      row: Int, col: Int, visible: Bool) -> some View {
        let weight = chart.weight(of: hand)
        let isSelected = selectedHand == hand
        return Button {
            Haptics.tap()
            selectedHand = isSelected ? nil : hand
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(fillColor(weight: weight))
                Text(hand.notation)
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(textColor(weight: weight))
                    .padding(1)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(isSelected ? Theme.goldMoment : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.55)
        .animation(
            visible
                ? Motion.entrance(reduceMotion: reduceMotion)
                    .delay(reduceMotion ? 0 : Double(row + col) * 0.018)
                : nil,
            value: visible)
    }

    private func fillColor(weight: Double) -> Color {
        if weight >= 0.999 { return Theme.feltAccent }
        if weight > 0 { return Theme.feltAccent.opacity(0.45) }
        return Theme.surfaceElevated
    }

    private func textColor(weight: Double) -> Color {
        if weight >= 0.999 { return Theme.inkBackground }
        if weight > 0 { return Theme.textPrimary }
        return Theme.textSecondary
    }

    // MARK: - 图例与信息卡

    private var legend: some View {
        HStack(spacing: Spacing.s16) {
            legendItem(color: Theme.feltAccent,
                       label: LocalizedText(zh: "范围内", en: "In range"))
            legendItem(color: Theme.feltAccent.opacity(0.45),
                       label: LocalizedText(zh: "混合频率", en: "Mixed"))
            legendItem(color: Theme.surfaceElevated,
                       label: LocalizedText(zh: "范围外", en: "Out"))
            Spacer()
        }
    }

    private func legendItem(color: Color, label: LocalizedText) -> some View {
        HStack(spacing: Spacing.s4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label.localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private func infoCard(for chart: RangeChart) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            if let hand = selectedHand {
                let weight = chart.weight(of: hand)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                    Text(hand.notation)
                        .font(Typo.statValue)
                        .foregroundStyle(weight > 0 ? Theme.feltAccent : Theme.textSecondary)
                    VStack(alignment: .leading, spacing: Spacing.s4) {
                        Text(LocalizedText(zh: "\(hand.comboCount) 个组合",
                                           en: "\(hand.comboCount) combos").localized)
                            .font(Typo.body)
                            .foregroundStyle(Theme.textPrimary)
                        Text(weightLine(weight: weight, action: chart.action))
                            .font(Typo.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
            } else {
                Text(chart.name.localized)
                    .font(Typo.headline)
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: Spacing.s24) {
                    statPair(value: String(format: "%.0f", chart.totalCombos),
                             label: LocalizedText(zh: "组合数", en: "Combos"))
                    statPair(value: String(format: "%.1f%%", chart.percentOfDeck),
                             label: LocalizedText(zh: "占全部起手", en: "Of all hands"))
                    Spacer()
                }
                Text(LocalizedText(zh: "点击任意格查看组合数与频率。",
                                   en: "Tap any cell for combos and frequency.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .animation(Motion.quick, value: selectedHand)
    }

    private func statPair(value: String, label: LocalizedText) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Typo.statValue)
                .foregroundStyle(Theme.feltAccent)
            Text(label.localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func weightLine(weight: Double, action: RangeAction) -> String {
        let verb = action == .call
            ? LocalizedText(zh: "跟注", en: "call")
            : LocalizedText(zh: "加注", en: "raise")
        if weight <= 0 {
            return LocalizedText(zh: "范围外 · \(verb.zh)频率 0%",
                                 en: "Out of range · \(verb.en) 0% of the time").localized
        }
        let percent = Int((weight * 100).rounded())
        return LocalizedText(zh: "\(verb.zh)频率 \(percent)%",
                             en: "\(verb.en.capitalized) \(percent)% of the time").localized
    }
}

#Preview {
    if let content = try? ContentLoader.load() {
        NavigationStack { RangeMatrixView(charts: content.ranges) }
            .preferredColorScheme(.dark)
    }
}
