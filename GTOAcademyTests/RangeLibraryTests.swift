import XCTest
@testable import GTOAcademy

/// 12 张范围表的内容契约：组合数、位置单调性、动作语义、无尽模式覆盖。
/// 范式说明：不写 setUpWithError——其 override 继承父类的 nonisolated 隔离，
/// 无法对 @MainActor 类的存储属性赋值（Swift 6）。统一在测试体内 loadLibrary()。
@MainActor
final class RangeLibraryTests: XCTestCase {

    func testTwelveChartsLoaded() throws {
        let library = try loadLibrary()
        XCTAssertEqual(library.ranges.count, 12)
        XCTAssertEqual(Set(library.ranges.map(\.id)), [
            "rfi-utg-100bb", "rfi-hj-100bb", "rfi-co-100bb",
            "rfi-btn-100bb", "rfi-sb-100bb",
            "bb-call-vs-utg-100bb", "bb-call-vs-co-100bb",
            "bb-call-vs-btn-100bb", "bb-call-vs-sb-100bb",
            "bb-3bet-vs-btn-100bb", "sb-3bet-vs-btn-100bb",
            "btn-3bet-vs-co-100bb",
        ])
    }

    /// 组合数与校验器固化的窗口一致（内容回归即测试红）。
    func testNewChartComboCounts() throws {
        let library = try loadLibrary()
        XCTAssertEqual(Int(try combos("rfi-hj-100bb", in: library).rounded()), 266)
        XCTAssertEqual(Int(try combos("rfi-co-100bb", in: library).rounded()), 350)
        XCTAssertEqual(Int(try combos("rfi-sb-100bb", in: library).rounded()), 578)
        XCTAssertEqual(Int(try combos("bb-call-vs-btn-100bb", in: library).rounded()), 346)
        XCTAssertEqual(Int(try combos("bb-call-vs-utg-100bb", in: library).rounded()), 162)
        XCTAssertEqual(Int(try combos("bb-call-vs-co-100bb", in: library).rounded()), 266)
        XCTAssertEqual(Int(try combos("bb-call-vs-sb-100bb", in: library).rounded()), 424)
        XCTAssertEqual(Int(try combos("bb-3bet-vs-btn-100bb", in: library).rounded()), 106)
        XCTAssertEqual(Int(try combos("sb-3bet-vs-btn-100bb", in: library).rounded()), 138)
        XCTAssertEqual(Int(try combos("btn-3bet-vs-co-100bb", in: library).rounded()), 86)
    }

    /// 位置越靠后开局范围越宽；SB（加注或弃牌策略）宽于 CO。
    func testPositionalWidening() throws {
        let library = try loadLibrary()
        let utg = try percent("rfi-utg-100bb", in: library)
        let hj = try percent("rfi-hj-100bb", in: library)
        let co = try percent("rfi-co-100bb", in: library)
        let btn = try percent("rfi-btn-100bb", in: library)
        let sb = try percent("rfi-sb-100bb", in: library)
        XCTAssertLessThan(utg, hj)
        XCTAssertLessThan(hj, co)
        XCTAssertLessThan(co, btn)
        XCTAssertGreaterThan(sb, co)
    }

    func testBBChartIsCallAction() throws {
        let library = try loadLibrary()
        let bb = try chart("bb-call-vs-btn-100bb", in: library)
        XCTAssertEqual(bb.action, .call)
        XCTAssertEqual(bb.weight(of: try XCTUnwrap(HandClass(notation: "43s"))), 1)
        XCTAssertEqual(bb.weight(of: try XCTUnwrap(HandClass(notation: "AKs"))), 0)
    }

    /// 范围扩充后，无尽 RFI 自动覆盖五个开局位置（跟注 / 3-Bet 表被 action 过滤排除）。
    func testEndlessChartsCoverFivePositions() throws {
        let library = try loadLibrary()
        let deps = AppDependencies(content: library)
        let engine = ScenarioEngine(scenarios: deps.scenarios, ranges: deps.ranges)
        XCTAssertEqual(engine.endlessCharts.map(\.position),
                       [.utg, .hj, .co, .btn, .sb])
    }

    // MARK: - Helpers

    private func loadLibrary() throws -> ContentLibrary {
        try ContentLoader.load()
    }

    private func chart(_ id: String, in library: ContentLibrary) throws -> RangeChart {
        try XCTUnwrap(library.ranges.first { $0.id == id })
    }

    private func combos(_ id: String, in library: ContentLibrary) throws -> Double {
        try chart(id, in: library).totalCombos
    }

    private func percent(_ id: String, in library: ContentLibrary) throws -> Double {
        try chart(id, in: library).percentOfDeck
    }
}
