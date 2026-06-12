import Foundation

/// 无尽模式生成的 RFI 题。正确答案由范围表事实自动判定，可无限出题。
struct EndlessRFISpot: Sendable, Hashable, Identifiable {
    let id: String
    let position: Position
    let hand: HandClass
    /// .raise（在范围内）或 .fold（在范围外）。
    let correct: PreflopChoice
    /// 该位置开局范围占比（反馈文案用）。
    let rangePercent: Double

    var isInRange: Bool { correct == .raise }
}

/// 出题引擎：精编题排序 + 无尽 RFI 生成。
struct ScenarioEngine: Sendable {
    let scenarios: ScenarioRepository
    let ranges: RangeRepository

    // MARK: - 精编（难度升序，同难度按 id 稳定排序：先易后难的训练曲线）

    func curatedPreflop() -> [PreflopScenario] {
        scenarios.preflop.sorted { ($0.difficulty, $0.id) < ($1.difficulty, $1.id) }
    }

    func curatedPostflop() -> [PostflopScenario] {
        scenarios.postflop.sorted { ($0.difficulty, $0.id) < ($1.difficulty, $1.id) }
    }

    func curatedPlayerType() -> [PlayerTypeScenario] {
        scenarios.playerType.sorted { ($0.difficulty, $0.id) < ($1.difficulty, $1.id) }
    }

    // MARK: - 无尽 RFI

    /// 可用作无尽出题的开局范围表（当前 UTG 与 BTN，随内容扩充自动增位）。
    var endlessCharts: [RangeChart] {
        ranges.all
            .filter { $0.action == .raise }
            .sorted { $0.position.preflopOrder < $1.position.preflopOrder }
    }

    /// 生成一道无尽 RFI 题。
    /// 先以 50% 概率决定取「范围内 / 范围外」的牌，避免纯随机下答案几乎总是 fold。
    /// RNG 由调用方注入：种子相同则序列相同，可单测。
    func endlessRFISpot<G: RandomNumberGenerator>(
        index: Int,
        using generator: inout G
    ) -> EndlessRFISpot? {
        guard let chart = endlessCharts.randomElement(using: &generator) else { return nil }
        let pickInRange = Bool.random(using: &generator)
        let pool = HandClass.all169.filter {
            pickInRange ? chart.weight(of: $0) > 0.5 : chart.weight(of: $0) <= 0.5
        }
        guard let hand = pool.randomElement(using: &generator) else { return nil }
        return EndlessRFISpot(
            id: "endless-\(chart.position.rawValue)-\(hand.notation)-\(index)",
            position: chart.position,
            hand: hand,
            correct: pickInRange ? .raise : .fold,
            rangePercent: chart.percentOfDeck)
    }
}
