import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var stampStore: StampStore
    @EnvironmentObject private var antiqueStore: AntiqueStore
    @AppStorage("selectedMode") private var storedMode: String = CollectibleMode.stamp.rawValue
    @AppStorage("preferredLanguageCode") private var languageCode: String = "EN"

    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isCameraPresented = false
    @State private var isIdentifying = false
    @State private var identifiedStamp: Stamp?
    @State private var identifiedAntique: Antique?
    @State private var errorMessage: String?
    @State private var showLanguagePicker = false

    private let stampIdentifier: StampIdentifying = MockStampIdentificationService()
    private let antiqueIdentifier: AntiqueIdentifying = MockAntiqueIdentificationService()

    private var mode: CollectibleMode {
        get { CollectibleMode(rawValue: storedMode) ?? .stamp }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        modeAndLanguageBar
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
        }
    }

    // MARK: Subviews

    private var backgroundColor: Color {
        mode == .stamp ? .brandCream : .antiqueCream
    }

    private var navTitle: String {
        mode == .stamp ? "Stamp Identifier" : "Antique Identifier"
    }

    private var modeAndLanguageBar: some View {
        HStack(spacing: 10) {
            Picker("Mode", selection: $storedMode) {
                ForEach(CollectibleMode.allCases) { m in
                    Text(m.rawValue).tag(m.rawValue)
                }
            }
            .pickerStyle(.segmented)

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
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(mode == .stamp ? "Scan & Identify Any Stamp" : "Accurate Antique Scanner")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.brandInk)
            Text(mode == .stamp
                 ? "Point your camera at a stamp or pick one from your library."
                 : "Scan any antique, vintage, or collectible item for an instant appraisal.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private var scannerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)

            if let image = capturedImage {
                Image(uiImage: image).resizable().scaledToFit().padding(28)
            } else {
                ScannerFrame(color: mode.accentColor)
                    .overlay {
                        Image(systemName: mode == .stamp ? "camera.viewfinder" : "sparkles.tv")
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(mode.accentColor.opacity(0.75))
                    }
                    .padding(28)
            }

            if isIdentifying {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                VStack(spacing: 12) {
                    ProgressView().tint(.white).scaleEffect(1.3)
                    Text(mode == .stamp ? "Identifying stamp…" : "Identifying antique…")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }
        }
        .frame(height: 360)
        .padding(.horizontal)
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
                .foregroundStyle(Color.brandInk)
            tip(mode == .stamp
                ? "Place the stamp on a plain, well-lit surface."
                : "Photograph the antique against a neutral backdrop.")
            tip(mode == .stamp
                ? "Fill the frame, keeping the stamp parallel to the camera."
                : "Capture key details: marks, signatures, construction.")
            tip("Avoid glare — natural daylight works best.")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .padding(.horizontal)
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(mode.accentColor)
            Text(text)
                .foregroundStyle(.secondary)
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
}
