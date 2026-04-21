import SwiftUI

struct ScannerView: View {

    @StateObject private var vm = ScannerViewModel()
    @EnvironmentObject private var exchangeService: ExchangeRateService
    @State private var showSource = false
    @State private var showTarget = false

    private let frameSize = CGSize(width: 280, height: 120)

    private var convertedPrice: Double? {
        guard let p = vm.detectedPrice else { return nil }
        return exchangeService.convert(amount: p, from: vm.sourceCurrencyId, to: vm.targetCurrencyId)
    }

    var body: some View {
        GeometryReader { geo in
            let holeOrigin = CGPoint(
                x: (geo.size.width - frameSize.width) / 2,
                y: geo.size.height * 0.38
            )
            let holeRect = CGRect(origin: holeOrigin, size: frameSize)

            ZStack {
                CameraPreviewView(session: vm.captureSession)
                    .ignoresSafeArea()

                ScannerDimOverlay(holeRect: holeRect, cornerRadius: 14)
                    .fill(Color.black.opacity(0.48), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScannerFrameView(rect: holeRect)
                    .allowsHitTesting(false)

                if let detected = vm.detectedPrice, let converted = convertedPrice {
                    Text(
                        "\(String(format: "%.2f", detected)) \(vm.sourceCurrency.symbol)"
                        + "  =  "
                        + "\(String(format: "%.2f", converted)) \(vm.targetCurrency.symbol)"
                    )
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Color.black.opacity(0.72)))
                    .position(x: geo.size.width / 2,
                              y: holeOrigin.y + frameSize.height + 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.easeInOut(duration: 0.2), value: detected)
                }

                VStack {
                    Spacer()
                    CurrencyBarView(vm: vm, showSource: $showSource, showTarget: $showTarget)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 12)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear  { vm.startSession() }
        .onDisappear { vm.stopSession() }
        .sheet(isPresented: $showSource) {
            CurrencySelectorView(
                mode: .singleSelect(
                    current: vm.sourceCurrencyId,
                    onSelect: { vm.sourceCurrencyId = $0.id }
                )
            )
        }
        .sheet(isPresented: $showTarget) {
            CurrencySelectorView(
                mode: .singleSelect(
                    current: vm.targetCurrencyId,
                    onSelect: { vm.targetCurrencyId = $0.id }
                )
            )
        }
    }
}

// MARK: - Dimmed overlay with even-odd hole

private struct ScannerDimOverlay: Shape {
    let holeRect: CGRect
    let cornerRadius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addPath(Path(roundedRect: holeRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius)))
        return p
    }
}

// MARK: - Corner bracket frame

private struct ScannerFrameView: View {
    let rect: CGRect
    private let arm: CGFloat = 24
    private let lw:  CGFloat = 3

    var body: some View {
        Canvas { ctx, _ in
            let blue  = GraphicsContext.Shading.color(Color.blue)
            let bstyle = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)

            ctx.stroke(
                Path(roundedRect: rect, cornerSize: CGSize(width: 14, height: 14)),
                with: .color(.white.opacity(0.2)),
                style: StrokeStyle(lineWidth: 1)
            )
            for corner in corners() {
                var p = Path()
                p.move(to: corner.hEnd)
                p.addLine(to: corner.apex)
                p.addLine(to: corner.vEnd)
                ctx.stroke(p, with: blue, style: bstyle)
            }
        }
    }

    private struct C { let apex, hEnd, vEnd: CGPoint }

    private func corners() -> [C] {[
        C(apex: CGPoint(x: rect.minX, y: rect.minY),
          hEnd: CGPoint(x: rect.minX + arm, y: rect.minY),
          vEnd: CGPoint(x: rect.minX, y: rect.minY + arm)),
        C(apex: CGPoint(x: rect.maxX, y: rect.minY),
          hEnd: CGPoint(x: rect.maxX - arm, y: rect.minY),
          vEnd: CGPoint(x: rect.maxX, y: rect.minY + arm)),
        C(apex: CGPoint(x: rect.minX, y: rect.maxY),
          hEnd: CGPoint(x: rect.minX + arm, y: rect.maxY),
          vEnd: CGPoint(x: rect.minX, y: rect.maxY - arm)),
        C(apex: CGPoint(x: rect.maxX, y: rect.maxY),
          hEnd: CGPoint(x: rect.maxX - arm, y: rect.maxY),
          vEnd: CGPoint(x: rect.maxX, y: rect.maxY - arm)),
    ]}
}

// MARK: - Bottom currency bar

private struct CurrencyBarView: View {
    @ObservedObject var vm: ScannerViewModel
    @Binding var showSource: Bool
    @Binding var showTarget: Bool

    var body: some View {
        HStack(spacing: 16) {
            currencyButton(vm.sourceCurrency) { showSource = true }
            Button { vm.swapCurrencies() } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            currencyButton(vm.targetCurrency) { showTarget = true }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.62)))
    }

    private func currencyButton(_ currency: Currency, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(currency.flag).font(.system(size: 18))
                Text(currency.id).font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(minWidth: 80, minHeight: 42)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
        }
    }
}
