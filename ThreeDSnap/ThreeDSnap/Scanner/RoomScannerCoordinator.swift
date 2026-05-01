import Foundation
import SwiftUI
#if canImport(RoomPlan)
import RoomPlan
#endif
#if canImport(ARKit)
import ARKit
#endif

enum RoomScannerCoordinator {
    static var isSupported: Bool {
        #if canImport(RoomPlan) && !targetEnvironment(simulator)
        if #available(iOS 16.0, *) {
            return RoomCaptureSession.isSupported
        }
        return false
        #else
        return false
        #endif
    }
}

#if canImport(RoomPlan)
@available(iOS 16.0, *)
final class RoomCaptureController: NSObject, ObservableObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    @Published var hasFinished = false
    var onFinish: (CapturedRoom) -> Void = { _ in }
    var onError: (Error) -> Void = { _ in }
    weak var captureView: RoomCaptureView?

    func start() {
        let config = RoomCaptureSession.Configuration()
        captureView?.captureSession.run(configuration: config)
    }

    func stop() {
        captureView?.captureSession.stop()
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData,
                     error: Error?) -> Bool {
        return error == nil
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        hasFinished = true
        if let error {
            onError(error)
        } else {
            onFinish(processedResult)
        }
    }

    func captureSession(_ session: RoomCaptureSession,
                        didEndWith data: CapturedRoomData,
                        error: Error?) {
        if let error { onError(error) }
    }
}

@available(iOS 16.0, *)
struct RoomScannerRepresentable: UIViewRepresentable {
    @ObservedObject var controller: RoomCaptureController

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.delegate = controller
        view.captureSession.delegate = controller
        controller.captureView = view
        controller.start()
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: ()) {
        uiView.captureSession.stop()
    }
}

@available(iOS 16.0, *)
extension Scan {
    init(from captured: CapturedRoom, name: String, lengthUnit: LengthUnit) {
        // Derive a single room footprint by taking the bounding box of
        // every wall position (works on iOS 16+ where `floors` may not
        // be available).
        var minX = Double.greatestFiniteMagnitude
        var minZ = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxZ = -Double.greatestFiniteMagnitude

        for wall in captured.walls {
            let t = wall.transform
            let x = Double(t.columns.3.x)
            let z = Double(t.columns.3.z)
            let dim = wall.dimensions
            let halfW = Double(dim.x) / 2
            minX = min(minX, x - halfW)
            maxX = max(maxX, x + halfW)
            minZ = min(minZ, z - halfW)
            maxZ = max(maxZ, z + halfW)
        }

        let rooms: [Room]
        if minX < .greatestFiniteMagnitude {
            rooms = [Room(
                name: "Room 1",
                origin: CGPoint(x: minX, y: minZ),
                size: CGSize(width: maxX - minX, height: maxZ - minZ)
            )]
        } else {
            rooms = [Room(
                name: "Room 1",
                origin: .zero,
                size: CGSize(width: 4.0, height: 3.5)
            )]
        }

        self.init(name: name, rooms: rooms, lengthUnit: lengthUnit)
    }
}
#endif
