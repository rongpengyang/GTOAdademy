import Foundation

/// 169 格抽象起手牌（如 AKs / AKo / TT）。
/// 与 HoleCards（两张具体牌）严格区分：范围、Matrix、combo counting 用 HandClass；
/// 发牌与牌力评估用具体牌。
struct HandClass: Hashable, Sendable {
    enum Kind: String, Codable, Sendable, Hashable {
        case pair, suited, offsuit
    }

    let high: Rank
    let low: Rank
    let kind: Kind

    init?(high: Rank, low: Rank, kind: Kind) {
        switch kind {
        case .pair:
            guard high == low else { return nil }
        case .suited, .offsuit:
            guard high > low else { return nil }
        }
        self.high = high
        self.low = low
        self.kind = kind
    }

    static func pair(_ rank: Rank) -> HandClass {
        HandClass(high: rank, low: rank, kind: .pair)!
    }

    /// 解析 "AKs" / "T9o" / "QQ"；大小写不敏感，自动归一高低牌顺序。
    init?(notation: String) {
        let chars = Array(notation)
        guard chars.count == 2 || chars.count == 3,
              let a = Rank(letter: chars[0]),
              let b = Rank(letter: chars[1]) else { return nil }

        if chars.count == 2 {
            guard a == b else { return nil }
            self.init(high: a, low: b, kind: .pair)
        } else {
            let kind: Kind
            switch chars[2] {
            case "s", "S": kind = .suited
            case "o", "O": kind = .offsuit
            default: return nil
            }
            guard a != b else { return nil }
            self.init(high: max(a, b), low: min(a, b), kind: kind)
        }
    }

    var notation: String {
        switch kind {
        case .pair: high.letter + high.letter
        case .suited: high.letter + low.letter + "s"
        case .offsuit: high.letter + low.letter + "o"
        }
    }

    /// 组合数：对子 6、同花 4、不同花 12（combo counting 课程直接复用）。
    var comboCount: Int {
        switch kind {
        case .pair: 6
        case .suited: 4
        case .offsuit: 12
        }
    }

    /// 全部 169 格，按 Matrix 习惯排序（行=高牌降序，列=低牌降序）。
    static let all169: [HandClass] = {
        let ranks = Rank.allCases.sorted(by: >)
        var result: [HandClass] = []
        for hi in ranks {
            for lo in ranks where lo <= hi {
                if hi == lo {
                    result.append(.pair(hi))
                } else {
                    result.append(HandClass(high: hi, low: lo, kind: .suited)!)
                    result.append(HandClass(high: hi, low: lo, kind: .offsuit)!)
                }
            }
        }
        return result
    }()
}

extension HandClass: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let value = HandClass(notation: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid hand class: \(raw)"))
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(notation)
    }
}

extension HandClass: CustomStringConvertible {
    var description: String { notation }
}
