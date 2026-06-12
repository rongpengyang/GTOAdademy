import Foundation

/// 课程查询仓库（只读，Sendable）。
struct LessonRepository: Sendable {
    let trackFiles: [LessonTrackFile]
    private let lessonsByID: [String: Lesson]
    private let questionsByID: [String: QuizQuestion]

    init(trackFiles: [LessonTrackFile]) {
        let sorted = trackFiles.sorted { $0.track.order < $1.track.order }
        self.trackFiles = sorted

        var lessons: [String: Lesson] = [:]
        var questions: [String: QuizQuestion] = [:]
        for file in sorted {
            for lesson in file.lessons { lessons[lesson.id] = lesson }
            for question in file.questions { questions[question.id] = question }
        }
        self.lessonsByID = lessons
        self.questionsByID = questions
    }

    var tracks: [LessonTrack] { trackFiles.map(\.track) }

    func lessons(inTrack trackID: String) -> [Lesson] {
        trackFiles.first { $0.track.id == trackID }?
            .lessons.sorted { $0.order < $1.order } ?? []
    }

    func lesson(id: String) -> Lesson? { lessonsByID[id] }
    func question(id: String) -> QuizQuestion? { questionsByID[id] }

    var allLessonIDs: Set<String> { Set(lessonsByID.keys) }
    var totalLessonCount: Int { lessonsByID.count }
    var totalQuestionCount: Int { questionsByID.count }
}
