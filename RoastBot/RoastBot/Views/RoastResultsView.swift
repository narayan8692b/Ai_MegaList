import SwiftUI

struct RoastResultsView: View {
    let results: [RoastResult]
    let image: UIImage

    @State private var copiedID: UUID?
    @State private var shareItem: RoastResult?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // Header card
                    HStack(spacing: 14) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.orange, lineWidth: 2))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("PHOTO")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                            if let first = results.first {
                                Text("\(first.style.rawValue) • \(first.intensity)%")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Text("Tap a roast to copy it")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ForEach(results) { result in
                        RoastCard(result: result, isCopied: copiedID == result.id) {
                            UIPasteboard.general.string = result.text
                            copiedID = result.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if copiedID == result.id { copiedID = nil }
                            }
                        } onShare: {
                            shareItem = result
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Your Roasts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .sheet(item: $shareItem) { result in
            ShareSheet(item: result, image: image)
        }
    }
}

// MARK: - Roast card

private struct RoastCard: View {
    let result: RoastResult
    let isCopied: Bool
    let onCopy: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(result.text)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture(perform: onCopy)

            HStack {
                Spacer()
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCopied ? Color.green : Color.white.opacity(0.12))
                )
        )
        .overlay(alignment: .topTrailing) {
            if isCopied {
                Label("Copied", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isCopied)
        .padding(.horizontal)
    }
}

// MARK: - Share sheet

struct ShareSheet: View {
    let item: RoastResult
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.05).ignoresSafeArea()

                VStack(spacing: 20) {
                    // Shareable card preview
                    ShareableCard(roast: item.text, image: image)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 20)
                        .padding(.horizontal, 20)

                    Button {
                        shareCard()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Share Roast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func shareCard() {
        let renderer = ImageRenderer(content:
            ShareableCard(roast: item.text, image: image)
                .frame(width: 380)
        )
        renderer.scale = 3
        guard let img = renderer.uiImage else { return }

        let av = UIActivityViewController(activityItems: [img, item.text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}

struct ShareableCard: View {
    let roast: String
    let image: UIImage

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()

            ZStack(alignment: .bottomLeading) {
                Color(red: 0.1, green: 0.05, blue: 0.0)

                VStack(alignment: .leading, spacing: 10) {
                    Text(roast)
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding()

                    HStack {
                        Spacer()
                        Label("Roast Bot", systemImage: "flame.fill")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .padding(.trailing, 12)
                            .padding(.bottom, 10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
