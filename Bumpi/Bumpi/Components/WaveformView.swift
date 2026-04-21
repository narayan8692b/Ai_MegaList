import SwiftUI

struct WaveformView: View {
    var levels: [CGFloat]
    var color: Color = BumpiTheme.primary
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    Capsule()
                        .fill(color)
                        .frame(
                            width: barWidth,
                            height: max(2, level * geo.size.height)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .animation(.easeOut(duration: 0.08), value: levels)
    }
}

struct StaticWaveformView: View {
    var barCount: Int = 60
    var color: Color = BumpiTheme.primary

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { idx in
                Capsule()
                    .fill(color.opacity(0.75))
                    .frame(width: 2, height: heightFor(idx))
            }
        }
    }

    private func heightFor(_ idx: Int) -> CGFloat {
        let t = Double(idx) / Double(barCount)
        let wave = sin(t * .pi * 6) * 0.5 + 0.5
        let envelope = sin(t * .pi)
        return CGFloat(6 + wave * envelope * 24)
    }
}
