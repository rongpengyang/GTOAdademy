import Foundation

/// 玩家样本数据（计算器输入 / 分类器输入 / 题目素材）。
struct PlayerStats: Codable, Hashable, Sendable {
    let vpip: Double
    let pfr: Double
    let af: Double?
    let foldToCbet: Double?
    let hands: Int
}

/// 玩家类型。rawValue 即 JSON 编码。
enum PlayerType: String, Codable, CaseIterable, Sendable, Hashable {
    case nit, tag, lag, maniac
    case callingStation = "calling_station"
    case passiveFish = "passive_fish"

    var title: LocalizedText {
        switch self {
        case .nit: LocalizedText(zh: "Nit · 过紧", en: "Nit")
        case .tag: LocalizedText(zh: "TAG · 紧凶", en: "TAG")
        case .lag: LocalizedText(zh: "LAG · 松凶", en: "LAG")
        case .maniac: LocalizedText(zh: "Maniac · 狂暴", en: "Maniac")
        case .callingStation: LocalizedText(zh: "跟注站", en: "Calling Station")
        case .passiveFish: LocalizedText(zh: "松弱鱼", en: "Passive Fish")
        }
    }
}
