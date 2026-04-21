import Foundation
import Speech
import AVFoundation

enum TranscriptionError: LocalizedError {
    case unauthorized
    case recognizerUnavailable
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Speech recognition permission was not granted."
        case .recognizerUnavailable: return "Speech recognizer is not available for this language."
        case .recognitionFailed(let message): return message
        }
    }
}

final class TranscriptionService {
    static let shared = TranscriptionService()
    private init() {}

    private final class ContinuationBox: @unchecked Sendable {
        var continuation: CheckedContinuation<String, Error>?
        var task: SFSpeechRecognitionTask?
        private var finished = false
        private let lock = NSLock()

        func finish(_ result: Result<String, Error>) {
            lock.lock()
            defer { lock.unlock() }
            guard !finished, let cont = continuation else { return }
            finished = true
            continuation = nil
            task?.cancel()
            task = nil
            switch result {
            case .success(let value): cont.resume(returning: value)
            case .failure(let error): cont.resume(throwing: error)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func transcribe(url: URL, languageCode: String) async throws -> String {
        let authorized = await requestAuthorization()
        guard authorized else { throw TranscriptionError.unauthorized }

        let locale: Locale
        if languageCode == "auto" {
            locale = Locale.current
        } else {
            locale = Locale(identifier: languageCode)
        }

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        if #available(iOS 13, *) {
            request.requiresOnDeviceRecognition = false
        }

        let box = ContinuationBox()
        return try await withCheckedThrowingContinuation { cont in
            box.continuation = cont
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    box.finish(.failure(TranscriptionError.recognitionFailed(error.localizedDescription)))
                    return
                }
                if let result, result.isFinal {
                    box.finish(.success(result.bestTranscription.formattedString))
                }
            }
            box.task = task
        }
    }
}
