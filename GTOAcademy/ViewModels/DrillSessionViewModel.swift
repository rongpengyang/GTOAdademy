import Foundation
import Observation

/// 通用训练会话状态机：题目队列 → 揭示（判分由调用方经 DrillScoringEngine 完成）→ 推进。
/// 不持有判分逻辑、不触碰 SwiftData——三个训练器与无尽模式共用，纯逻辑可单测。
@MainActor
@Observable
final class DrillSessionViewModel<Item: Sendable> {
    private(set) var items: [Item]
    private(set) var currentIndex = 0
    private(set) var revealed = false
    private(set) var lastGrade: DrillGrade?
    private(set) var counts: [DrillGrade: Int] = [:]
    private(set) var xpEarned = 0
    private(set) var finished = false

    /// 无尽模式：advance 时由调用方续题，结束由用户主动触发。
    let isEndless: Bool

    nonisolated init(items: [Item], isEndless: Bool = false) {
        self.items = items
        self.isEndless = isEndless
    }

    var currentItem: Item? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    var answeredCount: Int { counts.values.reduce(0, +) }
    var correctCount: Int { counts[.correct, default: 0] }
    var acceptableCount: Int { counts[.acceptable, default: 0] }
    var wrongCount: Int { counts[.wrong, default: 0] }

    var isLastItem: Bool {
        !isEndless && currentIndex == items.count - 1
    }

    /// 揭示当前题的判分结果。已揭示后忽略。
    func reveal(grade: DrillGrade, xp: Int) {
        guard !revealed, currentItem != nil else { return }
        revealed = true
        lastGrade = grade
        counts[grade, default: 0] += 1
        xpEarned += xp
    }

    /// 推进。精编：末题置 finished；无尽：用 next 续题（next 为 nil 时同样结束）。
    func advance(appending next: Item? = nil) {
        guard revealed else { return }
        if isEndless, let next {
            items.append(next)
        }
        if currentIndex + 1 < items.count {
            currentIndex += 1
            revealed = false
            lastGrade = nil
        } else {
            finished = true
        }
    }

    /// 无尽模式主动收束（精编模式也可用于提前退出结算）。
    func finishSession() {
        finished = true
    }
}
