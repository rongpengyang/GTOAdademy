import Foundation

/// 范围图表里的动作。
enum RangeAction: String, Codable, Sendable, Hashable, CaseIterable {
    case raise, call, fold, limp
    case threeBet = "3bet"
}

/// 动作 + 频率。JSON 紧凑编码为二元数组：["raise", 1.0]。
struct ActionWeight: Hashable, Sendable {
    let action: RangeAction
    let weight: Double
}

extension ActionWeight: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        action = try container.decode(RangeAction.self)
        weight = try container.decode(Double.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(action)
        try container.encode(weight)
    }
}

/// 单格显式定义（混合频率时使用）。
struct RangeCell: Codable, Hashable, Sendable {
    let hand: HandClass
    let actions: [ActionWeight]

    private enum CodingKeys: String, CodingKey {
        case hand = "h"
        case actions = "a"
    }
}

/// 范围文件的磁盘结构。notation（人类记法）与 cells（显式格）二选一或共存，
/// cells 覆盖 notation 同名格。
struct RangeChartFile: Codable, Sendable, Hashable {
    let schemaVersion: Int
    let id: String
    let name: LocalizedText
    let position: Position
    let stack: Int
    let action: RangeAction
    let source: String
    let notation: String?
    let cells: [RangeCell]?
}

/// 加载后的范围图表（内存表示）。
struct RangeChart: Sendable, Hashable, Identifiable {
    let id: String
    let name: LocalizedText
    let position: Position
    let stackBB: Int
    let action: RangeAction
    let source: String
    let cells: [HandClass: [ActionWeight]]

    func weight(of hand: HandClass) -> Double {
        cells[hand]?.first(where: { $0.action == action })?.weight ?? 0
    }

    var totalCombos: Double {
        cells.reduce(0) { partial, entry in
            let w = entry.value.first(where: { $0.action == action })?.weight ?? 0
            return partial + Double(entry.key.comboCount) * w
        }
    }

    /// 占全部 1326 个起手组合的百分比。
    var percentOfDeck: Double {
        totalCombos / 1326 * 100
    }
}
