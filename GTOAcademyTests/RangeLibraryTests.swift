import XCTest
@testable import GTOAcademy

/// 6 张范围表的内容契约：组合数、位置单调性、动作语义、无尽模式覆盖。
@MainActor
final class RangeLibraryTests: XCTestCase {
    private var library: ContentLibrary!

    override func setUpWithError() throws {
        library = try ContentLoader.load()
    }

    func testSixChartsLoaded() throws {
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
        XCTAssertEqual(Int(try combos("rfi-hj-100bb").rounded()), 266)
        XCTAssertEqual(Int(try combos("rfi-co-100bb").rounded()), 350)
        XCTAssertEqual(Int(try combos("rfi-sb-100bb").rounded()), 578)
        XCTAssertEqual(Int(try combos("bb-call-vs-btn-100bb").rounded()), 346)
        XCTAssertEqual(Int(try combos("bb-call-vs-utg-100bb").rounded()), 162)
        XCTAssertEqual(Int(try combos("bb-call-vs-co-100bb").rounded()), 266)
        XCTAssertEqual(Int(try combos("bb-call-vs-sb-100bb").rounded()), 424)
        XCTAssertEqual(Int(try combos("bb-3bet-vs-btn-100bb").rounded()), 106)
        XCTAssertEqual(Int(try combos("sb-3bet-vs-btn-100bb").rounded()), 138)
        XCTAssertEqual(Int(try combos("btn-3bet-vs-co-100bb").rounded()), 86)
    }

    /// 位置越靠后开局范围越宽；SB（加注或弃牌策略）宽于 CO。
    func testPositionalWidening() throws {
        let utg = try percent("rfi-utg-100bb")
        let hj = try percent("rfi-hj-100bb")
        let co = try percent("rfi-co-100bb")
        let btn = try percent("rfi-btn-100bb")
        let sb = try percent("rfi-sb-100bb")
        XCTAssertLessThan(utg, hj)
        XCTAssertLessThan(hj, co)
        XCTAssertLessThan(co, btn)
        XCTAssertGreaterThan(sb, co)
    }

    func testBBChartIsCallAction() throws {
        let bb = try chart("bb-call-vs-btn-100bb")
        XCTAssertEqual(bb.action, .call)
        XCTAssertEqual(bb.weight(of: try XCTUnwrap(HandClass(notation: "43s"))), 1)
        XCTAssertEqual(bb.weight(of: try XCTUnwrap(HandClass(notation: "AKs"))), 0)
    }

    /// 范围扩充后，无尽 RFI 自动覆盖五个开局位置（BB 跟注表被 action 过滤排除）。
    func testEndlessChartsCoverFivePositions() throws {
        let deps = AppDependencies(content: library)
        let engine = ScenarioEngine(scenarios: deps.scenarios, ranges: deps.ranges)
        XCTAssertEqual(engine.endlessCharts.map(\.position),
                       [.utg, .hj, .co, .btn, .sb])
    }

    // MARK: - Helpers

    private func chart(_ id: String) throws -> RangeChart {
        try XCTUnwrap(library.ranges.first { $0.id == id })
    }

    private func combos(_ id: String) throws -> Double {
        try chart(id).totalCombos
    }

    private func percent(_ id: String) throws -> Double {
        try chart(id).percentOfDeck
    }
}
