import SwiftUI

struct CoinCardView: View {
    let coin: Coin

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            image
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(coin.shortTitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brandInk)
                .lineLimit(1)

            Text(dateText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: coin.dateAdded)
    }

    @ViewBuilder
    private var image: some View {
        if let data = coin.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            ZStack {
                RadialGradient(
                    colors: [Color.coinGold.opacity(0.35),
                             Color.coinGold.opacity(0.08)],
                    center: .center, startRadius: 4, endRadius: 80)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.coinGold)
            }
        }
    }
}

#Preview {
    CoinCardView(coin: Coin.seedCollection[0])
        .frame(width: 170)
        .padding()
}
