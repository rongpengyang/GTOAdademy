import Foundation
import Observation

/// 依赖容器：内容库 + 各仓库。后续阶段在此追加 Services
/// （ScenarioEngine / PlayerClassifier / ProgressStore 等）。
/// 经 .environment 注入，@Environment(AppDependencies.self) 取用。
@MainActor
@Observable
final class AppDependencies {
    let content: ContentLibrary
    let lessons: LessonRepository
    let scenarios: ScenarioRepository
    let ranges: RangeRepository

    init(content: ContentLibrary) {
        self.content = content
        self.lessons = LessonRepository(trackFiles: content.trackFiles)
        self.scenarios = ScenarioRepository(
            preflop: content.preflop,
            postflop: content.postflop,
            playerType: content.playerType)
        self.ranges = RangeRepository(charts: content.ranges)
    }
}
