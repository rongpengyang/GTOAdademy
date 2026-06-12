import SwiftUI
import SwiftData

/// 设置：四色牌面 / 触感反馈 / 主题。直接绑定唯一 AppSettings 记录。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [AppSettings]

    var body: some View {
        ZStack {
            Theme.inkBackground.ignoresSafeArea()
            if let settings = records.first {
                form(settings)
            }
        }
        .navigationTitle(LocalizedText(zh: "设置", en: "Settings").localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { _ = SettingsStore.settings(in: modelContext) }
    }

    private func form(_ settings: AppSettings) -> some View {
        @Bindable var settings = settings
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                // 四色牌面
                VStack(alignment: .leading, spacing: Spacing.s12) {
                    Toggle(isOn: $settings.fourColorDeck) {
                        Text(LocalizedText(zh: "四色牌面", en: "Four-color deck").localized)
                            .font(Typo.body)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.feltAccent)

                    HStack(spacing: Spacing.s8) {
                        ForEach(["As", "Kh", "Qd", "Jc"], id: \.self) { code in
                            if let card = Card(code: code) {
                                CardView(card: card, width: 36,
                                         fourColor: settings.fourColorDeck)
                            }
                        }
                    }
                    Text(LocalizedText(zh: "♦ 蓝、♣ 绿，训练时更快区分花色。",
                                       en: "Blue diamonds and green clubs make suits faster to read.").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Spacing.s16)
                .background(Theme.surface,
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

                // 触感反馈
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    Toggle(isOn: $settings.hapticsEnabled) {
                        Text(LocalizedText(zh: "触感反馈", en: "Haptic feedback").localized)
                            .font(Typo.body)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.feltAccent)
                    Text(LocalizedText(zh: "答题、翻牌与升级时的轻微震动。",
                                       en: "Subtle taps on answers, deals and level-ups.").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Spacing.s16)
                .background(Theme.surface,
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))

                // 主题
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    Text(LocalizedText(zh: "主题", en: "Theme").localized)
                        .font(Typo.body)
                        .foregroundStyle(Theme.textPrimary)
                    Picker("", selection: $settings.preferredTheme) {
                        Text(LocalizedText(zh: "跟随系统", en: "System").localized).tag("system")
                        Text(LocalizedText(zh: "深色", en: "Dark").localized).tag("dark")
                        Text(LocalizedText(zh: "浅色", en: "Light").localized).tag("light")
                    }
                    .pickerStyle(.segmented)
                    Text(LocalizedText(zh: "深色是 GTO Academy 的默认手感。",
                                       en: "Dark is the GTO Academy house feel.").localized)
                        .font(Typo.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Spacing.s16)
                .background(Theme.surface,
                            in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            .padding(Spacing.s16)
        }
        .onChange(of: settings.hapticsEnabled) {
            SettingsStore.applyHaptics(settings)
            try? modelContext.save()
        }
        .onChange(of: settings.fourColorDeck) { try? modelContext.save() }
        .onChange(of: settings.preferredTheme) { try? modelContext.save() }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: [UserProgress.self, DrillRecord.self,
                              MistakeReviewItem.self, AppSettings.self],
                        inMemory: true)
        .preferredColorScheme(.dark)
}
