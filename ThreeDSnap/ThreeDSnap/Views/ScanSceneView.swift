import SwiftUI
import SceneKit

struct ScanSceneView: UIViewRepresentable {
    enum Perspective { case iso, top }

    let scan: Scan
    let perspective: Perspective

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = UIColor.clear
        view.scene = buildScene()
        configureCamera(in: view)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = buildScene()
        configureCamera(in: uiView)
    }

    private func configureCamera(in view: SCNView) {
        guard let scene = view.scene else { return }
        let bounding = scan.boundingSizeMeters
        let maxDim = max(bounding.width, bounding.height, 4.0)

        let cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true) ?? {
            let n = SCNNode()
            n.name = "camera"
            n.camera = SCNCamera()
            scene.rootNode.addChildNode(n)
            return n
        }()

        switch perspective {
        case .iso:
            cameraNode.position = SCNVector3(maxDim * 0.9, maxDim * 1.1, maxDim * 0.9)
            cameraNode.eulerAngles = SCNVector3(-Float.pi / 4.5, Float.pi / 4, 0)
        case .top:
            cameraNode.position = SCNVector3(0, maxDim * 1.6, 0)
            cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        }
        cameraNode.camera?.fieldOfView = 55
        cameraNode.camera?.zFar = Double(maxDim) * 10
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let bounding = scan.boundingSizeMeters
        let centerX = Float(bounding.width / 2)
        let centerZ = Float(bounding.height / 2)

        let pivot = SCNNode()
        pivot.position = SCNVector3(-centerX, 0, -centerZ)
        scene.rootNode.addChildNode(pivot)

        for room in scan.rooms {
            pivot.addChildNode(buildRoomNode(room: room, unit: scan.lengthUnit))
        }

        let floor = SCNFloor()
        floor.reflectivity = 0.05
        let floorNode = SCNNode(geometry: floor)
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.05)
        floorNode.position = SCNVector3(0, -0.001, 0)
        scene.rootNode.addChildNode(floorNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.7, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let directional = SCNNode()
        directional.light = SCNLight()
        directional.light?.type = .directional
        directional.light?.color = UIColor.white
        directional.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directional)

        return scene
    }

    private func buildRoomNode(room: Room, unit: LengthUnit) -> SCNNode {
        let parent = SCNNode()
        let w = Float(room.size.width)
        let h: Float = 2.6
        let d = Float(room.size.height)
        let originX = Float(room.origin.x)
        let originZ = Float(room.origin.y)

        // Floor
        let floorGeo = SCNBox(width: CGFloat(w), height: 0.02, length: CGFloat(d), chamferRadius: 0)
        floorGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1)
        let floor = SCNNode(geometry: floorGeo)
        floor.position = SCNVector3(originX + w / 2, 0, originZ + d / 2)
        parent.addChildNode(floor)

        // Walls
        let wallThickness: Float = 0.06
        let wallColor = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)

        let walls: [(SCNVector3, SCNVector3)] = [
            // (size, position) — back wall (north, -Z side)
            (SCNVector3(w, h, wallThickness),
             SCNVector3(originX + w / 2, h / 2, originZ)),
            // front wall (+Z side)
            (SCNVector3(w, h, wallThickness),
             SCNVector3(originX + w / 2, h / 2, originZ + d)),
            // left wall (-X side)
            (SCNVector3(wallThickness, h, d),
             SCNVector3(originX, h / 2, originZ + d / 2)),
            // right wall (+X side)
            (SCNVector3(wallThickness, h, d),
             SCNVector3(originX + w, h / 2, originZ + d / 2))
        ]

        for (size, position) in walls {
            let geo = SCNBox(
                width: CGFloat(size.x),
                height: CGFloat(size.y),
                length: CGFloat(size.z),
                chamferRadius: 0
            )
            geo.firstMaterial?.diffuse.contents = wallColor
            let node = SCNNode(geometry: geo)
            node.position = position
            parent.addChildNode(node)
        }

        // Floor label
        let label = SCNText(string: room.name, extrusionDepth: 0.005)
        label.font = UIFont.systemFont(ofSize: 0.5, weight: .semibold)
        label.firstMaterial?.diffuse.contents = UIColor(white: 0.2, alpha: 1)
        label.flatness = 0.05
        let labelNode = SCNNode(geometry: label)
        let (minBox, maxBox) = labelNode.boundingBox
        let labelWidth = maxBox.x - minBox.x
        labelNode.scale = SCNVector3(0.3, 0.3, 0.3)
        labelNode.position = SCNVector3(
            originX + w / 2 - labelWidth * 0.15,
            0.012,
            originZ + d / 2
        )
        labelNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        parent.addChildNode(labelNode)

        return parent
    }
}

#Preview {
    ScanSceneView(scan: ScanStore.preview.scans.first!, perspective: .iso)
        .preferredColorScheme(.dark)
}
