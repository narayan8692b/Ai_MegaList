package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.model.OcrResult
import com.docscanner.shared.domain.util.DataResult

/**
 * Shared OCR abstraction. Backed by Google ML Kit Text Recognition on Android and the
 * Apple Vision framework (VNRecognizeTextRequest) on iOS.
 */
interface OcrEngine {
    suspend fun recognizeText(imagePath: String): DataResult<OcrResult>
}
