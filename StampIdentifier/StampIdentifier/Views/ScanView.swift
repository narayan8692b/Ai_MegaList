import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var stampStore:   StampStore
    @EnvironmentObject private var antiqueStore: AntiqueStore
    @EnvironmentObject private var jewelryStore: JewelryStore
    @EnvironmentObject private var coinStore:    CoinStore

    @AppStorage("selectedMode") private var storedMode: String = CollectibleMode.stamp.rawValue
    @AppStorage("preferredLanguageCode") private var languageCode: String = "EN"

    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isCameraPresented = false
    @State private var isIdentifying = false

    @State private var identifiedStamp:   Stamp?
    @State private var identifiedAntique: Antique?
    @State private var identifiedJewelry: Jewelry?
    @State private var identifiedCoin:    Coin?

    @State private var errorMessage: String?
    @State private var showLanguagePicker = false

    private let stampIdentifier:   StampIdentifying   = MockStampIdentificationService()
    private let antiqueIdentifier: AntiqueIdentifying = MockAntiqueIdentificationService()
    private let jewelryIdentifier: JewelryIdentifying = MockJewelryIdentificationService()
    private let coinIdentifier:    CoinIdentifying    = MockCoinIdentificationService()

    private var mode: CollectibleMode {
        CollectibleMode(rawValue: storedMode) ?? .stamp
    }

    var body: some View {
        NavigationStack {
            ZStack {
                mode.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        modeRow
                        header
                        scannerCard
                        actionButtons
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        tipsSection
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(mode == .coin ? .dark : .light, for: .navigationBar)
            .onChange(of: pickerItem) { _, newValue in
                Task { await loadPickedImage(newValue) }
            }
            .onChange(of: storedMode) { _, _ in
                capturedImage = nil
                errorMessage = nil
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraPicker { image in
                    capturedImage = image
                    Task { await identify(image: image) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView()
            }
            .navigationDestination(item: $identifiedStamp) { stamp in
                StampDetailView(stamp: stamp, showsAddButton: true)
            }
            .navigationDestination(item: $identifiedAntique) { antique in
                AntiqueDetailView(antique: antique, showsAddButton: true)
            }
            .navigationDestination(item: $identifiedJewelry) { piece in
                JewelryDetailView(piece: piece, showsAddButton: true)
            }
            .navigationDestination(item: $identifiedCoin) { coin in
                CoinDetailView(coin: coin, showsAddButton: true)
            }
        }
    }

    // MARK: Subviews

    private var navTitle: String {
        switch mode {
        case .stamp:   return "Stamp Identifier"
        case .antique: return "Antique Identifier"
        case .jewelry: return "Jewelry Identifier"
        case .coin:    return "Coin Identifier"
        }
    }

    private var primaryTitle: String {
        switch mode {
        case .stamp:   return "Scan & Identify Any Stamp"
        case .antique: return "Accurate Antique Scanner"
        case .jewelry: return "Instant Jewelry Appraisal"
        case .coin:    return "Accurate Coin Scanner"
        }
    }

    private var primarySubtitle: String {
        switch mode {
        case .stamp:   return "Point your camera at a stamp or pick one from your library."
        case .antique: return "Scan any antique, vintage, or collectible item for an instant appraisal."
        case .jewelry: return "Discover hidden value — get an estimate, materials breakdown, and eBay fair-price check."
        case .coin:    return "Identify any coin — US, foreign, ancient, or commemorative."
        }
    }

    private var modeRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("Mode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showLanguagePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(SupportedLanguage.named(languageCode).flag)
                        Text(languageCode)
                            .font(.caption.weight(.bold))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                    )
                    .foregroundStyle(Color.brandInk)
                }
            }
            .padding(.horizontal)

            ModeChipPicker(selection: $storedMode)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(primaryTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(mode == .coin ? .white : Color.brandInk)
            Text(primarySubtitle)
                .font(.subheadline)
                .foregroundStyle(mode == .coin ? Color.white.opacity(0.7) : .secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private var scannerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(mode == .coin ? Color.white.opacity(0.06) : Color.white)
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)

            if let image = capturedImage {
                Image(uiImage: image).resizable().scaledToFit().padding(28)
            } else {
                ScannerFrame(color: mode.accentColor)
                    .overlay {
                        Image(systemName: scannerIcon)
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(mode.accentColor.opacity(0.85))
                    }
                    .padding(28)
            }

            if isIdentifying {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                VStack(spacing: 12) {
                    ProgressView().tint(.white).scaleEffect(1.3)
                    Text("Identifying \(mode.singular.lowercased())…")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }
        }
        .frame(height: 360)
        .padding(.horizontal)
    }

    private var scannerIcon: String {
        switch mode {
        case .stamp:   return "camera.viewfinder"
        case .antique: return "sparkles.tv"
        case .jewelry: return "sparkles"
        case .coin:    return "dollarsign.circle"
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                isCameraPresented = true
            } label: {
                Label("Scan with Camera", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(mode.accentColor)
            .controlSize(.large)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(mode.accentColor)
            .controlSize(.large)
        }
        .padding(.horizontal)
        .disabled(isIdentifying)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tips for accurate results")
                .font(.headline)
                .foregroundStyle(mode == .coin ? .white : Color.brandInk)
            tip(tip1)
            tip(tip2)
            tip("Avoid glare — natural daylight works best.")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(mode == .coin ? Color.white.opacity(0.08) : Color.white.opacity(0.85))
        )
        .padding(.horizontal)
    }

    private var tip1: String {
        switch mode {
        case .stamp:   return "Place the stamp on a plain, well-lit surface."
        case .antique: return "Photograph the antique against a neutral backdrop."
        case .jewelry: return "Capture hallmarks and stone details close-up."
        case .coin:    return "Photograph the obverse face with crisp focus."
        }
    }

    private var tip2: String {
        switch mode {
        case .stamp:   return "Fill the frame, keeping the stamp parallel to the camera."
        case .antique: return "Capture key details: marks, signatures, construction."
        case .jewelry: return "Include metal stamp, prong / bezel detail, and the full piece."
        case .coin:    return "Try to include both obverse and reverse if possible."
        }
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(mode.accentColor)
            Text(text)
                .foregroundStyle(mode == .coin ? Color.white.opacity(0.8) : .secondary)
        }
        .font(.subheadline)
    }

    // MARK: Logic

    private func loadPickedImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                capturedImage = image
                await identify(image: image)
            }
        } catch {
            errorMessage = "Could not load the selected image."
        }
    }

    private func identify(image: UIImage) async {
        errorMessage = nil
        isIdentifying = true
        defer { isIdentifying = false }
        do {
            switch mode {
            case .stamp:
                identifiedStamp = try await stampIdentifier.identify(image: image)
            case .antique:
                identifiedAntique = try await antiqueIdentifier.identify(image: image)
            case .jewelry:
                identifiedJewelry = try await jewelryIdentifier.identify(image: image)
            case .coin:
                identifiedCoin = try await coinIdentifier.identify(image: image)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ScannerFrame: View {
    var color: Color = .brandOrange

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let corner: CGFloat = 34
            let thickness: CGFloat = 5

            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: corner))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: corner, y: 0))
                }.stroke(color, style: .init(lineWidth: thickness, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: w - corner, y: 0))
                    p.addLine(to: CGPoint(x: w, y: 0))
                    p.addLine(to: CGPoint(x: w, y: corner))
                }.stroke(color, style: .init(lineWidth: thickness, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - corner))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: corner, y: h))
                }.stroke(color, style: .init(lineWidth: thickness, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: w - corner, y: h))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: w, y: h - corner))
                }.stroke(color, style: .init(lineWidth: thickness, lineCap: .round))
            }
        }
    }
}

#Preview {
    ScanView()
        .environmentObject(StampStore())
        .environmentObject(AntiqueStore())
        .environmentObject(JewelryStore())
        .environmentObject(CoinStore())
}
