import Foundation
import Observation

/// 玩家类型判断工具：滑杆输入 → PlayerClassifier 实时分类。
/// 可由数据计算器带初值进入（PlayerStats 直通）。
@MainActor
@Observable
final class PlayerTypeToolViewModel {
    var vpip: Double
    var pfr: Double
    /// 滑杆驱动，入 stats 前取整。
    var hands: Double
    var includeAF: Bool
    var af: Double
    var includeFoldToCbet: Bool
    var foldToCbet: Double

    private let classifier: PlayerClassifier

    nonisolated init(config: ClassifierConfig, initial: PlayerStats? = nil) {
        classifier = PlayerClassifier(config: config)
        let initialVPIP = initial?.vpip ?? 24
        vpip = initialVPIP
        pfr = min(initial?.pfr ?? 19, initialVPIP)
        hands = Double(initial?.hands ?? 100)
        includeAF = initial?.af != nil
        af = initial?.af ?? 2
        includeFoldToCbet = initial?.foldToCbet != nil
        foldToCbet = initial?.foldToCbet ?? 50
    }

    /// 当前输入对应的统计快照（未启用的可选项以 nil 传出，不参与分类）。
    var stats: PlayerStats {
        PlayerStats(vpip: vpip,
                    pfr: pfr,
                    af: includeAF ? af : nil,
                    foldToCbet: includeFoldToCbet ? foldToCbet : nil,
                    hands: Int(hands))
    }

    var classification: Classification { classifier.classify(stats) }

    /// PFR ≤ VPIP（翻前加注必然已入池）。任一滑杆变动后调用。
    func clampPFR() {
        if pfr > vpip { pfr = vpip }
    }
}
