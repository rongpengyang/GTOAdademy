import XCTest
@testable import GTOAcademy

/// 测验状态机（不触碰 SwiftData，纯逻辑可测）。
@MainActor
final class CheckpointQuizViewModelTests: XCTestCase {
    private let text = LocalizedText(zh: "文", en: "t")

    /// 两题夹具：q1 正确选项 1，q2 正确选项 0。
    private func makeViewModel() -> CheckpointQuizViewModel {
        let question1 = QuizQuestion(
            id: "q1", prompt: text, choices: [text, text, text], correctIndex: 1,
            choiceExplanations: [text, text, text], objective: text, lessonRef: "l1")
        let question2 = QuizQuestion(
            id: "q2", prompt: text, choices: [text, text, text], correctIndex: 0,
            choiceExplanations: [text, text, text], objective: text, lessonRef: "l1")
        let lesson = Lesson(
            id: "l1", order: 1, title: text, minutes: 3,
            blocks: [.concept(text), .mistake(text), .quizRef("q1"), .quizRef("q2")])
        let track = LessonTrack(id: "t1", order: 1, title: text, subtitle: nil)
        let file = LessonTrackFile(
            schemaVersion: 1, track: track,
            lessons: [lesson], questions: [question1, question2])
        return CheckpointQuizViewModel(
            lesson: lesson,
            repository: LessonRepository(trackFiles: [file]))
    }

    func testInitialState() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.questions.count, 2)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertNil(viewModel.selection)
        XCTAssertFalse(viewModel.revealed)
        XCTAssertFalse(viewModel.finished)
        XCTAssertEqual(viewModel.currentQuestion?.id, "q1")
        XCTAssertFalse(viewModel.isLastQuestion)
    }

    func testWrongSelectionRevealsWithoutScoreAndIgnoresRepeats() {
        let viewModel = makeViewModel()

        viewModel.select(0) // q1 正确为 1
        XCTAssertTrue(viewModel.revealed)
        XCTAssertEqual(viewModel.selection, 0)
        XCTAssertEqual(viewModel.correctCount, 0)
        XCTAssertEqual(viewModel.isSelectionCorrect, false)

        viewModel.select(1) // 已揭示，应被忽略
        XCTAssertEqual(viewModel.selection, 0)
        XCTAssertEqual(viewModel.correctCount, 0)
    }

    func testCorrectFlowThroughCompletion() {
        let viewModel = makeViewModel()

        viewModel.select(1)
        XCTAssertEqual(viewModel.correctCount, 1)
        XCTAssertEqual(viewModel.isSelectionCorrect, true)

        viewModel.advance()
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertFalse(viewModel.revealed)
        XCTAssertNil(viewModel.selection)
        XCTAssertTrue(viewModel.isLastQuestion)

        viewModel.select(0)
        XCTAssertEqual(viewModel.correctCount, 2)

        viewModel.advance()
        XCTAssertTrue(viewModel.finished)
        XCTAssertTrue(viewModel.isPerfectScore)
    }

    func testAdvanceRequiresReveal() {
        let viewModel = makeViewModel()
        viewModel.advance()
        XCTAssertEqual(viewModel.currentIndex, 0, "未揭示前 advance 应无效")
        XCTAssertFalse(viewModel.finished)
    }
}
