import SwiftUI

struct ScannerView: View {

    @StateObject private var vm = ScannerViewModel()
    @State private var showSource = false
    @State private var showTarget = false

    private let frameSize = CGSize(width: 280, height: 120)

    var body: some View {
        GeometryReader { geo in
            let holeOrigin = CGPoint(
                x: (geo.size.width - frameSize.width) / 2,
                y: geo.size.height * 0.38
            )
            let holeRect = CGRect(origin: holeOrigin, size: frameSize)

            ZStack {
                // Live camera feed
                CameraPreviewView(session: vm.captureSession)
                    .ignoresSafeArea()

                // Dimmed overlay with transparent scanning cutout (even-odd fill)
                ScannerDimOverlay(holeRect: holeRect, cornerRadius: 14)
                    .fill(Color.black.opacity(0.48), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Corner bracket markers on the scanning frame
                ScannerFrameView(rect: holeRect)
                    .allowsHitTesting(false)

                // Conversion result pill (appears below the scanning frame)
                if let detected = vm.detectedPrice, let converted = vm.convertedPrice {
                    Text(
                        "\(String(format: "%.2f", detected)) \(vm.sourceCurrency.symbol)"
                        + "  =  "
                        + "\(String(format: "%.2f", converted)) \(vm.targetCurrency.symbol)"
                    )
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.black.opacity(0.72)))
                    .position(x: geo.size.width / 2,
                              y: holeOrigin.y + frameSize.height + 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.easeInOut(duration: 0.2), value: detected)
                }

                // Bottom currency bar
                VStack {
                    Spacer()
                    CurrencyBarView(vm: vm,
                                    showSource: $showSource,
                                    showTarget: $showTarget)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 28)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear  { vm.startSession() }
        .onDisappear { vm.stopSession() }
        .sheet(isPresented: $showSource) {
            CurrencySelectorView(selected: $vm.sourceCurrency)
                .onChange(of: vm.sourceCurrency) { _ in vm.recalculate() }
        }
        .sheet(isPresented: $showTarget) {
            CurrencySelectorView(selected: $vm.targetCurrency)
                .onChange(of: vm.targetCurrency) { _ in vm.recalculate() }
        }
    }
}

// MARK: - Dimmed overlay with hole (even-odd winding rule)

private struct ScannerDimOverlay: Shape {
    let holeRect: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addPath(Path(roundedRect: holeRect,
                       cornerSize: CGSize(width: cornerRadius, height: cornerRadius)))
        return p
    }
}

// MARK: - Corner bracket frame drawn with Canvas

private struct ScannerFrameView: View {
    let rect: CGRect

    private let armLen: CGFloat = 24
    private let lw: CGFloat     = 3
    private let cr: CGFloat     = 14

    var body: some View {
        Canvas { ctx, _ in
            let white = GraphicsContext.Shading.color(.white)
            let blue  = GraphicsContext.Shading.color(Color(red: 0.2, green: 0.5, blue: 1.0))
            let bStyle = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)

            // Thin full-border guide
            ctx.stroke(
                Path(roundedRect: rect, cornerSize: CGSize(width: cr, height: cr)),
                with: .color(.white.opacity(0.2)),
                style: StrokeStyle(lineWidth: 1)
            )

            // Four corner brackets
            for corner in corners(rect: rect, cr: cr) {
                var p = Path()
                p.move(to: corner.hEnd)
                p.addLine(to: corner.apex)
                p.addLine(to: corner.vEnd)
                ctx.stroke(p, with: blue, style: bStyle)
            }
        }
    }

    private struct CornerPoints { let apex, hEnd, vEnd: CGPoint }

    private func corners(rect: CGRect, cr: CGFloat) -> [CornerPoints] {
        [
            CornerPoints(
                apex: CGPoint(x: rect.minX, y: rect.minY),
                hEnd: CGPoint(x: rect.minX + armLen, y: rect.minY),
                vEnd: CGPoint(x: rect.minX, y: rect.minY + armLen)
            ),
            CornerPoints(
                apex: CGPoint(x: rect.maxX, y: rect.minY),
                hEnd: CGPoint(x: rect.maxX - armLen, y: rect.minY),
                vEnd: CGPoint(x: rect.maxX, y: rect.minY + armLen)
            ),
            CornerPoints(
                apex: CGPoint(x: rect.minX, y: rect.maxY),
                hEnd: CGPoint(x: rect.minX + armLen, y: rect.maxY),
                vEnd: CGPoint(x: rect.minX, y: rect.maxY - armLen)
            ),
            CornerPoints(
                apex: CGPoint(x: rect.maxX, y: rect.maxY),
                hEnd: CGPoint(x: rect.maxX - armLen, y: rect.maxY),
                vEnd: CGPoint(x: rect.maxX, y: rect.maxY - armLen)
            ),
        ]
    }
}

// MARK: - Currency selector bar

private struct CurrencyBarView: View {
    @ObservedObject var vm: ScannerViewModel
    @Binding var showSource: Bool
    @Binding var showTarget: Bool

    var body: some View {
        HStack(spacing: 16) {
            currencyButton(vm.sourceCurrency.id) { showSource = true }

            Button { vm.swapCurrencies() } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }

            currencyButton(vm.targetCurrency.id) { showTarget = true }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.62)))
    }

    private func currencyButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 78, height: 42)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
        }
    }
}
