package com.docscanner.shared.platform

import com.docscanner.shared.domain.model.BoundingBox
import com.docscanner.shared.domain.model.OcrBlock
import com.docscanner.shared.domain.model.OcrResult
import com.docscanner.shared.domain.platform.OcrEngine
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import platform.Vision.VNImageRequestHandler
import platform.Vision.VNRecognizeTextRequest
import platform.Vision.VNRecognizedText
import platform.Vision.VNRecognizedTextObservation
import platform.Vision.VNRequestTextRecognitionLevelAccurate
import platform.UIKit.UIImage
import kotlin.coroutines.resume

/**
 * iOS [OcrEngine] backed by the Vision framework's [VNRecognizeTextRequest].
 *
 * The request runs on [Dispatchers.Default]; Vision invokes the request completion handler
 * synchronously during `performRequests`, so we drive it via [suspendCancellableCoroutine]
 * and resume once the handler has populated results (or thrown).
 *
 * Bounding boxes returned by Vision are normalized (0..1) with a BOTTOM-LEFT origin; we flip
 * the Y axis so the domain [BoundingBox] uses a top-left origin (top < bottom).
 */
@OptIn(ExperimentalForeignApi::class)
class VisionOcrEngine : OcrEngine {

    override suspend fun recognizeText(imagePath: String): DataResult<OcrResult> =
        withContext(Dispatchers.Default) {
            val uiImage = UIImage.imageWithContentsOfFile(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Ocr("Unable to decode image: $imagePath"),
                )
            val cgImage = uiImage.CGImage
                ?: return@withContext DataResult.Failure(
                    AppError.Ocr("Unable to obtain CGImage: $imagePath"),
                )

            suspendCancellableCoroutine { cont ->
                try {
                    val request = VNRecognizeTextRequest { completedRequest, error ->
                        if (error != null) {
                            cont.resume(
                                DataResult.Failure(
                                    AppError.Ocr(error.localizedDescription ?: "Vision OCR failed"),
                                ),
                            )
                            return@VNRecognizeTextRequest
                        }
                        val results = completedRequest?.results ?: emptyList<Any?>()
                        cont.resume(DataResult.Success(parse(results)))
                    }
                    request.setRecognitionLevel(VNRequestTextRecognitionLevelAccurate)
                    request.setUsesLanguageCorrection(true)

                    val handler = VNImageRequestHandler(cgImage, options = mapOf<Any?, Any?>())
                    val ok = handler.performRequests(listOf(request), error = null)
                    if (!ok && cont.isActive) {
                        cont.resume(DataResult.Failure(AppError.Ocr("Vision performRequests failed")))
                    }
                } catch (t: Throwable) {
                    if (cont.isActive) {
                        cont.resume(DataResult.Failure(AppError.Ocr(t.message ?: "Vision OCR error", t)))
                    }
                }
            }
        }

    private fun parse(results: List<*>): OcrResult {
        val blocks = mutableListOf<OcrBlock>()
        val sb = StringBuilder()
        for (obs in results) {
            val observation = obs as? VNRecognizedTextObservation ?: continue
            val candidate = observation.topCandidates(1u).firstOrNull() as? VNRecognizedText ?: continue
            val text = candidate.string
            if (text.isEmpty()) continue
            if (sb.isNotEmpty()) sb.append('\n')
            sb.append(text)

            // observation.boundingBox: normalized, bottom-left origin.
            val box = observation.boundingBox.useContents {
                BoundingBox(
                    left = origin.x.toFloat(),
                    right = (origin.x + size.width).toFloat(),
                    // Flip Y: Vision bottom-left -> domain top-left.
                    top = (1.0 - (origin.y + size.height)).toFloat(),
                    bottom = (1.0 - origin.y).toFloat(),
                )
            }
            blocks.add(
                OcrBlock(
                    text = text,
                    boundingBox = box,
                    confidence = candidate.confidence,
                ),
            )
        }
        return OcrResult(fullText = sb.toString(), blocks = blocks, languageCode = null)
    }
}
