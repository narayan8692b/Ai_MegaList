package com.docscanner.shared.domain.model

/** Result of running the platform OCR engine over an image. */
data class OcrResult(
    val fullText: String,
    val blocks: List<OcrBlock>,
    val languageCode: String? = null,
)

/** A recognized block of text with its bounding box (normalized coordinates). */
data class OcrBlock(
    val text: String,
    val boundingBox: BoundingBox,
    val confidence: Float = 0f,
)

data class BoundingBox(
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
)
