import XCTest
import SwiftData
@testable import GTOAcademy

/// 统一写入口：等级门槛 / 连续天数 / 每日首训奖励 / SRS 复习调度（内存容器，不落盘）。
@MainActor
final class ProgressStoreTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProgress.self, DrillRecord.self,
                 MistakeReviewItem.self, AppSettings.self,
            configurations: configuration)
        return ModelContext(container)
    }

    private func day(_ offset: Int, from base: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: base)!
    }

    // MARK: - 等级门槛

    func testLevelThresholds() throws {
        let track = try ContentLoader.load().levels

        XCTAssertEqual(ProgressStore.levelID(forXP: 0, track: track), 1)
        XCTAssertEqual(ProgressStore.levelID(forXP: 59, track: track), 1)
        XCTAssertEqual(ProgressStore.levelID(forXP: 60, track: track), 2)
        XCTAssertEqual(ProgressStore.levelID(forXP: 1240, track: track), 8)
        XCTAssertEqual(ProgressStore.levelID(forXP: 5000, track: track), 8)
    }

    func testLevelInfoProgress() throws {
        let track = try ContentLoader.load().levels

        let midway = try XCTUnwrap(ProgressStore.levelInfo(forXP: 30, track: track))
        XCTAssertEqual(midway.current.id, 1)
        XCTAssertEqual(midway.next?.id, 2)
        XCTAssertEqual(midway.progress, 0.5, accuracy: 0.001)

        let maxed = try XCTUnwrap(ProgressStore.levelInfo(forXP: 2000, track: track))
        XCTAssertEqual(maxed.current.id, 8)
        XCTAssertNil(maxed.next)
        XCTAssertEqual(maxed.progress, 1, accuracy: 0.001)
    }

    // MARK: - 每日活跃与连续天数

    func testDailyFirstGrantedOncePerDay() throws {
        let context = try makeContext()
        let track = try ContentLoader.load().levels
        let day1 = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertTrue(ProgressStore.touchDailyActivity(track: track, now: day1, in: context))
        let record = ProgressStore.progress(in: context)
        XCTAssertEqual(record.xp, track.xp.dailyFirst)
        XCTAssertEqual(record.streakDays, 1)

        XCTAssertFalse(ProgressStore.touchDailyActivity(track: track, now: day1, in: context))
        XCTAssertEqual(record.xp, track.xp.dailyFirst)
        XCTAssertEqual(record.streakDays, 1)
    }

    func testStreakAcrossDays() throws {
        let context = try makeContext()
        let track = try ContentLoader.load().levels
        let day1 = Date(timeIntervalSince1970: 1_700_000_000)

        ProgressStore.touchDailyActivity(track: track, now: day1, in: context)
        ProgressStore.touchDailyActivity(track: track, now: day(1, from: day1), in: context)
        XCTAssertEqual(ProgressStore.progress(in: context).streakDays, 2)

        // 隔了一天没训：连续天数重置。
        ProgressStore.touchDailyActivity(track: track, now: day(3, from: day1), in: context)
        XCTAssertEqual(ProgressStore.progress(in: context).streakDays, 1)
    }

    // MARK: - 训练 / 课程写入

    func testRecordDrillAnswerSyncsLevelAndTouches() throws {
        let context = try makeContext()
        let track = try ContentLoader.load().levels

        ProgressStore.recordDrillAnswer(scenarioID: "pf-a", trainer: "preflop",
                                        grade: .correct, xp: 5,
                                        track: track, in: context)

        let records = try context.fetch(FetchDescriptor<DrillRecord>())
        XCTAssertEqual(records.count, 1)
        let progress = ProgressStore.progress(in: context)
        XCTAssertEqual(progress.xp, 5 + track.xp.dailyFirst)
        XCTAssertEqual(progress.level,
                       ProgressStore.levelID(forXP: progress.xp, track: track))
    }

    func testCompleteLessonIdempotentWithBonus() throws {
        let context = try makeContext()
        let track = try ContentLoader.load().levels

        let first = ProgressStore.completeLesson("l1-01", track: track, in: context)
        XCTAssertEqual(first, track.xp.lessonComplete)
        let progress = ProgressStore.progress(in: context)
        XCTAssertEqual(progress.xp, track.xp.lessonComplete + track.xp.dailyFirst)

        let again = ProgressStore.completeLesson("l1-01", track: track, in: context)
        XCTAssertEqual(again, 0)
        XCTAssertEqual(progress.xp, track.xp.lessonComplete + track.xp.dailyFirst)
    }

    // MARK: - SRS 复习调度

    func testReviewPassAdvancesAndSchedules() throws {
        let context = try makeContext()
        let library = try ContentLoader.load()
        let track = library.levels
        let srs = library.srs
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        ProgressStore.logMistake(scenarioID: "pf-a", trainer: "preflop",
                                 userChoice: "fold", correctAnswer: "raise",
                                 reason: LocalizedText(zh: "原因", en: "reason"),
                                 lessonRef: nil, srs: srs, in: context)
        // 先消耗当日首训奖励，便于断言纯 reviewPass 增量。
        ProgressStore.touchDailyActivity(track: track, now: now, in: context)
        let xpBefore = ProgressStore.progress(in: context).xp

        ProgressStore.recordReviewOutcome(scenarioID: "pf-a", passed: true,
                                          srs: srs, track: track,
                                          now: now, in: context)

        let items = try context.fetch(FetchDescriptor<MistakeReviewItem>())
        let item = try XCTUnwrap(items.first)
        XCTAssertEqual(item.stage, 1)
        XCTAssertNil(item.masteredAt)
        let expected = Calendar.current.date(byAdding: .day,
                                             value: srs.intervalsDays[1], to: now)
        XCTAssertEqual(item.nextReviewAt, expected)

        XCTAssertEqual(ProgressStore.progress(in: context).xp,
                       xpBefore + track.xp.reviewPass)
        let reviews = try context.fetch(FetchDescriptor<DrillRecord>())
            .filter { $0.trainer == "review" }
        XCTAssertEqual(reviews.count, 1)
        XCTAssertEqual(reviews.first?.grade, "correct")
    }

    func testReviewPassAtFinalStageMasters() throws {
        let context = try makeContext()
        let library = try ContentLoader.load()
        let srs = library.srs
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let item = MistakeReviewItem(scenarioID: "pf-final", trainer: "preflop",
                                     userChoice: "fold", correctAnswer: "raise",
                                     reasonZH: "原因", reasonEN: "reason",
                                     lessonRef: nil,
                                     stage: srs.intervalsDays.count - 1,
                                     nextReviewAt: now)
        context.insert(item)

        ProgressStore.recordReviewOutcome(scenarioID: "pf-final", passed: true,
                                          srs: srs, track: library.levels,
                                          now: now, in: context)

        XCTAssertNotNil(item.masteredAt)
        XCTAssertEqual(item.stage, srs.intervalsDays.count)
    }

    func testReviewFailResetsAndNoXP() throws {
        let context = try makeContext()
        let library = try ContentLoader.load()
        let track = library.levels
        let srs = library.srs
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let item = MistakeReviewItem(scenarioID: "pf-fail", trainer: "preflop",
                                     userChoice: "fold", correctAnswer: "raise",
                                     reasonZH: "原因", reasonEN: "reason",
                                     lessonRef: nil,
                                     stage: 2,
                                     nextReviewAt: now)
        context.insert(item)
        ProgressStore.touchDailyActivity(track: track, now: now, in: context)
        let xpBefore = ProgressStore.progress(in: context).xp

        ProgressStore.recordReviewOutcome(scenarioID: "pf-fail", passed: false,
                                          srs: srs, track: track,
                                          now: now, in: context)

        XCTAssertEqual(item.stage, 0)
        XCTAssertNil(item.masteredAt)
        let expected = Calendar.current.date(byAdding: .day,
                                             value: srs.intervalsDays[0], to: now)
        XCTAssertEqual(item.nextReviewAt, expected)
        XCTAssertEqual(ProgressStore.progress(in: context).xp, xpBefore)

        let reviews = try context.fetch(FetchDescriptor<DrillRecord>())
            .filter { $0.trainer == "review" }
        XCTAssertEqual(reviews.first?.grade, "wrong")
        XCTAssertEqual(reviews.first?.xpEarned, 0)
    }

    func testDueReviewsFiltersAndSorts() throws {
        let context = try makeContext()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let overdue = MistakeReviewItem(scenarioID: "due-1", trainer: "preflop",
                                        userChoice: "fold", correctAnswer: "raise",
                                        reasonZH: "原因", reasonEN: "reason",
                                        lessonRef: nil,
                                        nextReviewAt: day(-1, from: now))
        let future = MistakeReviewItem(scenarioID: "future-1", trainer: "preflop",
                                       userChoice: "fold", correctAnswer: "raise",
                                       reasonZH: "原因", reasonEN: "reason",
                                       lessonRef: nil,
                                       nextReviewAt: day(2, from: now))
        let mastered = MistakeReviewItem(scenarioID: "done-1", trainer: "preflop",
                                         userChoice: "fold", correctAnswer: "raise",
                                         reasonZH: "原因", reasonEN: "reason",
                                         lessonRef: nil,
                                         nextReviewAt: day(-3, from: now),
                                         masteredAt: now)
        context.insert(overdue)
        context.insert(future)
        context.insert(mastered)

        let due = ProgressStore.dueReviews(now: now, in: context)
        XCTAssertEqual(due.map(\.scenarioID), ["due-1"])
    }
}
