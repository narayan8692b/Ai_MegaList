package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.util.DataResult

/**
 * Auto-detect the document boundary in a captured image. Used to seed the corner
 * adjustment screen that is shown after every capture.
 */
class DetectEdgesUseCase(private val imageProcessor: ImageProcessor) {
    suspend operator fun invoke(imagePath: String): DataResult<DocumentCorners> =
        imageProcessor.detectEdges(imagePath)
}

/**
 * Apply perspective correction using the (possibly user-adjusted) [corners] and then
 * the chosen [filter], returning the path of the final processed image.
 */
class ProcessPageUseCase(private val imageProcessor: ImageProcessor) {
    suspend operator fun invoke(
        imagePath: String,
        corners: DocumentCorners,
        filter: ScanFilter,
    ): DataResult<String> {
        val corrected = imageProcessor.perspectiveCorrect(imagePath, corners)
        return when (corrected) {
            is DataResult.Failure -> corrected
            is DataResult.Success -> imageProcessor.applyFilter(corrected.data, filter)
        }
    }
}

/** Preview a single filter on an already perspective-corrected image. */
class ApplyFilterUseCase(private val imageProcessor: ImageProcessor) {
    suspend operator fun invoke(imagePath: String, filter: ScanFilter): DataResult<String> =
        imageProcessor.applyFilter(imagePath, filter)
}
