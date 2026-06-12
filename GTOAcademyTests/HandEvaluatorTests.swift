import XCTest
@testable import GTOAcademy

/// 7 张评牌器：九大牌型 + wheel + 取最优五张 + Comparable。
final class HandEvaluatorTests: XCTestCase {
    /// 由紧凑编码构造一手牌并评牌（5–7 张）。
    private func rank(_ codes: String...) -> HandRank {
        let cards = codes.map { Card(code: $0)! }
        return HandEvaluator.evaluate(PokerHand(cards: cards)!)
    }

    func testHighCard() {
        let result = rank("As", "Kd", "9h", "7c", "5s")
        XCTAssertEqual(result.category, .highCard)
        XCTAssertEqual(result.tiebreakers, [.ace, .king, .nine, .seven, .five])
    }

    func testPairWithKickersDescending() {
        let result = rank("As", "Ad", "Kh", "9c", "5s")
        XCTAssertEqual(result.category, .pair)
        XCTAssertEqual(result.tiebreakers, [.ace, .king, .nine, .five])
    }

    func testTwoPairPicksBestTwoOfThree() {
        let result = rank("As", "Ad", "Kh", "Kc", "9s", "9d", "2c")
        XCTAssertEqual(result.category, .twoPair)
        XCTAssertEqual(result.tiebreakers, [.ace, .king, .nine], "三对取最大两对 + 最大踢脚")
    }

    func testTrips() {
        let result = rank("Qs", "Qd", "Qh", "9c", "5s")
        XCTAssertEqual(result.category, .trips)
        XCTAssertEqual(result.tiebreakers, [.queen, .nine, .five])
    }

    func testStraight() {
        let result = rank("9s", "8d", "7h", "6c", "5s")
        XCTAssertEqual(result.category, .straight)
        XCTAssertEqual(result.tiebreakers, [.nine])
    }

    func testWheelCountsFiveHigh() {
        let result = rank("As", "2d", "3h", "4c", "5s", "9d", "Kc")
        XCTAssertEqual(result.category, .straight)
        XCTAssertEqual(result.tiebreakers, [.five], "A-2-3-4-5 的顶张是 5，不是 A")
    }

    func testFlushPicksTopFiveOfSeven() {
        let result = rank("As", "Ks", "9s", "7s", "5s", "3s", "2s")
        XCTAssertEqual(result.category, .flush)
        XCTAssertEqual(result.tiebreakers, [.ace, .king, .nine, .seven, .five])
    }

    func testFullHouseFromDoubleTrips() {
        let result = rank("As", "Ad", "Ah", "Ks", "Kd", "Kh", "2c")
        XCTAssertEqual(result.category, .fullHouse)
        XCTAssertEqual(result.tiebreakers, [.ace, .king], "双三条取大三条 + 大对")
    }

    func testQuads() {
        let result = rank("9s", "9d", "9h", "9c", "As")
        XCTAssertEqual(result.category, .quads)
        XCTAssertEqual(result.tiebreakers, [.nine, .ace])
    }

    func testStraightFlush() {
        let result = rank("9s", "8s", "7s", "6s", "5s", "Ad", "Kd")
        XCTAssertEqual(result.category, .straightFlush)
        XCTAssertEqual(result.tiebreakers, [.nine])
    }

    func testSevenCardsSelectBestCategory() {
        // 同时含三条 A 与皇家同花顺素材，必须选出后者。
        let result = rank("As", "Ks", "Qs", "Js", "Ts", "Ah", "Ad")
        XCTAssertEqual(result.category, .straightFlush)
        XCTAssertEqual(result.tiebreakers, [.ace])
    }

    func testHoleBoardEvaluationAndComparison() {
        let board = Board(cards: ["Kh", "7c", "2s"].map { Card(code: $0)! })!
        let topPair = HandEvaluator.evaluate(hole: HoleCards(code: "AsKd")!, board: board)!
        let overpair = HandEvaluator.evaluate(hole: HoleCards(code: "AcAd")!, board: board)!
        XCTAssertEqual(topPair.category, .pair)
        XCTAssertEqual(overpair.category, .pair)
        XCTAssertLessThan(topPair, overpair, "顶对顶踢 < 超对")
    }
}
