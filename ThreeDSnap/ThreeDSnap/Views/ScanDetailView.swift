import SwiftUI
import SceneKit

struct ScanDetailView: View {
    let scan: Scan
    @EnvironmentObject private var scanStore: ScanStore
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case view, topView, floorPlan
        var id: String { rawValue }
        var label: String {
            switch self {
            case .view: return "View"
            case .topView: return "Top View"
            case .floorPlan: return "Floor Plan"
            }
        }
        var icon: String {
            switch self {
            case .view: return "eye.fill"
            case .topView: return "square.dashed"
            case .floorPlan: return "rectangle.split.3x3.fill"
            }
        }
    }

    @State private var mode: Mode = .view
    @State private var showingDeleteAlert = false
    @State private var showingShare = false
    @State private var showingMeasure = false
    @State private var renamedName: String = ""
    @State private var showingRename = false

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.04), Color.black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                modeBar
                    .padding(.top, 14)
                actionBar
                    .padding(.top, 6)
                    .padding(.bottom, 12)
            }
        }
        .navigationTitle(scan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        renamedName = scan.name
                        showingRename = true
                    }
                    Button("Share", systemImage: "square.and.arrow.up") {
                        showingShare = true
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete scan?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                scanStore.delete(id: scan.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action can't be undone.")
        }
        .alert("Rename scan", isPresented: $showingRename) {
            TextField("Name", text: $renamedName)
            Button("Save") {
                let trimmed = renamedName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    scanStore.rename(id: scan.id, to: trimmed)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingMeasure) {
            MeasureView()
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: [scan.summary, scan.name])
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .view:
            ScanSceneView(scan: scan, perspective: .iso)
        case .topView:
            ScanSceneView(scan: scan, perspective: .top)
        case .floorPlan:
            FloorPlanView(scan: scan)
        }
    }

    private var modeBar: some View {
        HStack(spacing: 16) {
            ForEach(Mode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { mode = item }
                } label: {
                    ZStack {
                        Circle()
                            .fill(mode == item
                                  ? AnyShapeStyle(LinearGradient(colors: [.blue, .indigo],
                                                                  startPoint: .topLeading,
                                                                  endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color.white.opacity(0.08)))
                            .frame(width: 56, height: 56)
                        Image(systemName: item.icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            Button {
                showingMeasure = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)
                    Image(systemName: "ruler.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var actionBar: some View {
        HStack {
            ScanActionButton(title: mode.label, icon: mode.icon, tinted: true) { }
            ScanActionButton(title: "Top View", icon: "square.dashed") { mode = .topView }
            ScanActionButton(title: "Floor Plan", icon: "rectangle.split.3x3.fill") { mode = .floorPlan }
            ScanActionButton(title: "Delete", icon: "trash") { showingDeleteAlert = true }
        }
        .padding(.horizontal, 16)
    }
}

private struct ScanActionButton: View {
    let title: String
    let icon: String
    var tinted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tinted ? .white : .white.opacity(0.85))
                    .frame(width: 44, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(tinted ? Color.blue : Color.white.opacity(0.06))
                    )
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ScanDetailView(scan: ScanStore.preview.scans.first!)
            .environmentObject(ScanStore.preview)
    }
    .preferredColorScheme(.dark)
}
