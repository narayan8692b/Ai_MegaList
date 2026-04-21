import SwiftUI

struct StyleCard: View {
    let style: DesignStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                gradientPreview
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(style.tagline)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, 8)
            }
            .padding(8)
            .background(Color.ruumCard, in: RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous)
                    .stroke(isSelected ? Color.ruumTeal : Color.black.opacity(0.05),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var gradientPreview: some View {
        ZStack {
            LinearGradient(colors: style.colors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)

            VStack {
                HStack {
                    Text(style.name.prefix(1))
                        .font(.system(size: 38, weight: .black, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
