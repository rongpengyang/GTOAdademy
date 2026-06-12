import Foundation

/// 内容双语字段。UI 框架文案后续走 String Catalog；内容 JSON 统一用本类型。
struct LocalizedText: Codable, Hashable, Sendable {
    let zh: String
    let en: String

    init(zh: String, en: String) {
        self.zh = zh
        self.en = en
    }

    var localized: String {
        Self.prefersChinese ? zh : en
    }

    static var prefersChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
    }
}

/// 骨架阶段的少量 UI 文案（M6 迁移到 Localizable.xcstrings）。
enum L10n {
    static var tabHome: String { LocalizedText(zh: "主页", en: "Home").localized }
    static var tabLearn: String { LocalizedText(zh: "学习", en: "Learn").localized }
    static var tabDrill: String { LocalizedText(zh: "训练", en: "Drill").localized }
    static var tabTools: String { LocalizedText(zh: "工具", en: "Tools").localized }
    static var tabProfile: String { LocalizedText(zh: "我的", en: "Profile").localized }
    static var loading: String { LocalizedText(zh: "正在加载训练内容…", en: "Loading training content…").localized }
    static var contentErrorTitle: String { LocalizedText(zh: "内容加载失败", en: "Content failed to load").localized }
}
