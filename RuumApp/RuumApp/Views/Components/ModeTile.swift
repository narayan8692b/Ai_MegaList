import SwiftUI

struct ModeTile: View {
    let mode: DesignMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Spacer(minLength: 8)
                Text(mode.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(
                LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}
