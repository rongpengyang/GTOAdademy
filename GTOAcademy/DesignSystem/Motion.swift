import SwiftUI

/// 动效规范。所有进入类动画须经 entrance(reduceMotion:) 取曲线，
/// 保证"减弱动态"设置下降级为淡入。
enum Motion {
    /// 标准曲线：spring(response: 0.35, dampingFraction: 0.8)。
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.9)

    static func entrance(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : standard
    }

    /// 签名动效参数：Range Matrix 对角线波次点亮的每格延迟。
    static func matrixWaveDelay(row: Int, column: Int) -> Double {
        Double(row + column) * 0.012
    }
}
