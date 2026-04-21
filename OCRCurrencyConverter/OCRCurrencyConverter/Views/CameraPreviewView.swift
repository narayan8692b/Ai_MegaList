import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> _PreviewView {
        let view = _PreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: _PreviewView, context: Context) {}
}

final class _PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    var session: AVCaptureSession? {
        didSet {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
