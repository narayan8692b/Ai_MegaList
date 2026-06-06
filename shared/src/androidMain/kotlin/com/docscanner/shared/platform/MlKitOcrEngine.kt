package com.docscanner.shared.platform

import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import com.docscanner.shared.domain.model.BoundingBox
import com.docscanner.shared.domain.model.OcrBlock
import com.docscanner.shared.domain.model.OcrResult
import com.docscanner.shared.domain.platform.OcrEngine
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.suspendCancellableCoroutine
import java.io.File
import kotlin.coroutines.resume

/**
 * Android [OcrEngine] backed by Google ML Kit on-device Latin text recognition.
 *
 * The ML Kit [com.google.android.gms.tasks.Task] is awaited via
 * [suspendCancellableCoroutine] so we do not depend on `kotlinx-coroutines-play-services`
 * (its `.await()` extension is not in the dependency set).
 */
class MlKitOcrEngine(private val context: Context) : OcrEngine {

    private val recognizer by lazy {
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_CLIENT)
    }

    override suspend fun recognizeText(imagePath: String): DataResult<OcrResult> {
        // Read the source dimensions up-front so we can normalize bounding boxes (0..1).
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(imagePath, bounds)
        val imgW = bounds.outWidth
        val imgH = bounds.outHeight
        if (imgW <= 0 || imgH <= 0) {
            return DataResult.Failure(AppError.Ocr("Unable to decode image: $imagePath"))
        }

        val input = try {
            InputImage.fromFilePath(context, Uri.fromFile(File(imagePath)))
        } catch (e: Throwable) {
            return DataResult.Failure(AppError.Ocr("Unable to load image for OCR", e))
        }

        return suspendCancellableCoroutine { cont ->
            recognizer.process(input)
                .addOnSuccessListener { text ->
                    val blocks = text.textBlocks.map { block ->
                        val r = block.boundingBox
                        OcrBlock(
                            text = block.text,
                            boundingBox = if (r != null) {
                                BoundingBox(
                                    left = r.left.toFloat() / imgW,
                                    top = r.top.toFloat() / imgH,
                                    right = r.right.toFloat() / imgW,
                                    bottom = r.bottom.toFloat() / imgH,
                                )
                            } else {
                                BoundingBox(0f, 0f, 0f, 0f)
                            },
                            // ML Kit's Latin recognizer does not expose a confidence score.
                            confidence = 0f,
                        )
                    }
                    cont.resume(
                        DataResult.Success(
                            OcrResult(
                                fullText = text.text,
                                blocks = blocks,
                                languageCode = blocks.firstOrNull()?.let { null },
                            ),
                        ),
                    )
                }
                .addOnFailureListener { e ->
                    cont.resume(DataResult.Failure(AppError.Ocr("OCR failed", e)))
                }
            cont.invokeOnCancellation { /* ML Kit task cannot be hard-cancelled; result is ignored. */ }
        }
    }
}
