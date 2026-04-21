import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var store: StampStore

    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isCameraPresented = false
    @State private var isIdentifying = false
    @State private var identifiedStamp: Stamp?
    @State private var errorMessage: String?

    private let identifier: StampIdentifying = MockStampIdentificationService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
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
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Stamp Identifier")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: pickerItem) { _, newValue in
                Task { await loadPickedImage(newValue) }
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraPicker { image in
                    capturedImage = image
                    Task { await identify(image: image) }
                }
                .ignoresSafeArea()
            }
            .navigationDestination(item: $identifiedStamp) { stamp in
                StampDetailView(stamp: stamp, showsAddButton: true)
            }
        }
    }

    // MARK: Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Text("Scan & Identify Any Stamp")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.brandInk)
            Text("Point your camera at a stamp or pick one from your library.")
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
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(28)
            } else {
                ScannerFrame()
                    .overlay {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(Color.brandOrange.opacity(0.75))
                    }
                    .padding(28)
            }

            if isIdentifying {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                    Text("Identifying stamp…")
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
            .tint(Color.brandOrange)
            .controlSize(.large)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(Color.brandOrange)
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
            tip("Place the stamp on a plain, well-lit surface.")
            tip("Fill the frame, keeping the stamp parallel to the camera.")
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
                .foregroundStyle(Color.brandOrange)
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
            let stamp = try await identifier.identify(image: image)
            identifiedStamp = stamp
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ScannerFrame: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let corner: CGFloat = 34
            let thickness: CGFloat = 5
            let color = Color.brandOrange

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
    ScanView().environmentObject(StampStore())
}
