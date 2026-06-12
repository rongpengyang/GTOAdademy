import XCTest
@testable import GTOAcademy

/// 判分引擎：三档判分（翻前 / 翻后 / 类型）+ XP 表。真值取自真实内容。
final class DrillScoringEngineTests: XCTestCase {
    private var library: ContentLibrary!

    override func setUpWithError() throws {
        library = try ContentLoader.load()
    }

    func testPreflopThreeTiers() throws {
        let scenario = try XCTUnwrap(
            library.preflop.first { $0.id == "pf-bbdef-aqs-vs-btn" })
        XCTAssertEqual(DrillScoringEngine.grade(.threeBet, for: scenario), .correct)
        XCTAssertEqual(DrillScoringEngine.grade(.call, for: scenario), .acceptable)
        XCTAssertEqual(DrillScoringEngine.grade(.fold, for: scenario), .wrong)
    }

    func testPostflopGradesByKey() throws {
        let scenario = try XCTUnwrap(
            library.postflop.first { $0.id == "po-flop-cbet-btn-ak" })
        XCTAssertEqual(
            DrillScoringEngine.grade(try XCTUnwrap(PostflopChoice(key: "bet33")), for: scenario),
            .correct)
        XCTAssertEqual(
            DrillScoringEngine.grade(try XCTUnwrap(PostflopChoice(key: "bet50")), for: scenario),
            .acceptable)
        XCTAssertEqual(
            DrillScoringEngine.grade(try XCTUnwrap(PostflopChoice(key: "check")), for: scenario),
            .wrong)
        XCTAssertEqual(
            DrillScoringEngine.grade(try XCTUnwrap(PostflopChoice(key: "bet100")), for: scenario),
            .wrong)
    }

    func testPlayerTypeBinary() throws {
        let scenario = try XCTUnwrap(
            library.playerType.first { $0.correct == .maniac })
        XCTAssertEqual(DrillScoringEngine.grade(.maniac, for: scenario), .correct)
        XCTAssertEqual(DrillScoringEngine.grade(.nit, for: scenario), .wrong)
    }

    func testXPTable() throws {
        let rules = library.levels.xp
        XCTAssertEqual(DrillScoringEngine.xp(for: .correct, mode: .curated, rules: rules),
                       rules.curatedCorrect)
        XCTAssertEqual(DrillScoringEngine.xp(for: .correct, mode: .endless, rules: rules),
                       rules.endlessCorrect)
        XCTAssertEqual(DrillScoringEngine.xp(for: .acceptable, mode: .curated, rules: rules),
                       rules.acceptable)
        XCTAssertEqual(DrillScoringEngine.xp(for: .acceptable, mode: .endless, rules: rules),
                       rules.acceptable)
        XCTAssertEqual(DrillScoringEngine.xp(for: .wrong, mode: .curated, rules: rules), 0)
        XCTAssertEqual(DrillScoringEngine.xp(for: .wrong, mode: .endless, rules: rules), 0)
        // 数值契约（levels.json）：精编 5 / 无尽 2 / 可接受 2。
        XCTAssertEqual(rules.curatedCorrect, 5)
        XCTAssertEqual(rules.endlessCorrect, 2)
        XCTAssertEqual(rules.acceptable, 2)
    }
}
