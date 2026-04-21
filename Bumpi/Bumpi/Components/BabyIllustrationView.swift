import SwiftUI

/// A stylized illustrative baby-in-womb graphic drawn with SF Symbols and
/// gradients. No external assets required.
struct BabyIllustrationView: View {
    var pulse: Bool = false
    var size: CGFloat = 220

    @State private var scale: CGFloat = 1.0
    @State private var glow: CGFloat = 0.6

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BumpiTheme.accent.opacity(0.55),
                            BumpiTheme.primary.opacity(0.15),
                            Color.white.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.75
                    )
                )
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .opacity(glow)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [BumpiTheme.accent, BumpiTheme.primary.opacity(0.85)],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 10,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: BumpiTheme.primary.opacity(0.3), radius: 18, x: 0, y: 8)

            Image(systemName: "figure.child")
                .font(.system(size: size * 0.28, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.88))
                .offset(y: size * 0.01)

            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.12))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BumpiTheme.primary, BumpiTheme.primaryDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(x: -size * 0.05, y: -size * 0.05)
                .scaleEffect(scale)
        }
        .onAppear {
            if pulse {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    scale = 1.08
                    glow = 0.9
                }
            }
        }
    }
}

#if DEBUG
struct BabyIllustrationView_Previews: PreviewProvider {
    static var previews: some View {
        BabyIllustrationView(pulse: true)
            .padding()
            .background(BumpiTheme.background)
    }
}
#endif
