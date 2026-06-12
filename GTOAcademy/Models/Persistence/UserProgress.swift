import Foundation
import SwiftData

/// 用户成长状态（单例记录，ProgressStore 在 M5 阶段成为唯一写入口）。
@Model
final class UserProgress {
    var xp: Int
    var level: Int
    var streakDays: Int
    var lastTrainingDay: Date?
    var completedLessonIDs: [String]

    init(xp: Int = 0,
         level: Int = 1,
         streakDays: Int = 0,
         lastTrainingDay: Date? = nil,
         completedLessonIDs: [String] = []) {
        self.xp = xp
        self.level = level
        self.streakDays = streakDays
        self.lastTrainingDay = lastTrainingDay
        self.completedLessonIDs = completedLessonIDs
    }
}
