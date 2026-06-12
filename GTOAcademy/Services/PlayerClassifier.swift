import Foundation

/// 分类结论。
enum Classification: Sendable, Equatable {
    /// 样本不足（附所需最小手数）。
    case insufficientSample(minimum: Int)
    /// 命中某型；borderline 表示有统计值贴近规则边界，置信度应降档。
    case classified(PlayerType, borderline: Bool)
    /// 所有规则均未命中（中间地带，不强行贴标签）。
    case unclassified
}

/// 有序规则表分类器：极端型在前，先命中先得。
/// 全部阈值来自 classifier.json——产品可调参，代码零硬编码。
struct PlayerClassifier: Sendable {
    let config: ClassifierConfig

    func classify(_ stats: PlayerStats) -> Classification {
        guard stats.hands >= config.sampleMin else {
            return .insufficientSample(minimum: config.sampleMin)
        }
        for rule in config.rules where matches(rule, stats: stats) {
            return .classified(rule.type, borderline: isBorderline(rule, stats: stats))
        }
        return .unclassified
    }

    private func matches(_ rule: ClassifierRule, stats: PlayerStats) -> Bool {
        if let bound = rule.vpip, !bound.matches(stats.vpip) { return false }
        if let bound = rule.pfr, !bound.matches(stats.pfr) { return false }
        if let bound = rule.af, !bound.matches(stats.af) { return false }
        if let bound = rule.foldToCbet, !bound.matches(stats.foldToCbet) { return false }
        return true
    }

    /// 任一「百分比尺度」统计值（VPIP / PFR / Fold-to-Cbet）距其任一边界
    /// 不足 borderlineMargin 个百分点即视为 borderline。
    /// AF 是 0–5 量级的比值，不适用百分点 margin，故不参与判定。
    private func isBorderline(_ rule: ClassifierRule, stats: PlayerStats) -> Bool {
        let percentScale: [(StatBound?, Double?)] = [
            (rule.vpip, stats.vpip),
            (rule.pfr, stats.pfr),
            (rule.foldToCbet, stats.foldToCbet),
        ]
        for (bound, value) in percentScale {
            guard let bound, let value else { continue }
            let edges = [bound.gt, bound.gte, bound.lt, bound.lte].compactMap { $0 }
            if edges.contains(where: { abs(value - $0) < config.borderlineMargin }) {
                return true
            }
        }
        return false
    }
}
