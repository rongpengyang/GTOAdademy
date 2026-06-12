import XCTest
@testable import GTOAcademy

/// 通用训练会话状态机（泛型，Int 充当题目）。
@MainActor
final class DrillSessionViewModelTests: XCTestCase {
    func testRevealIsIdempotentAndAccumulates() {
        let session = DrillSessionViewModel(items: [1, 2, 3])
        session.reveal(grade: .correct, xp: 5)
        session.reveal(grade: .wrong, xp: 0) // 已揭示，应被忽略
        XCTAssertTrue(session.revealed)
        XCTAssertEqual(session.lastGrade, .correct)
        XCTAssertEqual(session.correctCount, 1)
        XCTAssertEqual(session.wrongCount, 0)
        XCTAssertEqual(session.xpEarned, 5)
    }

    func testAdvanceRequiresReveal() {
        let session = DrillSessionViewModel(items: [1, 2])
        session.advance()
        XCTAssertEqual(session.currentIndex, 0, "未揭示前 advance 应无效")
        XCTAssertFalse(session.finished)
    }

    func testCuratedFinishesAfterLastItem() {
        let session = DrillSessionViewModel(items: [10, 20])
        XCTAssertFalse(session.isLastItem)

        session.reveal(grade: .correct, xp: 5)
        session.advance()
        XCTAssertEqual(session.currentIndex, 1)
        XCTAssertEqual(session.currentItem, 20)
        XCTAssertFalse(session.revealed)
        XCTAssertTrue(session.isLastItem)

        session.reveal(grade: .acceptable, xp: 2)
        session.advance()
        XCTAssertTrue(session.finished)
        XCTAssertEqual(session.answeredCount, 2)
        XCTAssertEqual(session.xpEarned, 7)
    }

    func testEndlessAppendsNextAndEndsOnNil() {
        let session = DrillSessionViewModel(items: [1], isEndless: true)
        XCTAssertFalse(session.isLastItem, "无尽模式没有「末题」概念")

        session.reveal(grade: .correct, xp: 2)
        session.advance(appending: 2)
        XCTAssertEqual(session.currentItem, 2)
        XCTAssertFalse(session.finished)
        XCTAssertFalse(session.revealed)

        session.reveal(grade: .wrong, xp: 0)
        session.advance(appending: nil) // 续题失败 → 同样收束
        XCTAssertTrue(session.finished)
    }

    func testFinishSessionEndsImmediately() {
        let session = DrillSessionViewModel(items: [1, 2, 3], isEndless: true)
        session.reveal(grade: .correct, xp: 2)
        session.finishSession()
        XCTAssertTrue(session.finished)
        XCTAssertEqual(session.answeredCount, 1)
    }
}
