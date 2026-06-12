import Foundation
import SwiftData
import SwiftUI

/// 设置单例访问与应用：四色牌面 / 主题 / 触感。
/// 读写都走这里，视图层不手工创建 AppSettings 记录。
@MainActor
enum SettingsStore {
    /// 取（或创建）唯一的 AppSettings 记录。
    static func settings(in context: ModelContext) -> AppSettings {
        if let existing = (try? context.fetch(FetchDescriptor<AppSettings>()))?.first {
            return existing
        }
        let fresh = AppSettings()
        context.insert(fresh)
        try? context.save()
        return fresh
    }

    /// 把触感开关同步到 Haptics 静态门（App 启动与设置变更时调用）。
    static func applyHaptics(_ settings: AppSettings) {
        Haptics.isEnabled = settings.hapticsEnabled
    }

    /// preferredTheme → SwiftUI ColorScheme（"system" 返回 nil 跟随系统）。
    static func colorScheme(for theme: String) -> ColorScheme? {
        switch theme {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
}
