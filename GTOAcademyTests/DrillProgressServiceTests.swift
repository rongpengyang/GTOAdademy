import XCTest
import SwiftData
@testable import GTOAcademy

/// 训练进度写入：流水 + XP + 错题快照（内存容器，不落盘）。
@MainActor
final class DrillProgressServiceTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProgress.self, DrillRecord.self,
                 MistakeReviewItem.self, AppSettings.self,
            configurations: configuration)
        return ModelContext(container)
    }

    func testRecordAnswerWritesRecordAndXP() throws {
        let context = try makeContext()

        DrillProgressService.recordAnswer(
            scenarioID: "pf-a", trainer: "preflop",
            grade: .correct, xp: 5, in: context)
        DrillProgressService.recordAnswer(
            scenarioID: "pf-b", trainer: "preflop",
            grade: .wrong, xp: 0, in: context)

        let records = try context.fetch(FetchDescriptor<DrillRecord>())
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(Set(records.map(\.grade)), ["correct", "wrong"])
        XCTAssertEqual(LessonProgressService.progress(in: context).xp, 5)
    }

    func testLogMistakeCreatesSnapshot() throws {
        let context = try makeContext()
        let srs = try ContentLoader.load().srs

        DrillProgressService.logMistake(
            scenarioID: "pf-a", trainer: "preflop",
            userChoice: "fold", correctAnswer: "raise",
            reason: LocalizedText(zh: "原因", en: "reason"),
            lessonRef: "l2-01-rfi-principles",
            srs: srs, in: context)

        let items = try context.fetch(FetchDescriptor<MistakeReviewItem>())
        XCTAssertEqual(items.count, 1)
        let item = try XCTUnwrap(items.first)
        XCTAssertEqual(item.stage, 0)
        XCTAssertEqual(item.trainer, "preflop")
        XCTAssertEqual(item.userChoice, "fold")
        XCTAssertEqual(item.correctAnswer, "raise")
        XCTAssertEqual(item.reasonZH, "原因")
        XCTAssertEqual(item.reasonEN, "reason")
        XCTAssertEqual(item.lessonRef, "l2-01-rfi-principles")
        XCTAssertNil(item.masteredAt)
        XCTAssertGreaterThan(item.nextReviewAt, .now)
    }

    func testRelogResetsStage() throws {
        let context = try makeContext()
        let srs = try ContentLoader.load().srs

        DrillProgressService.logMistake(
            scenarioID: "pf-a", trainer: "preflop",
            userChoice: "fold", correctAnswer: "raise",
            reason: LocalizedText(zh: "一", en: "one"),
            lessonRef: nil, srs: srs, in: context)
        let item = try XCTUnwrap(
            try context.fetch(FetchDescriptor<MistakeReviewItem>()).first)
        item.stage = 2
        item.masteredAt = .now

        DrillProgressService.logMistake(
            scenarioID: "pf-a", trainer: "preflop",
            userChoice: "call", correctAnswer: "raise",
            reason: LocalizedText(zh: "二", en: "two"),
            lessonRef: nil, srs: srs, in: context)

        let all = try context.fetch(FetchDescriptor<MistakeReviewItem>())
        XCTAssertEqual(all.count, 1, "同题应复用同一条记录而非新建")
        let updated = try XCTUnwrap(all.first)
        XCTAssertEqual(updated.stage, 0, "再次答错应重置 SRS 阶段")
        XCTAssertNil(updated.masteredAt)
        XCTAssertEqual(updated.userChoice, "call")
        XCTAssertEqual(updated.reasonZH, "二")
    }
}
