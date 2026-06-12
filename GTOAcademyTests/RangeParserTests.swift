import XCTest
@testable import GTOAcademy

final class RangeParserTests: XCTestCase {
    private func combos(_ hands: [HandClass: Double]) -> Int {
        hands.keys.reduce(0) { $0 + $1.comboCount }
    }

    func testAllPairs() throws {
        let result = try RangeParser.parse("22+")
        XCTAssertEqual(result.count, 13)
        XCTAssertEqual(combos(result), 78)
        XCTAssertEqual(result[HandClass(notation: "AA")!], 1.0)
        XCTAssertEqual(result[HandClass(notation: "22")!], 1.0)
    }

    func testPairSpanOrderAgnostic() throws {
        let a = try RangeParser.parse("99-66")
        let b = try RangeParser.parse("66-99")
        XCTAssertEqual(Set(a.keys), Set(b.keys))
        XCTAssertEqual(a.count, 4)
        XCTAssertEqual(combos(a), 24)
        XCTAssertNil(a[HandClass(notation: "TT")!])
        XCTAssertNil(a[HandClass(notation: "55")!])
    }

    func testSuitedPlus() throws {
        let result = try RangeParser.parse("ATs+")
        XCTAssertEqual(result.count, 4) // ATs AJs AQs AKs
        XCTAssertEqual(combos(result), 16)
        XCTAssertNotNil(result[HandClass(notation: "AKs")!])
        XCTAssertNil(result[HandClass(notation: "A9s")!])
    }

    func testSuitedSpan() throws {
        let result = try RangeParser.parse("KTs-K7s")
        XCTAssertEqual(result.count, 4) // K7s K8s K9s KTs
        XCTAssertEqual(combos(result), 16)
        XCTAssertNotNil(result[HandClass(notation: "K8s")!])
        XCTAssertNil(result[HandClass(notation: "KJs")!])
        XCTAssertNil(result[HandClass(notation: "K6s")!])
    }

    func testOffsuitPlus() throws {
        let result = try RangeParser.parse("AQo+")
        XCTAssertEqual(result.count, 2) // AQo AKo
        XCTAssertEqual(combos(result), 24)
    }

    func testWeightSuffixAndPlainMix() throws {
        let result = try RangeParser.parse("A5s:0.5, KQo")
        XCTAssertEqual(result[HandClass(notation: "A5s")!] ?? 0, 0.5, accuracy: 0.0001)
        XCTAssertEqual(result[HandClass(notation: "KQo")!] ?? 0, 1.0, accuracy: 0.0001)
    }

    func testDuplicateTokenLastWins() throws {
        let result = try RangeParser.parse("A5s, A5s:0.25")
        XCTAssertEqual(result[HandClass(notation: "A5s")!] ?? 0, 0.25, accuracy: 0.0001)
    }

    func testInvalidTokensThrow() {
        XCTAssertThrowsError(try RangeParser.parse("ZZ"))
        XCTAssertThrowsError(try RangeParser.parse("AKx"))
        XCTAssertThrowsError(try RangeParser.parse("QQs"))
        XCTAssertThrowsError(try RangeParser.parse("ATs-KTs")) // 不同高牌的区间
        XCTAssertThrowsError(try RangeParser.parse("A5s:1.5")) // 频率越界
        XCTAssertThrowsError(try RangeParser.parse("A5s:0"))   // 频率为零
    }

    func testUTGNotationComboTotal() throws {
        let result = try RangeParser.parse(
            "22+, ATs+, A5s-A4s, KTs+, QTs+, JTs, T9s, 98s, AJo+, KQo")
        XCTAssertEqual(combos(result), 182)
    }

    func testBTNNotationComboTotal() throws {
        let result = try RangeParser.parse(
            "22+, A2s+, K2s+, Q5s+, J7s+, T7s+, 97s+, 86s+, 75s+, 65s, 64s, 54s, A2o+, K9o+, Q9o+, J9o+, T8o+, 98o")
        XCTAssertEqual(combos(result), 550)
    }
}
