import Foundation
import SwiftData

/// 训练答题的进度写入：流水 + XP + 错题快照。M5 并入统一的 ProgressStore。
@MainActor
enum DrillProgressService {
    /// 记录一次作答：写 DrillRecord 流水，XP 计入 UserProgress。
    static func recordAnswer(scenarioID: String,
                             trainer: String,
                             grade: DrillGrade,
                             xp: Int,
                             in context: ModelContext) {
        context.insert(DrillRecord(
            scenarioID: scenarioID,
            trainer: trainer,
            grade: grade.rawValue,
            xpEarned: xp))
        if xp > 0 {
            LessonProgressService.progress(in: context).xp += xp
        }
        try? context.save()
    }

    /// 精编题答错 → 写入错题本（双语解释快照）。同题已存在则重置 SRS 阶段。
    static func logMistake(scenarioID: String,
                           trainer: String,
                           userChoice: String,
                           correctAnswer: String,
                           reason: LocalizedText,
                           lessonRef: String?,
                           srs: SRSConfig,
                           in context: ModelContext) {
        let firstInterval = srs.intervalsDays.first ?? 1
        let nextReview = Calendar.current.date(
            byAdding: .day, value: firstInterval, to: .now) ?? .now

        let descriptor = FetchDescriptor<MistakeReviewItem>(
            predicate: #Predicate { $0.scenarioID == scenarioID })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.stage = 0
            existing.nextReviewAt = nextReview
            existing.userChoice = userChoice
            existing.reasonZH = reason.zh
            existing.reasonEN = reason.en
            existing.masteredAt = nil
        } else {
            context.insert(MistakeReviewItem(
                scenarioID: scenarioID,
                trainer: trainer,
                userChoice: userChoice,
                correctAnswer: correctAnswer,
                reasonZH: reason.zh,
                reasonEN: reason.en,
                lessonRef: lessonRef,
                nextReviewAt: nextReview))
        }
        try? context.save()
    }
}
