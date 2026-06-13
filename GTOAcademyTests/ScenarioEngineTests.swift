import XCTest
@testable import GTOAcademy

/// 测试用确定性 RNG（线性同余）：种子相同 → 出题序列相同。
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

@MainActor
final class ScenarioEngineTests: XCTestCase {
    private func makeEngine() throws -> ScenarioEngine {
        let dependencies = AppDependencies(content: try ContentLoader.load())
        return ScenarioEngine(scenarios: dependencies.scenarios,
                              ranges: dependencies.ranges)
    }

    /// 无尽题答案必须与范围表事实一致（weight > 0.5 ⇔ 加注）。
    func testEndlessSpotRespectsChartTruth() throws {
        let engine = try makeEngine()
        var generator = SeededGenerator(state: 42)
        for index in 0..<50 {
            let spot = try XCTUnwrap(
                engine.endlessRFISpot(index: index, using: &generator))
            let chart = try XCTUnwrap(
                engine.endlessCharts.first { $0.position == spot.position })
            let inRange = chart.weight(of: spot.hand) > 0.5
            XCTAssertEqual(spot.correct == .raise, inRange, spot.id)
            XCTAssertEqual(spot.isInRange, inRange, spot.id)
        }
    }

    /// 50/50 采样必须让「加注 / 弃牌」两类答案都出现，否则无尽模式退化为全 fold。
    func testEndlessProducesBothOutcomes() throws {
        let engine = try makeEngine()
        var generator = SeededGenerator(state: 7)
        var outcomes = Set<PreflopChoice>()
        for index in 0..<100 {
            if let spot = engine.endlessRFISpot(index: index, using: &generator) {
                outcomes.insert(spot.correct)
            }
        }
        XCTAssertEqual(outcomes, [.raise, .fold])
    }

    /// 精编题按（难度, id）稳定升序：先易后难的训练曲线。
    func testCuratedSortedByDifficultyThenID() throws {
        let engine = try makeEngine()

        let preflop = engine.curatedPreflop()
        XCTAssertFalse(preflop.isEmpty)
        for (a, b) in zip(preflop, preflop.dropFirst()) {
            XCTAssertTrue((a.difficulty, a.id) <= (b.difficulty, b.id))
        }

        let postflop = engine.curatedPostflop()
        for (a, b) in zip(postflop, postflop.dropFirst()) {
            XCTAssertTrue((a.difficulty, a.id) <= (b.difficulty, b.id))
        }

        let playerType = engine.curatedPlayerType()
        for (a, b) in zip(playerType, playerType.dropFirst()) {
            XCTAssertTrue((a.difficulty, a.id) <= (b.difficulty, b.id))
        }
    }

    /// 每日抽样：定量、去重、子集、难度升序，且同一天内不同时刻结果稳定。
    func testDailySamplingStableWithinDay() throws {
        let engine = try makeEngine()
        let calendar = Calendar.current
        let morning = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 12, hour: 9)))
        let evening = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 12, hour: 22)))

        let sample = engine.dailyPreflop(on: morning)
        XCTAssertEqual(sample.count, ScenarioEngine.dailySessionSize)
        XCTAssertEqual(Set(sample.map(\.id)).count, sample.count, "抽样内有重复题")
        let poolIDs = Set(engine.curatedPreflop().map(\.id))
        XCTAssertTrue(sample.allSatisfy { poolIDs.contains($0.id) }, "抽样越出题库")
        for (a, b) in zip(sample, sample.dropFirst()) {
            XCTAssertTrue((a.difficulty, a.id) <= (b.difficulty, b.id), "抽样应保持难度升序")
        }
        XCTAssertEqual(sample.map(\.id), engine.dailyPreflop(on: evening).map(\.id),
                       "同一天不同时刻应是同一套题")
    }

    /// 每日抽样跨天轮换；池子不足请求量时全量返回。
    func testDailySamplingRotatesAcrossDays() throws {
        let engine = try makeEngine()
        let calendar = Calendar.current
        let day1 = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 12)))
        let day2 = try XCTUnwrap(calendar.date(
            from: DateComponents(year: 2026, month: 6, day: 13)))
        XCTAssertNotEqual(engine.dailyPostflop(on: day1).map(\.id),
                          engine.dailyPostflop(on: day2).map(\.id),
                          "相邻两天的题面不应完全相同")
        XCTAssertEqual(engine.dailyPlayerType(count: 99, on: day1).count,
                       engine.scenarios.playerType.count, "池子不足时应全量返回")
    }
}
