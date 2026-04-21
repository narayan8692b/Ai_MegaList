import SwiftUI

struct DesignResultView: View {
    let design: Design
    @EnvironmentObject private var storage: DesignStorage
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                slider
                metadata

                HStack(spacing: 12) {
                    actionButton(title: "Save", icon: "square.and.arrow.down") {
                        saveToPhotos()
                    }
                    NavigationLink {
                        InteriorDesignView(mode: design.mode, preselectedStyle: design.style)
                    } label: {
                        Label("Reimagine", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    actionButton(title: "Share", icon: "square.and.arrow.up") {
                        showShareSheet = true
                    }
                }
            }
            .padding(Layout.padding)
        }
        .navigationTitle("Design Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        storage.delete(design)
                        dismiss()
                    } label: {
                        Label("Delete Design", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let after = storage.image(named: design.generatedImageFilename) {
                ShareSheet(items: [after])
            }
        }
    }

    private var slider: some View {
        Group {
            if let before = storage.image(named: design.originalImageFilename),
               let after  = storage.image(named: design.generatedImageFilename) {
                BeforeAfterSlider(before: before, after: after)
                    .frame(height: 400)
            } else {
                RoundedRectangle(cornerRadius: Layout.cardRadius)
                    .fill(Color.ruumCard)
                    .frame(height: 400)
                    .overlay(Text("Image unavailable").foregroundColor(.secondary))
            }
        }
    }

    private var metadata: some View {
        HStack(spacing: 12) {
            tagChip(icon: design.room.sfSymbol, label: design.room.name)
            tagChip(icon: "paintpalette", label: design.style.name)
            tagChip(icon: design.mode.sfSymbol, label: design.mode.title)
        }
    }

    private func tagChip(icon: String, label: String) -> some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.ruumCard, in: Capsule())
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.bordered)
        .tint(.ruumTeal)
    }

    private func saveToPhotos() {
        guard let img = storage.image(named: design.generatedImageFilename) else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
