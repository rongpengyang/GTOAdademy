import SwiftUI

/// iPad / 大屏阅读宽度约束（M9）。
/// 内容列收窄到 680pt 并居中，两侧自然留白；iPhone 屏宽小于该值，因而完全无感知。
extension View {
    /// 课程正文、答题卡、列表页统一调用，挂在滚动容器的内容栈上。
    func readableWidth(_ maxWidth: CGFloat = 680) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
