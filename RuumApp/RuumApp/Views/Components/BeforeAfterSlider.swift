import SwiftUI

struct BeforeAfterSlider: View {
    let before: UIImage
    let after: UIImage

    @State private var position: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let x = max(0, min(w, position * w))

            ZStack {
                Image(uiImage: after)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()

                Image(uiImage: before)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle().frame(width: x)
                            Spacer(minLength: 0)
                        }
                    )

                // Labels
                VStack {
                    HStack {
                        Label("Before", systemImage: "photo")
                            .labelStyle(.titleOnly)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.black.opacity(0.55), in: Capsule())
                            .foregroundColor(.white)
                        Spacer()
                        Label("After", systemImage: "sparkles")
                            .labelStyle(.titleOnly)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.ruumTeal, in: Capsule())
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    Spacer()
                }

                // Divider + handle
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: h)
                    .position(x: x, y: h / 2)

                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .foregroundColor(.ruumTeal)
                            .font(.system(size: 14, weight: .bold))
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .position(x: x, y: h / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        position = max(0, min(1, value.location.x / w))
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        }
    }
}
