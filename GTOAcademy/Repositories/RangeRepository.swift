import Foundation

/// 范围图表查询仓库（只读，Sendable）。
struct RangeRepository: Sendable {
    let all: [RangeChart]
    private let byID: [String: RangeChart]

    init(charts: [RangeChart]) {
        self.all = charts
        self.byID = Dictionary(charts.map { ($0.id, $0) }) { first, _ in first }
    }

    func chart(id: String) -> RangeChart? { byID[id] }

    func charts(position: Position) -> [RangeChart] {
        all.filter { $0.position == position }
    }

    func chart(position: Position, action: RangeAction) -> RangeChart? {
        all.first { $0.position == position && $0.action == action }
    }
}
