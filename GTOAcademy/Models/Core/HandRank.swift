import Foundation

/// 牌力评估结果：类别 + 按位比较的决胜牌。HandEvaluator 在 M3 阶段产出该类型。
struct HandRank: Hashable, Sendable, Comparable {
    enum Category: Int, Comparable, Codable, Sendable, CaseIterable {
        case highCard = 1, pair, twoPair, trips, straight
        case flush, fullHouse, quads, straightFlush

        static func < (lhs: Category, rhs: Category) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let category: Category
    /// 同类别时逐位比较（例：两对为 [高对, 低对, 踢脚]）。
    let tiebreakers: [Rank]

    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        if lhs.category != rhs.category {
            return lhs.category < rhs.category
        }
        for (l, r) in zip(lhs.tiebreakers, rhs.tiebreakers) where l != r {
            return l < r
        }
        return false
    }
}
