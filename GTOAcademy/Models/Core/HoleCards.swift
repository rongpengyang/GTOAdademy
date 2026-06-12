import Foundation

/// 两张具体底牌。JSON 编码为四字符紧凑串，如 "AhKh"。
struct HoleCards: Hashable, Sendable {
    let first: Card
    let second: Card

    /// 自动归一：高牌在前（同点数按花色枚举顺序，仅为稳定性）。
    init?(_ a: Card, _ b: Card) {
        guard a != b else { return nil }
        if a.rank > b.rank || (a.rank == b.rank && a.suit.rawValue < b.suit.rawValue) {
            first = a; second = b
        } else {
            first = b; second = a
        }
    }

    init?(code: String) {
        let chars = Array(code)
        guard chars.count == 4,
              let a = Card(code: String(chars[0...1])),
              let b = Card(code: String(chars[2...3])) else { return nil }
        self.init(a, b)
    }

    var code: String { first.code + second.code }

    var handClass: HandClass {
        if first.rank == second.rank {
            return .pair(first.rank)
        }
        let kind: HandClass.Kind = first.suit == second.suit ? .suited : .offsuit
        return HandClass(high: first.rank, low: second.rank, kind: kind)!
    }
}

extension HoleCards: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let value = HoleCards(code: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid hole cards: \(raw)"))
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}
