import SwiftUI

struct AntiqueCardView: View {
    let antique: Antique

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                image
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text(antique.shortTitle)
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
        return f.string(from: antique.dateAdded)
    }

    @ViewBuilder
    private var image: some View {
        if let data = antique.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.antiqueGold.opacity(0.25),
                             Color.antiqueGold.opacity(0.05)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "crown")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Color.antiqueGold)
            }
        }
    }
}

#Preview {
    AntiqueCardView(antique: Antique.seedCollection[0])
        .frame(width: 160)
        .padding()
}
