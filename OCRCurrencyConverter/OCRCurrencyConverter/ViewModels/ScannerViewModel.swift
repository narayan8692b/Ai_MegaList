import Foundation
import AVFoundation
import Combine

final class ScannerViewModel: NSObject, ObservableObject {

    // MARK: - Published state

    @Published var detectedPrice: Double?
    @Published var convertedPrice: Double?
    @Published var sourceCurrency: Currency = Currency.find(by: "EUR")
    @Published var targetCurrency: Currency = Currency.find(by: "USD")
    @Published var isScanning = true

    // MARK: - Camera

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    // MARK: - Services

    let exchangeService = ExchangeRateService()
    private let ocrService = OCRService()

    private var processingFrame = false
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupCamera()

        exchangeService.$rates
            .sink { [weak self] _ in self?.recalculate() }
            .store(in: &cancellables)
    }

    // MARK: - Session control

    func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    // MARK: - Currency actions

    func swapCurrencies() {
        let tmp = sourceCurrency
        sourceCurrency = targetCurrency
        targetCurrency = tmp
        recalculate()
    }

    func recalculate() {
        guard let price = detectedPrice else { convertedPrice = nil; return }
        convertedPrice = exchangeService.convert(amount: price,
                                                 from: sourceCurrency.id,
                                                 to: targetCurrency.id)
    }

    // MARK: - Private setup

    private func setupCamera() {
        captureSession.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else { return }

        captureSession.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ocr.queue", qos: .userInitiated))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ScannerViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard isScanning, !processingFrame,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        processingFrame = true
        ocrService.detectPrice(in: pixelBuffer) { [weak self] price in
            guard let self else { return }
            if let price {
                self.detectedPrice = price
                self.recalculate()
            }
            self.processingFrame = false
        }
    }
}
