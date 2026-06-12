import XCTest
import SwiftData
@testable import GTOAcademy

/// LessonProgressService 写入逻辑（内存容器，不落盘）。
@MainActor
final class ProgressServiceTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProgress.self, DrillRecord.self,
                 MistakeReviewItem.self, AppSettings.self,
            configurations: configuration)
        return ModelContext(container)
    }

    private var rules: XPRules {
        XPRules(lessonComplete: 20, curatedCorrect: 5, endlessCorrect: 2,
                acceptable: 2, reviewPass: 3, dailyFirst: 10)
    }

    func testCompleteLessonAwardsXPOnce() throws {
        let context = try makeContext()

        let first = LessonProgressService.completeLesson("l1-01", xpRules: rules, in: context)
        XCTAssertEqual(first, 20)

        let repeated = LessonProgressService.completeLesson("l1-01", xpRules: rules, in: context)
        XCTAssertEqual(repeated, 0, "重复完成不应重复计 XP")

        let progress = LessonProgressService.progress(in: context)
        XCTAssertEqual(progress.xp, 20)
        XCTAssertEqual(progress.completedLessonIDs, ["l1-01"])
        XCTAssertTrue(LessonProgressService.isCompleted("l1-01", in: context))
        XCTAssertFalse(LessonProgressService.isCompleted("l1-02", in: context))
    }

    func testRecordQuizAnswerWritesDrillRecords() throws {
        let context = try makeContext()

        LessonProgressService.recordQuizAnswer(questionID: "q1", correct: true, in: context)
        LessonProgressService.recordQuizAnswer(questionID: "q2", correct: false, in: context)

        let records = try context.fetch(FetchDescriptor<DrillRecord>())
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(Set(records.map(\.trainer)), ["quiz"])
        XCTAssertEqual(Set(records.map(\.grade)), ["correct", "wrong"])
        XCTAssertEqual(records.map(\.xpEarned), [0, 0])
    }

    func testProgressReturnsSingleRecord() throws {
        let context = try makeContext()

        let first = LessonProgressService.progress(in: context)
        first.xp = 7
        let second = LessonProgressService.progress(in: context)
        XCTAssertEqual(second.xp, 7, "应复用同一条 UserProgress")

        let all = try context.fetch(FetchDescriptor<UserProgress>())
        XCTAssertEqual(all.count, 1)
    }
}
