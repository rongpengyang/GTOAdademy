import Foundation
import Observation

/// VPIP / PFR / AF 计算器：由原始计数推导百分比与激进因子。
/// 不触碰 SwiftData；`stats` 快照可直接交给玩家类型判断工具。
@MainActor
@Observable
final class StatCalculatorViewModel {
    /// 观察到的总手数。
    var hands = 0
    /// 主动入池次数（VPIP 计数）。
    var vpipCount = 0
    /// 翻前加注次数（PFR 计数）。
    var pfrCount = 0
    /// 下注 + 加注次数（AF 分子）。
    var betsAndRaises = 0
    /// 跟注次数（AF 分母）。
    var calls = 0

    init() {}

    var vpipPercent: Double? {
        guard hands > 0 else { return nil }
        return Double(vpipCount) / Double(hands) * 100
    }

    var pfrPercent: Double? {
        guard hands > 0 else { return nil }
        return Double(pfrCount) / Double(hands) * 100
    }

    /// AF = (下注 + 加注) ÷ 跟注。跟注为 0 时无定义。
    var af: Double? {
        guard calls > 0 else { return nil }
        return Double(betsAndRaises) / Double(calls)
    }

    /// 有进攻动作却零跟注 → AF 趋于无穷（UI 显示 ∞）。
    var afIsInfinite: Bool { calls == 0 && betsAndRaises > 0 }

    /// 录入自洽性：翻前加注必然已入池，入池不可能超过总手数。
    var hasOrderingIssue: Bool { pfrCount > vpipCount || vpipCount > hands }

    /// 可交给 PlayerClassifier 的统计快照（需要正的手数）。
    var stats: PlayerStats? {
        guard let vpip = vpipPercent, let pfr = pfrPercent else { return nil }
        return PlayerStats(vpip: vpip, pfr: pfr, af: af, foldToCbet: nil, hands: hands)
    }
}
