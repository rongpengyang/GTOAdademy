import Foundation

/// 范围记法解析错误。携带原始 token 便于内容排错。
enum RangeParseError: Error, Equatable, CustomStringConvertible {
    case invalidToken(String)
    case invalidRange(String)
    case invalidWeight(String)

    var description: String {
        switch self {
        case .invalidToken(let token): "Invalid range token: \(token)"
        case .invalidRange(let token): "Invalid range span: \(token)"
        case .invalidWeight(let token): "Invalid weight in token: \(token)"
        }
    }
}

/// 把人类范围记法解析为 HandClass → 频率 字典。
///
/// 语法（逗号分隔，空白容忍）：
/// - 单项：`AA`、`AKs`、`T9o`
/// - 对子向上：`77+` → 77…AA
/// - 对子区间：`99-66`（两端包含，顺序无关）
/// - 同高牌向上：`ATs+` → ATs AJs AQs AKs（低牌升至高牌-1）
/// - 同高牌区间：`KTs-K7s`（两端包含，需同高牌、同 kind）
/// - 频率后缀：`A5s:0.5`（0 < w ≤ 1）
/// - 重复 token：后者覆盖前者（last wins）
enum RangeParser {
    static func parse(_ notation: String) throws -> [HandClass: Double] {
        var result: [HandClass: Double] = [:]
        let tokens = notation
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for raw in tokens {
            var token = raw
            var weight = 1.0
            if let colon = token.firstIndex(of: ":") {
                let suffix = String(token[token.index(after: colon)...])
                    .trimmingCharacters(in: .whitespaces)
                guard let value = Double(suffix), value > 0, value <= 1 else {
                    throw RangeParseError.invalidWeight(raw)
                }
                weight = value
                token = String(token[..<colon]).trimmingCharacters(in: .whitespaces)
            }
            for hand in try expand(token: token, original: raw) {
                result[hand] = weight
            }
        }
        return result
    }

    // MARK: - Expansion

    private static func expand(token: String, original: String) throws -> [HandClass] {
        if token.contains("-") {
            let parts = token.split(separator: "-").map(String.init)
            guard parts.count == 2 else { throw RangeParseError.invalidToken(original) }
            return try expandSpan(from: parts[0], to: parts[1], original: original)
        }
        if token.hasSuffix("+") {
            return try expandPlus(base: String(token.dropLast()), original: original)
        }
        guard let single = HandClass(notation: token) else {
            throw RangeParseError.invalidToken(original)
        }
        return [single]
    }

    /// "77+" / "ATs+" / "T8o+"
    private static func expandPlus(base: String, original: String) throws -> [HandClass] {
        guard let baseHand = HandClass(notation: base) else {
            throw RangeParseError.invalidToken(original)
        }
        switch baseHand.kind {
        case .pair:
            return Rank.allCases
                .filter { $0 >= baseHand.high }
                .map { HandClass.pair($0) }
        case .suited, .offsuit:
            return Rank.allCases
                .filter { $0 >= baseHand.low && $0 < baseHand.high }
                .map { HandClass(high: baseHand.high, low: $0, kind: baseHand.kind)! }
        }
    }

    /// "99-66" / "KTs-K7s"（两端包含，顺序无关）
    private static func expandSpan(from a: String, to b: String, original: String) throws -> [HandClass] {
        guard let handA = HandClass(notation: a), let handB = HandClass(notation: b) else {
            throw RangeParseError.invalidToken(original)
        }

        if handA.kind == .pair, handB.kind == .pair {
            let upper = max(handA.high, handB.high)
            let lower = min(handA.high, handB.high)
            return Rank.allCases
                .filter { $0 >= lower && $0 <= upper }
                .map { HandClass.pair($0) }
        }

        guard handA.kind == handB.kind, handA.high == handB.high else {
            throw RangeParseError.invalidRange(original)
        }
        let upperLow = max(handA.low, handB.low)
        let lowerLow = min(handA.low, handB.low)
        return Rank.allCases
            .filter { $0 >= lowerLow && $0 <= upperLow }
            .map { HandClass(high: handA.high, low: $0, kind: handA.kind)! }
    }
}
