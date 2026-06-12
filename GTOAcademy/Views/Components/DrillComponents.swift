import SwiftUI

/// 判分徽章（正确 / 可接受 / 错误）。
struct GradeBadge: View {
    let grade: DrillGrade

    private var color: Color {
        switch grade {
        case .correct: Theme.feltAccent
        case .acceptable: Theme.goldMoment
        case .wrong: Theme.danger
        }
    }

    private var icon: String {
        switch grade {
        case .correct: "checkmark.circle.fill"
        case .acceptable: "checkmark.circle"
        case .wrong: "xmark.circle.fill"
        }
    }

    var body: some View {
        Label(grade.title.localized, systemImage: icon)
            .font(Typo.headline)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.s12)
            .padding(.vertical, Spacing.s8)
            .background(color.opacity(0.12), in: Capsule())
    }
}

/// 带强调色标题的解释卡（训练反馈通用）。
struct ExplanationCard: View {
    let title: LocalizedText
    let text: LocalizedText
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(title.localized)
                .font(Typo.caption)
                .fontWeight(.semibold)
                .foregroundStyle(accent)
            Text(text.localized)
                .font(Typo.body)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// 训练会话结算页（精编 / 无尽通用）。
struct DrillSummaryView: View {
    let title: LocalizedText
    let correct: Int
    let acceptable: Int
    let wrong: Int
    let xpEarned: Int
    let onDone: () -> Void

    private var flawless: Bool { wrong == 0 && correct + acceptable > 0 }

    var body: some View {
        VStack(spacing: Spacing.s16) {
            Spacer()

            Image(systemName: flawless ? "checkmark.seal.fill" : "flag.pattern.checkered")
                .font(.system(size: 52))
                .foregroundStyle(flawless ? Theme.goldMoment : Theme.feltAccent)

            Text(title.localized)
                .font(Typo.title)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: Spacing.s12) {
                summaryTile(count: correct,
                            label: LocalizedText(zh: "正确", en: "Correct"),
                            color: Theme.feltAccent)
                summaryTile(count: acceptable,
                            label: LocalizedText(zh: "可接受", en: "Acceptable"),
                            color: Theme.goldMoment)
                summaryTile(count: wrong,
                            label: LocalizedText(zh: "错误", en: "Wrong"),
                            color: Theme.danger)
            }

            if xpEarned > 0 {
                Text("+\(xpEarned) XP")
                    .font(Typo.headline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.goldMoment)
                    .padding(.horizontal, Spacing.s16)
                    .padding(.vertical, Spacing.s8)
                    .background(Theme.goldMoment.opacity(0.12), in: Capsule())
            }

            if wrong > 0 {
                Text(LocalizedText(zh: "答错的题已记入错题本，去「我的」按间隔复习。",
                                   en: "Misses were saved to the mistake book—review them in Profile.").localized)
                    .font(Typo.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onDone) {
                Text(LocalizedText(zh: "完成", en: "Done").localized)
                    .font(Typo.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.feltAccent)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.inkBackground)
    }

    private func summaryTile(count: Int, label: LocalizedText, color: Color) -> some View {
        VStack(spacing: Spacing.s4) {
            Text("\(count)")
                .font(Typo.statValue)
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label.localized)
                .font(Typo.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s16)
        .background(Theme.surface,
                    in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
