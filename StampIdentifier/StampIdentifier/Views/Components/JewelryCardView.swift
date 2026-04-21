import SwiftUI

struct JewelryCardView: View {
    let piece: Jewelry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            image
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(piece.shortTitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brandInk)
                .lineLimit(1)

            Text("\(piece.type.rawValue) · \(piece.estimatedValueDisplay)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private var image: some View {
        if let data = piece.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.jewelryGold.opacity(0.25),
                             Color.jewelryGold.opacity(0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "sparkles")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.jewelryGold)
            }
        }
    }
}

#Preview {
    JewelryCardView(piece: Jewelry.seedCollection[0])
        .frame(width: 170)
        .padding()
}
