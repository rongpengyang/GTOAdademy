import Foundation
import Observation

/// 课末测验状态机：逐题作答 → 揭示 → 推进 → 结束。
/// 不触碰 SwiftData（持久化由 View 层经 LessonProgressService 完成），保证可单测。
@MainActor
@Observable
final class CheckpointQuizViewModel {
    let lesson: Lesson
    let questions: [QuizQuestion]

    private(set) var currentIndex = 0
    private(set) var selection: Int?
    private(set) var revealed = false
    private(set) var correctCount = 0
    private(set) var finished = false

    /// View 的 @State 属性初始化发生在 nonisolated 上下文。
    nonisolated init(lesson: Lesson, repository: LessonRepository) {
        self.lesson = lesson
        self.questions = lesson.quizIDs.compactMap { repository.question(id: $0) }
    }

    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    var isSelectionCorrect: Bool? {
        guard revealed, let selection, let question = currentQuestion else { return nil }
        return selection == question.correctIndex
    }

    var isPerfectScore: Bool {
        !questions.isEmpty && correctCount == questions.count
    }

    /// 选择某个选项并立即揭示。已揭示后忽略后续点击。
    func select(_ index: Int) {
        guard !revealed,
              let question = currentQuestion,
              question.choices.indices.contains(index) else { return }
        selection = index
        revealed = true
        if index == question.correctIndex {
            correctCount += 1
        }
    }

    /// 揭示后推进：下一题或进入结束态。
    func advance() {
        guard revealed else { return }
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selection = nil
            revealed = false
        } else {
            finished = true
        }
    }
}
