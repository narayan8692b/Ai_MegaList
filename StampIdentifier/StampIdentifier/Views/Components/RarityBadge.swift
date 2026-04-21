import SwiftUI

struct RarityBadge: View {
    let rarity: Rarity

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: rarity.symbol)
            Text(rarity.rawValue)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(rarity.tintColor)
        .background(
            Capsule().fill(rarity.tintColor.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(rarity.tintColor.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        ForEach(Rarity.allCases) { rarity in
            RarityBadge(rarity: rarity)
        }
    }
    .padding()
}
