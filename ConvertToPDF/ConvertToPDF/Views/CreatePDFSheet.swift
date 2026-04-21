import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct CreatePDFSheet: View {
    var onComplete: (Result<[PDFDocumentItem], Error>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showFileImporter = false
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showURLPrompt = false
    @State private var urlText = ""
    @State private var isProcessing = false
    @State private var photoSelections: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Create PDF from")
                .font(.title3.bold())
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 12)

            sourceRow(icon: "folder.fill", title: "Files", subtitle: "Select files from your device") {
                showFileImporter = true
            }
            sourceRow(icon: "photo.on.rectangle.angled", title: "Gallery", subtitle: "Select photos from gallery") {
                showPhotosPicker = true
            }
            sourceRow(icon: "camera.fill", title: "Camera", subtitle: "Take photos with camera") {
                showCamera = true
            }
            sourceRow(icon: "link", title: "URL Link", subtitle: "Download file from URL") {
                showURLPrompt = true
            }
            sourceRow(icon: "square.grid.3x3.fill", title: "Other Apps", subtitle: "Import from other applications") {
                showFileImporter = true
            }

            Spacer(minLength: 12)
        }
        .overlay {
            if isProcessing {
                ProgressView("Processing…")
                    .padding(24)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $photoSelections,
            maxSelectionCount: 0,
            matching: .images
        )
        .onChange(of: photoSelections) { _, newItems in
            guard !newItems.isEmpty else { return }
            handlePhotoSelections(newItems)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { images in
                handleCapturedImages(images)
            }
        }
        .alert("Download PDF", isPresented: $showURLPrompt) {
            TextField("https://example.com/file.pdf", text: $urlText)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            Button("Cancel", role: .cancel) { urlText = "" }
            Button("Download") { handleURLDownload() }
        } message: {
            Text("Enter the URL of the PDF to import.")
        }
    }

    @ViewBuilder
    private func sourceRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accentSoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Theme.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                isProcessing = true
                defer { isProcessing = false }
                do {
                    var imported: [PDFDocumentItem] = []
                    var images: [UIImage] = []
                    for url in urls {
                        if url.pathExtension.lowercased() == "pdf" {
                            let doc = try PDFManager.importPDF(from: url)
                            imported.append(doc)
                        } else if let img = loadImage(from: url) {
                            images.append(img)
                        }
                    }
                    if !images.isEmpty {
                        let name = "Imported \(Date().formatted(date: .abbreviated, time: .omitted))"
                        let doc = try PDFManager.makePDF(from: images, named: name)
                        imported.append(doc)
                    }
                    if imported.isEmpty {
                        onComplete(.failure(PDFManagerError.emptyInput))
                    } else {
                        onComplete(.success(imported))
                    }
                    dismiss()
                } catch {
                    onComplete(.failure(error))
                    dismiss()
                }
            }
        case .failure(let error):
            onComplete(.failure(error))
            dismiss()
        }
    }

    private func handlePhotoSelections(_ items: [PhotosPickerItem]) {
        Task {
            isProcessing = true
            defer {
                isProcessing = false
                photoSelections = []
            }
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    images.append(img)
                }
            }
            guard !images.isEmpty else {
                onComplete(.failure(PDFManagerError.emptyInput))
                dismiss()
                return
            }
            do {
                let name = "Gallery PDF \(Date().formatted(date: .abbreviated, time: .omitted))"
                let doc = try PDFManager.makePDF(from: images, named: name)
                onComplete(.success([doc]))
                dismiss()
            } catch {
                onComplete(.failure(error))
                dismiss()
            }
        }
    }

    private func handleCapturedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        Task {
            isProcessing = true
            defer { isProcessing = false }
            do {
                let name = "Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
                let doc = try PDFManager.makePDF(from: images, named: name)
                onComplete(.success([doc]))
                dismiss()
            } catch {
                onComplete(.failure(error))
                dismiss()
            }
        }
    }

    private func handleURLDownload() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        urlText = ""
        guard let url = URL(string: trimmed), url.scheme?.hasPrefix("http") == true else {
            onComplete(.failure(PDFManagerError.downloadFailed("Invalid URL")))
            dismiss()
            return
        }
        Task {
            isProcessing = true
            defer { isProcessing = false }
            do {
                let doc = try await PDFManager.downloadPDF(from: url)
                onComplete(.success([doc]))
                dismiss()
            } catch {
                onComplete(.failure(error))
                dismiss()
            }
        }
    }

    private func loadImage(from url: URL) -> UIImage? {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
