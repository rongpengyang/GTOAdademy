import Foundation
import SwiftData

/// 每次答题流水（Profile 统计图表数据源）。
@Model
final class DrillRecord {
    var date: Date
    var scenarioID: String
    /// "preflop" / "postflop" / "playerType" / "review" / "quiz"
    var trainer: String
    /// "correct" / "acceptable" / "wrong"
    var grade: String
    var xpEarned: Int

    init(date: Date = .now,
         scenarioID: String,
         trainer: String,
         grade: String,
         xpEarned: Int) {
        self.date = date
        self.scenarioID = scenarioID
        self.trainer = trainer
        self.grade = grade
        self.xpEarned = xpEarned
    }
}
