import Foundation

/// 内容清单（Content/manifest.json）。Loader 据此发现全部内容文件。
struct ContentManifest: Codable, Sendable, Hashable {
    struct ScenarioFileNames: Codable, Sendable, Hashable {
        let preflop: String
        let postflop: String
        let playerType: String
    }

    let schemaVersion: Int
    let contentVersion: String
    let lessonFiles: [String]
    let scenarioFiles: ScenarioFileNames
    let rangeFiles: [String]
}

/// 数值边界（分类器规则用）。"optional" 为 true 时：该项数据缺失不阻断匹配。
struct StatBound: Hashable, Sendable {
    let gt: Double?
    let gte: Double?
    let lt: Double?
    let lte: Double?
    let optionalStat: Bool

    func matches(_ value: Double?) -> Bool {
        guard let value else { return optionalStat }
        if let gt, !(value > gt) { return false }
        if let gte, !(value >= gte) { return false }
        if let lt, !(value < lt) { return false }
        if let lte, !(value <= lte) { return false }
        return true
    }
}

extension StatBound: Codable {
    private enum CodingKeys: String, CodingKey {
        case gt, gte, lt, lte
        case optionalStat = "optional"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gt = try c.decodeIfPresent(Double.self, forKey: .gt)
        gte = try c.decodeIfPresent(Double.self, forKey: .gte)
        lt = try c.decodeIfPresent(Double.self, forKey: .lt)
        lte = try c.decodeIfPresent(Double.self, forKey: .lte)
        optionalStat = try c.decodeIfPresent(Bool.self, forKey: .optionalStat) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(gt, forKey: .gt)
        try c.encodeIfPresent(gte, forKey: .gte)
        try c.encodeIfPresent(lt, forKey: .lt)
        try c.encodeIfPresent(lte, forKey: .lte)
        if optionalStat { try c.encode(true, forKey: .optionalStat) }
    }
}

/// 分类规则。数组顺序即判定优先级（极端型在前）。
struct ClassifierRule: Codable, Sendable, Hashable {
    let type: PlayerType
    let vpip: StatBound?
    let pfr: StatBound?
    let af: StatBound?
    let foldToCbet: StatBound?
}

struct ClassifierConfig: Sendable, Hashable {
    let schemaVersion: Int
    let sampleMin: Int
    /// 距任一边界小于该百分点数时降置信。
    let borderlineMargin: Double
    let rules: [ClassifierRule]
}

extension ClassifierConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, sampleMin, borderlineMargin, rules
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        sampleMin = try c.decode(Int.self, forKey: .sampleMin)
        borderlineMargin = try c.decodeIfPresent(Double.self, forKey: .borderlineMargin) ?? 2
        rules = try c.decode([ClassifierRule].self, forKey: .rules)
    }
}

/// XP 数值规则。
struct XPRules: Codable, Sendable, Hashable {
    let lessonComplete: Int
    let curatedCorrect: Int
    let endlessCorrect: Int
    let acceptable: Int
    let reviewPass: Int
    let dailyFirst: Int
}

struct LevelDef: Codable, Sendable, Hashable, Identifiable {
    let id: Int
    let key: String
    let name: LocalizedText
    /// 达到该累计 XP 即进入本级（首级为 0，严格递增）。
    let minXP: Int
}

struct LevelConfig: Codable, Sendable, Hashable {
    let schemaVersion: Int
    let xp: XPRules
    let levels: [LevelDef]
}

/// 间隔复习配置。
struct SRSConfig: Codable, Sendable, Hashable {
    let schemaVersion: Int
    let intervalsDays: [Int]
}

/// 禁用宣传话术词表（ComplianceChecklist 与内容校验测试共用）。
struct BannedPhrases: Codable, Sendable, Hashable {
    let schemaVersion: Int
    let phrases: [String]
}
