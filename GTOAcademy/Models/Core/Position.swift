import Foundation

/// 6-max 位置。rawValue 即 JSON 编码。
enum Position: String, CaseIterable, Codable, Sendable, Hashable {
    case utg, hj, co, btn, sb, bb

    var displayName: String { rawValue.uppercased() }

    /// 翻前行动顺序（0 最先行动）。
    var preflopOrder: Int {
        switch self {
        case .utg: 0
        case .hj: 1
        case .co: 2
        case .btn: 3
        case .sb: 4
        case .bb: 5
        }
    }

    var fullName: LocalizedText {
        switch self {
        case .utg: LocalizedText(zh: "枪口位 UTG", en: "Under the Gun")
        case .hj: LocalizedText(zh: "劫机位 HJ", en: "Hijack")
        case .co: LocalizedText(zh: "关煞位 CO", en: "Cutoff")
        case .btn: LocalizedText(zh: "按钮位 BTN", en: "Button")
        case .sb: LocalizedText(zh: "小盲位 SB", en: "Small Blind")
        case .bb: LocalizedText(zh: "大盲位 BB", en: "Big Blind")
        }
    }
}
