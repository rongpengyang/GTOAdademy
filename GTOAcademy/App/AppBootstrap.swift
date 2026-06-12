import Foundation
import Observation

/// 启动引导：加载并校验全部内容，产出 AppDependencies。
/// 内容损坏时进入显式失败态——不允许半残运行。
@MainActor
@Observable
final class AppBootstrap {
    enum State: Sendable {
        case loading
        case ready(AppDependencies)
        case failed(String)
    }

    private(set) var state: State = .loading
    private var started = false

    /// @State 的属性初始化发生在 nonisolated 上下文，故 init 必须 nonisolated。
    nonisolated init() {}

    func loadIfNeeded() async {
        guard !started else { return }
        started = true
        do {
            // v1 内容为 KB 级，同步解码即可；内容增长后移入后台 Task。
            let library = try ContentLoader.load()
            state = .ready(AppDependencies(content: library))
        } catch {
            state = .failed(String(describing: error))
        }
    }
}
