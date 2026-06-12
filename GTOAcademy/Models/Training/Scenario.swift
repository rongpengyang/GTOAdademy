import Foundation

/// 场景文件通用外壳（Content/scenarios/*.json）。
struct ScenarioFile<T: Codable & Sendable & Hashable>: Codable, Sendable, Hashable {
    let schemaVersion: Int
    let scenarios: [T]
}

enum PreflopScenarioKind: String, Codable, Sendable, Hashable {
    case rfi
    case vsRfi = "vs_rfi"
    case bbDefense = "bb_defense"
}

/// 翻前精编题。
struct PreflopScenario: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let kind: PreflopScenarioKind
    let position: Position
    let facing: [FacingAction]
    let hand: HandClass
    let correct: PreflopChoice
    let acceptable: [PreflopChoice]
    let explanation: LocalizedText
    /// 键为 PreflopChoice.rawValue（"fold" / "call" / "raise" / "3bet"）。
    let wrongChoices: [String: LocalizedText]
    let objective: LocalizedText
    let lessonRef: String?
    let difficulty: Int
    let tags: [String]
}

/// 翻后精编题。
struct PostflopScenario: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let street: BettingRound
    let heroPosition: Position
    let villainPosition: Position
    let heroHand: HoleCards
    let board: [Card]
    let potBB: Double
    let effStackBB: Double
    let villainType: PlayerType?
    /// 行动历史，按行渲染（"翻前：BTN 加注 2.5bb，BB 跟注"）。
    let history: [LocalizedText]
    let correct: PostflopChoice
    let acceptable: [PostflopChoice]
    /// 解释分类法标签：value / bluff / protection / thin_value / check_back /
    /// cbet / donk / probe / delayed_cbet / pot_control。
    let reasonTags: [String]
    let explanation: LocalizedText
    /// 键为 PostflopChoice.key（"check" / "bet33" / "raise100"）。
    let wrongChoices: [String: LocalizedText]
    let objective: LocalizedText
    let lessonRef: String?
    let difficulty: Int
    let tags: [String]
}

/// 玩家类型判断题。
struct PlayerTypeScenario: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let stats: PlayerStats
    let correct: PlayerType
    let explanation: LocalizedText
    let objective: LocalizedText
    let lessonRef: String?
    let difficulty: Int
}
