package com.docscanner.shared.domain.model

/**
 * A single page within a [Document].
 *
 * @param originalImagePath path to the raw captured/imported image.
 * @param processedImagePath path to the cropped + perspective-corrected + filtered image.
 * @param corners the document corners (in original-image coordinates) chosen on the
 *   corner-adjustment screen, used for perspective correction.
 * @param filter the enhancement filter applied to produce [processedImagePath].
 * @param ocrText text extracted from this page via the platform OCR engine.
 */
data class Page(
    val id: String,
    val documentId: String,
    val orderIndex: Int,
    val originalImagePath: String,
    val processedImagePath: String,
    val corners: DocumentCorners?,
    val filter: ScanFilter = ScanFilter.ORIGINAL,
    val ocrText: String = "",
    val width: Int = 0,
    val height: Int = 0,
)
