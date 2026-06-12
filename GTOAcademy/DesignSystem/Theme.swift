import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1)
    }
}

extension Color {
    /// 深/浅主题自适应颜色。
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

/// 设计 token（见 docs/ARCHITECTURE.md §7）。视图只引用 Theme，不写裸色值。
/// 方向：专业训练工具的克制质感——墨色底 + 毛毡绿强调 + 金色仅用于成就时刻。
enum Theme {
    static let inkBackground = Color.adaptive(light: 0xF7F8F9, dark: 0x0B0E12)
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x151B23)
    static let surfaceElevated = Color.adaptive(light: 0xF1F3F5, dark: 0x1C2430)
    static let feltAccent = Color.adaptive(light: 0x1E7A50, dark: 0x2E9E6B)
    /// 仅成就 / 升级时刻使用。
    static let goldMoment = Color.adaptive(light: 0xB8860B, dark: 0xD9A441)
    static let danger = Color.adaptive(light: 0xD33036, dark: 0xE5484D)
    static let textPrimary = Color.adaptive(light: 0x14181D, dark: 0xE6EDF3)
    static let textSecondary = Color.adaptive(light: 0x5B6672, dark: 0x93A1B0)

    /// 花色颜色。fourColor 开启时为四色牌（♠黑 ♥红 ♦蓝 ♣绿），提升可读性与色弱友好度。
    static func suitColor(_ suit: Suit, fourColor: Bool) -> Color {
        switch suit {
        case .spades:
            return Color.adaptive(light: 0x14181D, dark: 0xE6EDF3)
        case .hearts:
            return Color.adaptive(light: 0xC93636, dark: 0xFF5C5C)
        case .diamonds:
            return fourColor
                ? Color.adaptive(light: 0x1F6FD6, dark: 0x4D9FFF)
                : Color.adaptive(light: 0xC93636, dark: 0xFF5C5C)
        case .clubs:
            return fourColor
                ? Color.adaptive(light: 0x2E8A46, dark: 0x3FB950)
                : Color.adaptive(light: 0x14181D, dark: 0xE6EDF3)
        }
    }
}
