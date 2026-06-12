import Foundation

/// 下注轮次。
enum BettingRound: String, Codable, Sendable, CaseIterable, Hashable {
    case preflop, flop, turn, river
}

/// 基础动作。
enum PlayerAction: String, Codable, Sendable, Hashable, CaseIterable {
    case fold, check, call, bet, raise
}

/// 场景中"前面发生了什么"（翻前）。
struct FacingAction: Codable, Hashable, Sendable {
    let position: Position
    let action: PlayerAction
    let sizeBB: Double?
}

/// 翻前训练的可选答案。
enum PreflopChoice: String, Codable, CaseIterable, Sendable, Hashable {
    case fold, call, raise
    case threeBet = "3bet"

    var title: LocalizedText {
        switch self {
        case .fold: LocalizedText(zh: "弃牌", en: "Fold")
        case .call: LocalizedText(zh: "跟注", en: "Call")
        case .raise: LocalizedText(zh: "加注", en: "Raise")
        case .threeBet: LocalizedText(zh: "3-Bet", en: "3-Bet")
        }
    }
}

/// 翻后训练的可选答案：动作 + 可选尺寸（占底池百分比）。
struct PostflopChoice: Codable, Hashable, Sendable {
    let action: PlayerAction
    let sizePct: Int?

    /// 错误选项字典的键格式："check"、"bet33"、"raise100"。
    var key: String {
        if let sizePct { action.rawValue + String(sizePct) } else { action.rawValue }
    }
}

extension PostflopChoice {
    /// 从键还原（"check"、"bet33"、"raise100"）。与 `key` 互逆。
    init?(key: String) {
        let actionPart = key.prefix(while: \.isLetter)
        guard !actionPart.isEmpty,
              let action = PlayerAction(rawValue: String(actionPart)) else { return nil }
        let digits = key.dropFirst(actionPart.count)
        if digits.isEmpty {
            self.init(action: action, sizePct: nil)
        } else if let size = Int(digits), size > 0 {
            self.init(action: action, sizePct: size)
        } else {
            return nil
        }
    }
}
