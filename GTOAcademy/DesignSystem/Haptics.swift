import UIKit

/// 触感事件集中映射。语义化命名，调用处不直接接触 UIKit 生成器。
/// 答错用 .error 但保持轻量——反馈，不惩罚。
/// isEnabled 是全局总闸，由 SettingsStore 在启动与设置变更时同步。
@MainActor
enum Haptics {
    static var isEnabled = true

    static func correct() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func wrong() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func deal() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func levelUp() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func tap() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
