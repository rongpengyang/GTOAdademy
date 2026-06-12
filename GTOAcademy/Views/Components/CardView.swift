import SwiftUI

/// 扑克牌视觉组件。四色牌缺省开启（♠黑 ♥红 ♦蓝 ♣绿），提升花色辨识与色弱友好度。
struct CardView: View {
    let card: Card
    var width: CGFloat = 56
    var fourColor: Bool = true

    private var height: CGFloat { width * 1.4 }
    private var corner: CGFloat { width * 0.16 }

    var body: some View {
        VStack(spacing: 0) {
            Text(card.rank.letter)
                .font(.system(size: width * 0.46, weight: .heavy, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: width * 0.4))
        }
        .foregroundStyle(Theme.suitColor(card.suit, fourColor: fourColor))
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.adaptive(light: 0xFFFFFF, dark: 0x1E2630)))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(Color.adaptive(light: 0xD9DEE4, dark: 0x2C3642), lineWidth: 1))
        .accessibilityLabel(card.displayName)
    }
}

extension HandClass {
    /// 该类别的展示样例两张牌（确定性：对子 ♠♥，同花 ♠♠，不同花 ♠♥）。
    var displayCards: [Card] {
        switch kind {
        case .pair:
            [Card(rank: high, suit: .spades), Card(rank: high, suit: .hearts)]
        case .suited:
            [Card(rank: high, suit: .spades), Card(rank: low, suit: .spades)]
        case .offsuit:
            [Card(rank: high, suit: .spades), Card(rank: low, suit: .hearts)]
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        CardView(card: Card(code: "As")!)
        CardView(card: Card(code: "Kh")!)
        CardView(card: Card(code: "Td")!)
        CardView(card: Card(code: "7c")!)
    }
    .padding()
    .background(Theme.inkBackground)
}
