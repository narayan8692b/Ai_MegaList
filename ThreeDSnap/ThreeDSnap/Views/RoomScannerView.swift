import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
#endif

struct RoomScannerView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @Environment(\.dismiss) private var dismiss

    @State private var capturedScan: Scan?
    @State private var errorMessage: String?
    @State private var showSaveSheet = false

    #if canImport(RoomPlan)
    @StateObject private var controller: AnyRoomCaptureController = AnyRoomCaptureController()
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if RoomScannerCoordinator.isSupported {
                #if canImport(RoomPlan)
                if #available(iOS 16.0, *), let inner = controller.inner {
                    RoomScannerRepresentable(controller: inner)
                        .ignoresSafeArea()
                        .onAppear {
                            inner.onFinish = handleCaptured
                            inner.onError = handleError
                        }
                } else {
                    unsupportedPlaceholder
                }
                #else
                unsupportedPlaceholder
                #endif
            } else {
                unsupportedPlaceholder
            }

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .alert("Scan Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil; dismiss() }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showSaveSheet) {
            if let scan = capturedScan {
                SaveScanSheet(scan: scan) { final in
                    scanStore.add(final)
                    dismiss()
                } onDiscard: {
                    capturedScan = nil
                    dismiss()
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Text("Room Scan")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Text("Walk slowly around the room and aim the camera at every wall.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                #if canImport(RoomPlan)
                if #available(iOS 16.0, *) { controller.inner?.stop() }
                #endif
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Done Scanning")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var unsupportedPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow)
            Text("LiDAR Required")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Room scanning needs an iPhone Pro or iPad Pro with a LiDAR sensor.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 32)
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
    }

    #if canImport(RoomPlan)
    @available(iOS 16.0, *)
    private func handleCaptured(_ captured: CapturedRoom?) {
        guard let captured else { return }
        let dateString = Date.now.formatted(.dateTime.month(.abbreviated).day().year())
        let name = "\(dateString), File \(scanStore.scans.count + 1)"
        let scan = Scan(from: captured, name: name, lengthUnit: .feet)
        capturedScan = scan
        showSaveSheet = true
    }
    #endif

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

private struct SaveScanSheet: View {
    @State var scan: Scan
    var onSave: (Scan) -> Void
    var onDiscard: () -> Void
    @State private var name: String = ""
    @State private var lengthUnit: LengthUnit = .feet

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Scan name", text: $name)
                }
                Section("Units") {
                    Picker("Length unit", selection: $lengthUnit) {
                        ForEach(LengthUnit.allCases, id: \.self) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Detected") {
                    LabeledContent("Rooms", value: "\(scan.rooms.count)")
                    LabeledContent("Total area",
                                   value: MeasurementFormatter.formatArea(scan.totalAreaSquareMeters,
                                                                           unit: lengthUnit))
                }
            }
            .navigationTitle("Save Scan")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { name = scan.name; lengthUnit = scan.lengthUnit }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Discard", role: .destructive) { onDiscard() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var s = scan
                        s.name = name.isEmpty ? scan.name : name
                        s.lengthUnit = lengthUnit
                        onSave(s)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#if canImport(RoomPlan)
final class AnyRoomCaptureController: ObservableObject {
    private var _inner: Any?

    var inner: RoomCaptureController? {
        if #available(iOS 16.0, *) {
            if let existing = _inner as? RoomCaptureController { return existing }
            let made = RoomCaptureController()
            _inner = made
            return made
        }
        return nil
    }
}
#endif

#Preview {
    RoomScannerView()
        .environmentObject(ScanStore())
}
