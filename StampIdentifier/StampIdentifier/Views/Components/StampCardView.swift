import SwiftUI

struct StampCardView: View {
    let stamp: Stamp

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                stampImage
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                RarityBadge(rarity: stamp.rarity)
                    .padding(6)
            }

            Text(stamp.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.brandInk)
                .lineLimit(1)

            Text(stamp.valueRange.displayRange)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.brandOrange)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private var stampImage: some View {
        if let data = stamp.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [stamp.rarity.tintColor.opacity(0.25),
                             stamp.rarity.tintColor.opacity(0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "seal")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(stamp.rarity.tintColor)
            }
        }
    }
}

#Preview {
    StampCardView(stamp: Stamp.seedCollection[0])
        .frame(width: 160)
        .padding()
}
