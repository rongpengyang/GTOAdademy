import Foundation

/// 公共牌（0/3/4/5 张）。
struct Board: Hashable, Sendable {
    let cards: [Card]

    init?(cards: [Card]) {
        guard [0, 3, 4, 5].contains(cards.count),
              Set(cards).count == cards.count else { return nil }
        self.cards = cards
    }

    var street: BettingRound {
        switch cards.count {
        case 3: .flop
        case 4: .turn
        case 5: .river
        default: .preflop
        }
    }
}

extension Board: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([Card].self)
        guard let value = Board(cards: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid board: \(raw.map(\.code).joined())"))
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(cards)
    }
}

/// 5–7 张牌的集合，HandEvaluator（M3 阶段实现）的输入。
struct PokerHand: Hashable, Sendable {
    let cards: [Card]

    init?(cards: [Card]) {
        guard (5...7).contains(cards.count),
              Set(cards).count == cards.count else { return nil }
        self.cards = cards
    }
}
