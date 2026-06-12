import Foundation

/// 成手评估：5–7 张牌取最优五张。
/// 实现为穷举 C(7,5)=21 个组合取最大——训练 App 的调用量级下，清晰正确优先于微优化。
enum HandEvaluator {
    /// 评估 PokerHand（已保证 5–7 张且无重复）。
    static func evaluate(_ hand: PokerHand) -> HandRank {
        let cards = hand.cards
        if cards.count == 5 {
            return rank(ofFive: cards)
        }
        var best: HandRank?
        for combo in combinations(of: cards, choose: 5) {
            let candidate = rank(ofFive: combo)
            if best == nil || candidate > best! {
                best = candidate
            }
        }
        return best!
    }

    /// 便捷入口：底牌 + 公共牌。翻前（公共牌不足）返回 nil。
    static func evaluate(hole: HoleCards, board: Board) -> HandRank? {
        guard let hand = PokerHand(cards: [hole.first, hole.second] + board.cards) else {
            return nil
        }
        return evaluate(hand)
    }

    // MARK: - 5 张评牌

    private static func rank(ofFive five: [Card]) -> HandRank {
        let ranksDescending = five.map(\.rank).sorted(by: >)
        let isFlush = Set(five.map(\.suit)).count == 1
        let straightHigh = straightHighRank(ranksDescending)

        // 按点数分组：[(rank, count)]，先按 count 降序，再按 rank 降序。
        var tally: [Rank: Int] = [:]
        for rank in ranksDescending {
            tally[rank, default: 0] += 1
        }
        let groups = tally.sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.key > rhs.key
        }

        if let high = straightHigh, isFlush {
            return HandRank(category: .straightFlush, tiebreakers: [high])
        }
        if groups[0].value == 4 {
            return HandRank(category: .quads,
                            tiebreakers: [groups[0].key, groups[1].key])
        }
        if groups[0].value == 3, groups[1].value == 2 {
            return HandRank(category: .fullHouse,
                            tiebreakers: [groups[0].key, groups[1].key])
        }
        if isFlush {
            return HandRank(category: .flush, tiebreakers: ranksDescending)
        }
        if let high = straightHigh {
            return HandRank(category: .straight, tiebreakers: [high])
        }
        if groups[0].value == 3 {
            return HandRank(category: .trips,
                            tiebreakers: [groups[0].key, groups[1].key, groups[2].key])
        }
        if groups[0].value == 2, groups[1].value == 2 {
            return HandRank(category: .twoPair,
                            tiebreakers: [groups[0].key, groups[1].key, groups[2].key])
        }
        if groups[0].value == 2 {
            return HandRank(category: .pair,
                            tiebreakers: [groups[0].key, groups[1].key,
                                          groups[2].key, groups[3].key])
        }
        return HandRank(category: .highCard, tiebreakers: ranksDescending)
    }

    /// 五张是否构成顺子；返回顶张。wheel（A-5-4-3-2）顶张为 5。
    private static func straightHighRank(_ ranksDescending: [Rank]) -> Rank? {
        let unique = Array(Set(ranksDescending)).sorted(by: >)
        guard unique.count == 5 else { return nil }
        if unique.map(\.rawValue) == [14, 5, 4, 3, 2] {
            return .five
        }
        if unique.first!.rawValue - unique.last!.rawValue == 4 {
            return unique.first
        }
        return nil
    }

    /// 字典序组合枚举（n ≤ 7，k = 5，最多 21 项）。
    private static func combinations(of cards: [Card], choose k: Int) -> [[Card]] {
        guard cards.count > k else { return [cards] }
        var result: [[Card]] = []
        var indices = Array(0..<k)
        while true {
            result.append(indices.map { cards[$0] })
            var pivot = k - 1
            while pivot >= 0, indices[pivot] == cards.count - k + pivot {
                pivot -= 1
            }
            if pivot < 0 { break }
            indices[pivot] += 1
            for next in (pivot + 1)..<k {
                indices[next] = indices[next - 1] + 1
            }
        }
        return result
    }
}

extension HandRank.Category {
    /// UI 牌力标签（翻后训练顶部的「当前牌力」徽章）。
    var title: LocalizedText {
        switch self {
        case .highCard: LocalizedText(zh: "高牌", en: "High card")
        case .pair: LocalizedText(zh: "一对", en: "Pair")
        case .twoPair: LocalizedText(zh: "两对", en: "Two pair")
        case .trips: LocalizedText(zh: "三条", en: "Trips")
        case .straight: LocalizedText(zh: "顺子", en: "Straight")
        case .flush: LocalizedText(zh: "同花", en: "Flush")
        case .fullHouse: LocalizedText(zh: "葫芦", en: "Full house")
        case .quads: LocalizedText(zh: "四条", en: "Quads")
        case .straightFlush: LocalizedText(zh: "同花顺", en: "Straight flush")
        }
    }
}
