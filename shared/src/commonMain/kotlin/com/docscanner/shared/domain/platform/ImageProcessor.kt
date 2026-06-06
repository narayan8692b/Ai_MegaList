package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.util.DataResult

/**
 * Platform image-processing abstraction. Android backs this with OpenCV/RenderScript-free
 * Canvas + ColorMatrix operations and Apple backs it with Core Image / Vision. All heavy
 * work must run off the main thread (callers invoke from a background dispatcher).
 */
interface ImageProcessor {

    /**
     * Detect the most likely document quadrilateral in [imagePath]. Returns normalized
     * corners, or [DocumentCorners.FULL] if no confident detection. Must complete in
     * under ~2s on low-end devices.
     */
    suspend fun detectEdges(imagePath: String): DataResult<DocumentCorners>

    /**
     * Apply perspective correction using [corners] (normalized) and write the warped,
     * de-skewed image to a new file. Returns the output path.
     */
    suspend fun perspectiveCorrect(
        imagePath: String,
        corners: DocumentCorners,
    ): DataResult<String>

    /** Apply an enhancement [filter] and return the path of the produced image. */
    suspend fun applyFilter(
        imagePath: String,
        filter: ScanFilter,
    ): DataResult<String>

    /** Produce a small thumbnail for list display. Returns output path. */
    suspend fun createThumbnail(imagePath: String, maxSize: Int = 512): DataResult<String>

    suspend fun imageDimensions(imagePath: String): DataResult<Pair<Int, Int>>
}
