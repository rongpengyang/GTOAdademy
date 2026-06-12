import XCTest
@testable import GTOAcademy

/// 计算器纯逻辑：百分比、AF 边界、自洽提醒、统计快照。
@MainActor
final class StatCalculatorViewModelTests: XCTestCase {
    func testPercentages() {
        let vm = StatCalculatorViewModel()
        vm.hands = 200
        vm.vpipCount = 50
        vm.pfrCount = 40
        XCTAssertEqual(vm.vpipPercent, 25.0)
        XCTAssertEqual(vm.pfrPercent, 20.0)
    }

    func testAFUndefinedAndInfinite() {
        let vm = StatCalculatorViewModel()
        XCTAssertNil(vm.af)
        XCTAssertFalse(vm.afIsInfinite, "零计数不应显示 ∞")

        vm.betsAndRaises = 5
        XCTAssertNil(vm.af)
        XCTAssertTrue(vm.afIsInfinite)

        vm.calls = 4
        vm.betsAndRaises = 6
        XCTAssertEqual(vm.af, 1.5)
        XCTAssertFalse(vm.afIsInfinite)
    }

    func testStatsNilWithoutHands() {
        let vm = StatCalculatorViewModel()
        vm.vpipCount = 10
        XCTAssertNil(vm.stats)
    }

    func testOrderingIssueFlag() {
        let vm = StatCalculatorViewModel()
        vm.hands = 100
        vm.vpipCount = 20
        vm.pfrCount = 30
        XCTAssertTrue(vm.hasOrderingIssue, "PFR > VPIP 应触发提醒")

        vm.pfrCount = 10
        XCTAssertFalse(vm.hasOrderingIssue)

        vm.vpipCount = 120
        XCTAssertTrue(vm.hasOrderingIssue, "VPIP > 手数应触发提醒")
    }

    func testStatsSnapshot() throws {
        let vm = StatCalculatorViewModel()
        vm.hands = 100
        vm.vpipCount = 48
        vm.pfrCount = 6
        vm.betsAndRaises = 4
        vm.calls = 5
        let stats = try XCTUnwrap(vm.stats)
        XCTAssertEqual(stats.vpip, 48)
        XCTAssertEqual(stats.pfr, 6)
        XCTAssertEqual(stats.af, 0.8)
        XCTAssertNil(stats.foldToCbet)
        XCTAssertEqual(stats.hands, 100)
    }
}
