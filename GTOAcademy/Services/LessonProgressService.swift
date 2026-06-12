import Foundation
import SwiftData

/// M2 最小进度写入：课程完成、XP、测验流水。
/// M5 将演进为 ProgressStore（统一写入口 + 等级 / 连续天数 / SRS 调度）。
@MainActor
enum LessonProgressService {
    /// 取（或创建）唯一的 UserProgress 记录。
    static func progress(in context: ModelContext) -> UserProgress {
        if let existing = (try? context.fetch(FetchDescriptor<UserProgress>()))?.first {
            return existing
        }
        let fresh = UserProgress()
        context.insert(fresh)
        return fresh
    }

    static func isCompleted(_ lessonID: String, in context: ModelContext) -> Bool {
        progress(in: context).completedLessonIDs.contains(lessonID)
    }

    /// 标记课程完成。返回本次新获得的 XP；重复完成不重复计。
    @discardableResult
    static func completeLesson(_ lessonID: String,
                               xpRules: XPRules,
                               in context: ModelContext) -> Int {
        let record = progress(in: context)
        guard !record.completedLessonIDs.contains(lessonID) else { return 0 }
        record.completedLessonIDs.append(lessonID)
        record.xp += xpRules.lessonComplete
        try? context.save()
        return xpRules.lessonComplete
    }

    /// 记录单题作答流水（Profile 统计与 M5 错题本的数据源）。
    static func recordQuizAnswer(questionID: String,
                                 correct: Bool,
                                 in context: ModelContext) {
        context.insert(DrillRecord(
            scenarioID: questionID,
            trainer: "quiz",
            grade: correct ? "correct" : "wrong",
            xpEarned: 0))
    }
}
