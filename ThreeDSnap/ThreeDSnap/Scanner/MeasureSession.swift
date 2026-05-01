import Foundation
#if canImport(ARKit)
import ARKit
#endif
#if canImport(SceneKit)
import SceneKit
#endif

enum MeasureSession {
    static var isSupported: Bool {
        #if canImport(ARKit) && !targetEnvironment(simulator)
        return ARWorldTrackingConfiguration.isSupported
        #else
        return false
        #endif
    }
}

#if canImport(ARKit) && canImport(SceneKit)
import SwiftUI

final class MeasureCoordinator: NSObject, ObservableObject, ARSCNViewDelegate {
    @Published var distanceMeters: Double?
    @Published var statusMessage: String = "Tap to place the first point"

    weak var sceneView: ARSCNView?
    private var anchors: [SCNNode] = []
    private var lineNode: SCNNode?

    func setSceneView(_ view: ARSCNView) {
        self.sceneView = view
        view.delegate = self
        view.automaticallyUpdatesLighting = true
        view.scene = SCNScene()
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        view.session.run(config)
    }

    func handleTap(_ point: CGPoint) {
        guard let sceneView else { return }
        let hits: [ARRaycastResult]
        if let query = sceneView.raycastQuery(from: point,
                                              allowing: .estimatedPlane,
                                              alignment: .any) {
            hits = sceneView.session.raycast(query)
        } else {
            hits = []
        }
        guard let hit = hits.first else {
            statusMessage = "Move closer to a surface and try again"
            return
        }
        let position = SCNVector3(
            hit.worldTransform.columns.3.x,
            hit.worldTransform.columns.3.y,
            hit.worldTransform.columns.3.z
        )
        addAnchor(at: position)
    }

    func reset() {
        for node in anchors { node.removeFromParentNode() }
        anchors.removeAll()
        lineNode?.removeFromParentNode()
        lineNode = nil
        distanceMeters = nil
        statusMessage = "Tap to place the first point"
    }

    private func addAnchor(at position: SCNVector3) {
        guard let sceneView else { return }

        if anchors.count >= 2 {
            reset()
        }

        let sphere = SCNSphere(radius: 0.012)
        sphere.firstMaterial?.diffuse.contents = UIColor.systemBlue
        sphere.firstMaterial?.emission.contents = UIColor.systemBlue.withAlphaComponent(0.4)
        let node = SCNNode(geometry: sphere)
        node.position = position
        sceneView.scene.rootNode.addChildNode(node)
        anchors.append(node)

        if anchors.count == 1 {
            statusMessage = "Tap to place the second point"
        } else if anchors.count == 2 {
            let a = anchors[0].position
            let b = anchors[1].position
            let dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z
            let distance = sqrt(dx * dx + dy * dy + dz * dz)
            distanceMeters = Double(distance)
            statusMessage = ""

            let line = lineGeometry(from: a, to: b)
            lineNode?.removeFromParentNode()
            let n = SCNNode(geometry: line)
            sceneView.scene.rootNode.addChildNode(n)
            lineNode = n
        }
    }

    private func lineGeometry(from a: SCNVector3, to b: SCNVector3) -> SCNGeometry {
        let source = SCNGeometrySource(vertices: [a, b])
        let indices: [Int32] = [0, 1]
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let g = SCNGeometry(sources: [source], elements: [element])
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.systemBlue
        m.emission.contents = UIColor.systemBlue
        g.materials = [m]
        return g
    }
}

struct MeasureARViewRepresentable: UIViewRepresentable {
    @ObservedObject var coordinator: MeasureCoordinator

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        coordinator.setSceneView(view)
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(TapTarget.didTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.tapHandler = { [weak coordinator] location in
            coordinator?.handleTap(location)
        }
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: TapTarget) {
        uiView.session.pause()
    }

    func makeCoordinator() -> TapTarget { TapTarget() }

    final class TapTarget: NSObject {
        var tapHandler: ((CGPoint) -> Void)?
        @objc func didTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let point = gesture.location(in: view)
            tapHandler?(point)
        }
    }
}
#endif
