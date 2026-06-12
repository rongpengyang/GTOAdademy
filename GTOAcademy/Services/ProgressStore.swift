import Foundation
import SwiftData

/// M5 统一写入口：收编课程 / 训练写入，新增连续训练天数、每日首训奖励、
/// 等级同步与 SRS 复习调度。LessonProgressService / DrillProgressService
/// 保留为内部实现（既有测试不动），视图层一律经由本类型读写。
@MainActor
enum ProgressStore {

    // MARK: - 读取

    static func progress(in context: ModelContext) -> UserProgress {
        LessonProgressService.progress(in: context)
    }

    /// 累计 XP 对应的等级序号（1 起步）。
    static func levelID(forXP xp: Int, track: LevelConfig) -> Int {
        track.levels.last { xp >= $0.minXP }?.id ?? 1
    }

    /// 当前等级、下一等级与去往下一级的进度（满级时 progress = 1）。
    struct LevelInfo {
        let current: LevelDef
        let next: LevelDef?
        let progress: Double
    }

    static func levelInfo(forXP xp: Int, track: LevelConfig) -> LevelInfo? {
        guard !track.levels.isEmpty else { return nil }
        let current = track.levels.last { xp >= $0.minXP } ?? track.levels[0]
        let next = track.levels.first { $0.minXP > current.minXP }
        let progress: Double = if let next {
            Double(xp - current.minXP) / Double(max(next.minXP - current.minXP, 1))
        } else {
            1
        }
        return LevelInfo(current: current, next: next,
                         progress: min(max(progress, 0), 1))
    }

    // MARK: - 每日活跃（连续天数 + 首训奖励）

    /// 记一次当日训练活跃。跨入新的一天时：连续天数 +1（昨日有训）或重置为 1，
    /// 并发放每日首训 XP。同一天重复调用为空操作。返回是否发放了首训奖励。
    @discardableResult
    static func touchDailyActivity(track: LevelConfig,
                                   now: Date = .now,
                                   in context: ModelContext) -> Bool {
        let record = progress(in: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        if let last = record.lastTrainingDay {
            let lastDay = calendar.startOfDay(for: last)
            guard today > lastDay else { return false }
            let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? Int.max
            record.streakDays = gap == 1 ? record.streakDays + 1 : 1
        } else {
            record.streakDays = 1
        }
        record.lastTrainingDay = now
        record.xp += track.xp.dailyFirst
        syncLevel(record, track: track)
        try? context.save()
        return true
    }

    private static func syncLevel(_ record: UserProgress, track: LevelConfig) {
        record.level = levelID(forXP: record.xp, track: track)
    }

    // MARK: - 写入：课程 / 测验

    /// 标记课程完成（幂等）。返回课程本身的新增 XP（不含每日首训奖励）。
    @discardableResult
    static func completeLesson(_ lessonID: String,
                               track: LevelConfig,
                               in context: ModelContext) -> Int {
        let xp = LessonProgressService.completeLesson(lessonID, xpRules: track.xp, in: context)
        touchDailyActivity(track: track, in: context)
        syncLevel(progress(in: context), track: track)
        try? context.save()
        return xp
    }

    static func recordQuizAnswer(questionID: String,
                                 correct: Bool,
                                 track: LevelConfig,
                                 in context: ModelContext) {
        LessonProgressService.recordQuizAnswer(questionID: questionID,
                                               correct: correct, in: context)
        touchDailyActivity(track: track, in: context)
        try? context.save()
    }

    // MARK: - 写入：训练

    static func recordDrillAnswer(scenarioID: String,
                                  trainer: String,
                                  grade: DrillGrade,
                                  xp: Int,
                                  track: LevelConfig,
                                  in context: ModelContext) {
        DrillProgressService.recordAnswer(scenarioID: scenarioID, trainer: trainer,
                                          grade: grade, xp: xp, in: context)
        touchDailyActivity(track: track, in: context)
        syncLevel(progress(in: context), track: track)
        try? context.save()
    }

    static func logMistake(scenarioID: String,
                           trainer: String,
                           userChoice: String,
                           correctAnswer: String,
                           reason: LocalizedText,
                           lessonRef: String?,
                           srs: SRSConfig,
                           in context: ModelContext) {
        DrillProgressService.logMistake(scenarioID: scenarioID, trainer: trainer,
                                        userChoice: userChoice, correctAnswer: correctAnswer,
                                        reason: reason, lessonRef: lessonRef,
                                        srs: srs, in: context)
    }

    // MARK: - SRS 复习

    /// 到期待复习（未掌握且复习时间已到），按到期先后排序。
    static func dueReviews(now: Date = .now,
                           in context: ModelContext) -> [MistakeReviewItem] {
        let descriptor = FetchDescriptor<MistakeReviewItem>(
            predicate: #Predicate { $0.masteredAt == nil && $0.nextReviewAt <= now },
            sortBy: [SortDescriptor(\MistakeReviewItem.nextReviewAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// 复习一题的结果落账：
    /// 通过 → SRS 阶段 +1 并按间隔表排期，越过最后一档即标记掌握，发放 reviewPass XP；
    /// 未通过 → 阶段归零、按首档间隔重排，不发 XP。两种情况都记一条 "review" 流水。
    static func recordReviewOutcome(scenarioID: String,
                                    passed: Bool,
                                    srs: SRSConfig,
                                    track: LevelConfig,
                                    now: Date = .now,
                                    in context: ModelContext) {
        let descriptor = FetchDescriptor<MistakeReviewItem>(
            predicate: #Predicate { $0.scenarioID == scenarioID })
        guard let item = (try? context.fetch(descriptor))?.first else { return }

        let calendar = Calendar.current
        let xp: Int
        if passed {
            item.stage += 1
            if item.stage >= srs.intervalsDays.count {
                item.masteredAt = now
            } else {
                let days = srs.intervalsDays[item.stage]
                item.nextReviewAt = calendar.date(byAdding: .day, value: days, to: now) ?? now
            }
            xp = track.xp.reviewPass
            let record = progress(in: context)
            record.xp += xp
            syncLevel(record, track: track)
        } else {
            item.stage = 0
            item.masteredAt = nil
            let days = srs.intervalsDays.first ?? 1
            item.nextReviewAt = calendar.date(byAdding: .day, value: days, to: now) ?? now
            xp = 0
        }

        context.insert(DrillRecord(date: now, scenarioID: scenarioID, trainer: "review",
                                   grade: passed ? "correct" : "wrong", xpEarned: xp))
        touchDailyActivity(track: track, now: now, in: context)
        try? context.save()
    }

    // MARK: - Profile 聚合

    struct TrainerStats: Identifiable {
        let trainer: String
        let total: Int
        let correct: Int

        var id: String { trainer }
        var accuracy: Double? { total > 0 ? Double(correct) / Double(total) : nil }
    }

    /// 各训练器（含 quiz / review）的作答量与正确率，仅返回有数据的项。
    static func trainerStats(in context: ModelContext) -> [TrainerStats] {
        let records = (try? context.fetch(FetchDescriptor<DrillRecord>())) ?? []
        return ["preflop", "postflop", "playerType", "quiz", "review"].compactMap { name in
            let group = records.filter { $0.trainer == name }
            guard !group.isEmpty else { return nil }
            return TrainerStats(trainer: name,
                                total: group.count,
                                correct: group.filter { $0.grade == "correct" }.count)
        }
    }

    struct DailyXP: Identifiable {
        let day: Date
        let xp: Int

        var id: Date { day }
    }

    /// 近 N 天每日训练 XP（含今日，缺日补 0）——Profile 图表数据源。
    static func dailyXP(days: Int,
                        now: Date = .now,
                        in context: ModelContext) -> [DailyXP] {
        let calendar = Calendar.current
        guard days > 0,
              let start = calendar.date(byAdding: .day, value: -(days - 1),
                                        to: calendar.startOfDay(for: now)) else { return [] }
        let records = (try? context.fetch(FetchDescriptor<DrillRecord>(
            predicate: #Predicate { $0.date >= start }))) ?? []

        var byDay: [Date: Int] = [:]
        for record in records {
            byDay[calendar.startOfDay(for: record.date), default: 0] += record.xpEarned
        }
        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start)
            else { return nil }
            return DailyXP(day: day, xp: byDay[day] ?? 0)
        }
    }
}
