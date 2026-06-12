import SwiftUI

/// 4pt 网格间距。
enum Spacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
}

/// 圆角（连续曲率，调用处用 .continuous style）。
enum Radius {
    static let card: CGFloat = 12
    static let sheet: CGFloat = 16
    static let pill: CGFloat = 999
}
