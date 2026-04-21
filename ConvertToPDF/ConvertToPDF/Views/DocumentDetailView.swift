import SwiftUI
import PDFKit

struct DocumentDetailView: View {
    @EnvironmentObject var store: DocumentStore
    @Environment(\.dismiss) private var dismiss

    @State var document: PDFDocumentItem
    @State private var showOptions = false
    @State private var showRename = false
    @State private var showSetPassword = false
    @State private var showShare = false
    @State private var showDeleteConfirm = false
    @State private var showManagePages = false
    @State private var unlockPassword = ""
    @State private var needsUnlock = false
    @State private var pdfRefreshToken = UUID()

    var body: some View {
        PDFViewerContainer(url: document.fileURL, password: unlockPassword, refreshToken: pdfRefreshToken) { pdf in
            if pdf.isLocked && unlockPassword.isEmpty {
                needsUnlock = true
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
            }
        }
        .navigationDestination(isPresented: $showManagePages) {
            ManagePagesView(document: $document) {
                pdfRefreshToken = UUID()
            }
        }
        .sheet(isPresented: $showOptions) {
            DocumentOptionsSheet(
                document: document,
                onRename: { dismissOptionsThen { showRename = true } },
                onManagePages: { dismissOptionsThen { showManagePages = true } },
                onShare: { dismissOptionsThen { showShare = true } },
                onSetPassword: { dismissOptionsThen { showSetPassword = true } },
                onDelete: { dismissOptionsThen { showDeleteConfirm = true } }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRename) {
            RenameDocumentView(currentName: document.name) { newName in
                document.name = newName
                store.rename(document, to: newName)
            }
            .presentationDetents([.height(240)])
        }
        .sheet(isPresented: $showSetPassword) {
            SetPasswordView(document: document) { updated in
                document = updated
                store.update(updated)
                pdfRefreshToken = UUID()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [document.fileURL])
        }
        .alert("Delete document", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.delete(document)
                dismiss()
            }
        } message: {
            Text("This will permanently remove \"\(document.name)\".")
        }
        .alert("Unlock PDF", isPresented: $needsUnlock) {
            SecureField("Password", text: $unlockPassword)
            Button("Cancel", role: .cancel) { dismiss() }
            Button("Unlock") { pdfRefreshToken = UUID() }
        } message: {
            Text("This document is password protected.")
        }
    }

    private func dismissOptionsThen(_ action: @escaping () -> Void) {
        showOptions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            action()
        }
    }
}

struct PDFViewerContainer: UIViewRepresentable {
    let url: URL
    let password: String
    let refreshToken: UUID
    var onLoad: ((PDFDocument) -> Void)?

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor.secondarySystemBackground
        load(into: view)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        load(into: uiView)
    }

    private func load(into view: PDFView) {
        guard let doc = PDFDocument(url: url) else { return }
        if doc.isLocked, !password.isEmpty {
            _ = doc.unlock(withPassword: password)
        }
        view.document = doc
        onLoad?(doc)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
