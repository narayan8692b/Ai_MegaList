import Foundation
import AVFoundation
import Combine

final class ScannerViewModel: NSObject, ObservableObject {

    @Published var detectedPrice: Double?
    @Published var isScanning = true

    // Persisted across launches
    @Published var sourceCurrencyId: String {
        didSet { UserDefaults.standard.set(sourceCurrencyId, forKey: "scannerSource") }
    }
    @Published var targetCurrencyId: String {
        didSet { UserDefaults.standard.set(targetCurrencyId, forKey: "scannerTarget") }
    }

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ocrService = OCRService()
    private var processingFrame = false

    override init() {
        sourceCurrencyId = UserDefaults.standard.string(forKey: "scannerSource") ?? "EUR"
        targetCurrencyId = UserDefaults.standard.string(forKey: "scannerTarget") ?? "USD"
        super.init()
        setupCamera()
    }

    var sourceCurrency: Currency { Currency.find(by: sourceCurrencyId) }
    var targetCurrency: Currency { Currency.find(by: targetCurrencyId) }

    func swapCurrencies() {
        let tmp = sourceCurrencyId
        sourceCurrencyId = targetCurrencyId
        targetCurrencyId = tmp
    }

    func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    private func setupCamera() {
        captureSession.sessionPreset = .hd1280x720
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input  = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else { return }
        captureSession.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ocr.queue", qos: .userInitiated))
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
    }
}

extension ScannerViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard isScanning, !processingFrame,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processingFrame = true
        ocrService.detectPrice(in: pixelBuffer) { [weak self] price in
            guard let self else { return }
            if let price { self.detectedPrice = price }
            self.processingFrame = false
        }
    }
}
