import Foundation
import SwiftData

/// 用户设置（单例记录）。
@Model
final class AppSettings {
    var fourColorDeck: Bool
    /// "system" / "dark" / "light"
    var preferredTheme: String
    var hapticsEnabled: Bool
    /// 预留：用户自定义分类阈值（JSON 覆盖 Content/config/classifier.json）。
    var classifierOverridesJSON: String?

    init(fourColorDeck: Bool = true,
         preferredTheme: String = "system",
         hapticsEnabled: Bool = true,
         classifierOverridesJSON: String? = nil) {
        self.fourColorDeck = fourColorDeck
        self.preferredTheme = preferredTheme
        self.hapticsEnabled = hapticsEnabled
        self.classifierOverridesJSON = classifierOverridesJSON
    }
}
