package com.docscanner.shared.domain.model

/**
 * In-memory state of an active multi-page scan, before it is persisted as a [Document].
 * Each [ScanPage] tracks its captured image, the corners chosen on the adjustment screen,
 * and the selected enhancement filter.
 */
data class ScanSession(
    val documentTitle: String,
    val pages: List<ScanPage> = emptyList(),
)

data class ScanPage(
    val id: String,
    val original: CapturedImage,
    val corners: DocumentCorners,
    val filter: ScanFilter,
    /** Path of the perspective-corrected + filtered preview, if already produced. */
    val processedImagePath: String? = null,
    val ocrText: String = "",
)
