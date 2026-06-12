import Foundation
import SwiftData

/// 错题记录。解释文案做双语快照（内容版本升级不影响历史错题展示）。
@Model
final class MistakeReviewItem {
    var scenarioID: String
    var trainer: String
    var userChoice: String
    var correctAnswer: String
    var reasonZH: String
    var reasonEN: String
    var lessonRef: String?
    /// SRS 阶段：0 起步；通过依次进入 1/3/7/14 天间隔；越界即掌握。
    var stage: Int
    var nextReviewAt: Date
    var createdAt: Date
    var masteredAt: Date?

    init(scenarioID: String,
         trainer: String,
         userChoice: String,
         correctAnswer: String,
         reasonZH: String,
         reasonEN: String,
         lessonRef: String?,
         stage: Int = 0,
         nextReviewAt: Date,
         createdAt: Date = .now,
         masteredAt: Date? = nil) {
        self.scenarioID = scenarioID
        self.trainer = trainer
        self.userChoice = userChoice
        self.correctAnswer = correctAnswer
        self.reasonZH = reasonZH
        self.reasonEN = reasonEN
        self.lessonRef = lessonRef
        self.stage = stage
        self.nextReviewAt = nextReviewAt
        self.createdAt = createdAt
        self.masteredAt = masteredAt
    }
}
