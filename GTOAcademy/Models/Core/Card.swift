import Foundation

/// 花色。原始值即 JSON 紧凑编码("As" 的 "s")。
enum Suit: String, CaseIterable, Codable, Sendable, Hashable {
    case spades = "s", hearts = "h", diamonds = "d", clubs = "c"

    var symbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        }
    }
}

/// 牌面大小，rawValue 为可比较的点数（A 恒为 14；A 作 1 的 wheel 顺子由 HandEvaluator 处理）。
enum Rank: Int, CaseIterable, Codable, Sendable, Hashable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    var letter: String {
        switch self {
        case .ten: "T"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        case .ace: "A"
        default: String(rawValue)
        }
    }

    init?(letter: Character) {
        switch letter.uppercased() {
        case "2": self = .two
        case "3": self = .three
        case "4": self = .four
        case "5": self = .five
        case "6": self = .six
        case "7": self = .seven
        case "8": self = .eight
        case "9": self = .nine
        case "T": self = .ten
        case "J": self = .jack
        case "Q": self = .queen
        case "K": self = .king
        case "A": self = .ace
        default: return nil
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// 一张具体的牌。JSON 编码为两字符紧凑串，如 "As"、"Td"。
struct Card: Hashable, Sendable, CustomStringConvertible {
    let rank: Rank
    let suit: Suit

    init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    init?(code: String) {
        let chars = Array(code)
        guard chars.count == 2,
              let rank = Rank(letter: chars[0]),
              let suit = Suit(rawValue: String(chars[1]).lowercased()) else { return nil }
        self.init(rank: rank, suit: suit)
    }

    var code: String { rank.letter + suit.rawValue }
    var description: String { code }
    /// 用于 VoiceOver 等场景的可读名称。
    var displayName: String { rank.letter + suit.symbol }
}

extension Card: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let card = Card(code: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid card code: \(raw)"))
        }
        self = card
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}
