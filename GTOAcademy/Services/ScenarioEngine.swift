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

    // MARK: - 每日精编抽样（M9）

    /// 每日精编会话题量。
    static let dailySessionSize = 12

    /// 同一天结果稳定（中断重进、当日复盘是同一套题），跨天自动轮换；
    /// 采样后保持难度升序，先易后难的训练曲线不变。池子不足时全量返回。
    func dailyPreflop(count: Int = ScenarioEngine.dailySessionSize,
                      on date: Date = .now) -> [PreflopScenario] {
        dailySample(curatedPreflop(), count: count, on: date)
    }

    func dailyPostflop(count: Int = ScenarioEngine.dailySessionSize,
                       on date: Date = .now) -> [PostflopScenario] {
        dailySample(curatedPostflop(), count: count, on: date)
    }

    func dailyPlayerType(count: Int = ScenarioEngine.dailySessionSize,
                         on date: Date = .now) -> [PlayerTypeScenario] {
        dailySample(curatedPlayerType(), count: count, on: date)
    }

    private func dailySample<T>(_ pool: [T], count: Int, on date: Date) -> [T] {
        guard pool.count > count else { return pool }
        var generator = DailySeededGenerator(seed: Self.daySeed(on: date))
        var indices = Array(pool.indices)
        for slot in 0..<count {
            let pick = Int.random(in: slot..<indices.count, using: &generator)
            indices.swapAt(slot, pick)
        }
        return indices.prefix(count).sorted().map { pool[$0] }
    }

    /// 设备日历的年月日 → 种子，再过两轮 splitmix64 打散，
    /// 避免相邻日期的线性种子导致首轮采样雷同。
    static func daySeed(on date: Date) -> UInt64 {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var z = UInt64(max(0, c.year ?? 0)) &* 372
            &+ UInt64(max(0, c.month ?? 0)) &* 31
            &+ UInt64(max(0, c.day ?? 0))
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
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

/// 每日抽样用确定性 RNG（线性同余，与测试侧 SeededGenerator 同参）。
/// 种子相同 → 序列相同：同日稳定、跨天轮换、可单测。
struct DailySeededGenerator: RandomNumberGenerator, Sendable {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
