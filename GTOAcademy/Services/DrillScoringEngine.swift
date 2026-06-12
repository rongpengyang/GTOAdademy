import Foundation

/// 判分等级。rawValue 与 DrillRecord.grade 持久化字段一致。
enum DrillGrade: String, Sendable, Hashable, CaseIterable {
    case correct, acceptable, wrong

    var title: LocalizedText {
        switch self {
        case .correct: LocalizedText(zh: "正确", en: "Correct")
        case .acceptable: LocalizedText(zh: "可接受", en: "Acceptable")
        case .wrong: LocalizedText(zh: "错误", en: "Wrong")
        }
    }
}

/// 训练模式（影响 XP 档位）。
enum DrillMode: Sendable, Hashable {
    case curated
    case endless
}

/// 统一判分与 XP 规则。XP 数值全部来自 levels.json。
enum DrillScoringEngine {
    static func grade(_ choice: PreflopChoice, for scenario: PreflopScenario) -> DrillGrade {
        if choice == scenario.correct { return .correct }
        if scenario.acceptable.contains(choice) { return .acceptable }
        return .wrong
    }

    /// PostflopChoice 以 key（如 "bet33"）对齐，避免 sizePct 可选性带来的相等性歧义。
    static func grade(_ choice: PostflopChoice, for scenario: PostflopScenario) -> DrillGrade {
        if choice.key == scenario.correct.key { return .correct }
        if scenario.acceptable.contains(where: { $0.key == choice.key }) { return .acceptable }
        return .wrong
    }

    static func grade(_ choice: PlayerType, for scenario: PlayerTypeScenario) -> DrillGrade {
        choice == scenario.correct ? .correct : .wrong
    }

    static func xp(for grade: DrillGrade, mode: DrillMode, rules: XPRules) -> Int {
        switch grade {
        case .correct: mode == .curated ? rules.curatedCorrect : rules.endlessCorrect
        case .acceptable: rules.acceptable
        case .wrong: 0
        }
    }
}
