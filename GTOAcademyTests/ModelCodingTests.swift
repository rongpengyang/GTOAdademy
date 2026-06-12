import XCTest
@testable import GTOAcademy

final class ModelCodingTests: XCTestCase {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func testCardRoundTrip() throws {
        let card = try decoder.decode(Card.self, from: Data("\"As\"".utf8))
        XCTAssertEqual(card.rank, .ace)
        XCTAssertEqual(card.suit, .spades)
        let encoded = try encoder.encode(card)
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "\"As\"")
    }

    func testInvalidCardFails() {
        XCTAssertThrowsError(try decoder.decode(Card.self, from: Data("\"Ax\"".utf8)))
        XCTAssertThrowsError(try decoder.decode(Card.self, from: Data("\"1s\"".utf8)))
        XCTAssertThrowsError(try decoder.decode(Card.self, from: Data("\"Asd\"".utf8)))
    }

    func testHandClassNotation() throws {
        XCTAssertEqual(HandClass(notation: "AKs")?.comboCount, 4)
        XCTAssertEqual(HandClass(notation: "TT")?.comboCount, 6)
        XCTAssertEqual(HandClass(notation: "T9o")?.comboCount, 12)
        // 大小写与高低牌顺序自动归一
        XCTAssertEqual(HandClass(notation: "kqS")?.notation, "KQs")
        XCTAssertEqual(HandClass(notation: "9To")?.notation, "T9o")
        XCTAssertNil(HandClass(notation: "AKx"))
        XCTAssertNil(HandClass(notation: "AAs"))
        XCTAssertNil(HandClass(notation: "A"))
    }

    func testAll169Integrity() {
        XCTAssertEqual(HandClass.all169.count, 169)
        XCTAssertEqual(Set(HandClass.all169).count, 169)
        let totalCombos = HandClass.all169.reduce(0) { $0 + $1.comboCount }
        XCTAssertEqual(totalCombos, 1326)
    }

    func testHoleCardsNormalizationAndClass() throws {
        let holeCards = try decoder.decode(HoleCards.self, from: Data("\"KhAh\"".utf8))
        XCTAssertEqual(holeCards.first.rank, .ace, "高牌应归一在前")
        XCTAssertEqual(holeCards.handClass.notation, "AKs")

        let offsuit = try decoder.decode(HoleCards.self, from: Data("\"7c2d\"".utf8))
        XCTAssertEqual(offsuit.handClass.notation, "72o")

        let pair = try decoder.decode(HoleCards.self, from: Data("\"8h8s\"".utf8))
        XCTAssertEqual(pair.handClass.notation, "88")

        XCTAssertThrowsError(
            try decoder.decode(HoleCards.self, from: Data("\"AhAh\"".utf8)),
            "重复牌应解码失败")
    }

    func testActionWeightArrayCoding() throws {
        let weights = try decoder.decode(
            [ActionWeight].self,
            from: Data("[[\"raise\", 0.5], [\"call\", 0.5]]".utf8))
        XCTAssertEqual(weights.count, 2)
        XCTAssertEqual(weights[0].action, .raise)
        XCTAssertEqual(weights[0].weight, 0.5, accuracy: 0.0001)
        XCTAssertEqual(weights[1].action, .call)
    }

    func testPostflopChoiceKey() {
        XCTAssertEqual(PostflopChoice(action: .bet, sizePct: 33).key, "bet33")
        XCTAssertEqual(PostflopChoice(action: .check, sizePct: nil).key, "check")
        XCTAssertEqual(PostflopChoice(action: .raise, sizePct: 100).key, "raise100")
    }

    func testBoardValidation() {
        let flop = [Card(code: "Kd")!, Card(code: "7s")!, Card(code: "2c")!]
        XCTAssertNotNil(Board(cards: flop))
        XCTAssertNil(Board(cards: Array(flop.prefix(2))), "两张公共牌非法")
        XCTAssertNil(Board(cards: [flop[0], flop[0], flop[2]]), "重复公共牌非法")
        XCTAssertEqual(Board(cards: flop)?.street, .flop)
    }
}
