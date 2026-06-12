import SwiftUI

/// 字体角色表。全部基于 TextStyle 派生，保留 Dynamic Type 缩放能力。
enum Typo {
    static let largeTitle = Font.system(.largeTitle, weight: .bold)
    static let title = Font.system(.title2, weight: .semibold)
    static let headline = Font.system(.headline)
    static let body = Font.system(.body)
    static let caption = Font.system(.caption)
    /// 数值统一 rounded + 等宽数字（调用处叠加 .monospacedDigit()），避免跳动。
    static let statValue = Font.system(.title, design: .rounded, weight: .bold)
    /// 牌面字符：大号重字重。
    static let cardRank = Font.system(.largeTitle, design: .rounded, weight: .heavy)
}
