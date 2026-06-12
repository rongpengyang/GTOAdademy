import Foundation

/// 课程轨道文件（Content/lessons/*.json）的顶层结构。
struct LessonTrackFile: Codable, Sendable, Hashable {
    let schemaVersion: Int
    let track: LessonTrack
    let lessons: [Lesson]
    let questions: [QuizQuestion]
}

struct LessonTrack: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let order: Int
    let title: LocalizedText
    let subtitle: LocalizedText?
}

struct Lesson: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let order: Int
    let title: LocalizedText
    let minutes: Int
    let blocks: [LessonBlock]

    /// 课内引用的测验题 id。
    var quizIDs: [String] {
        blocks.compactMap {
            if case let .quizRef(id) = $0 { id } else { nil }
        }
    }
}

/// 课程内容块。未知 type 安全降级为 .unknown（前向兼容）。
enum LessonBlock: Sendable, Hashable {
    case concept(LocalizedText)
    case example(LocalizedText)
    case mistake(LocalizedText)
    case tip(LocalizedText)
    case quizRef(String)
    case unknown
}

extension LessonBlock: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, text, ref
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "concept": self = .concept(try container.decode(LocalizedText.self, forKey: .text))
        case "example": self = .example(try container.decode(LocalizedText.self, forKey: .text))
        case "mistake": self = .mistake(try container.decode(LocalizedText.self, forKey: .text))
        case "tip": self = .tip(try container.decode(LocalizedText.self, forKey: .text))
        case "quizRef": self = .quizRef(try container.decode(String.self, forKey: .ref))
        default: self = .unknown
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .concept(let t):
            try container.encode("concept", forKey: .type)
            try container.encode(t, forKey: .text)
        case .example(let t):
            try container.encode("example", forKey: .type)
            try container.encode(t, forKey: .text)
        case .mistake(let t):
            try container.encode("mistake", forKey: .type)
            try container.encode(t, forKey: .text)
        case .tip(let t):
            try container.encode("tip", forKey: .type)
            try container.encode(t, forKey: .text)
        case .quizRef(let id):
            try container.encode("quizRef", forKey: .type)
            try container.encode(id, forKey: .ref)
        case .unknown:
            try container.encode("unknown", forKey: .type)
        }
    }
}

/// 概念选择题（课内测验与 checkpoint 共用）。
struct QuizQuestion: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let prompt: LocalizedText
    let choices: [LocalizedText]
    let correctIndex: Int
    /// 与 choices 一一对应：每个选项为什么对 / 为什么不对。
    let choiceExplanations: [LocalizedText]
    let objective: LocalizedText
    let lessonRef: String?
}
