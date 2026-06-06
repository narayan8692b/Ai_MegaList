package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.model.PdfQuality
import com.docscanner.shared.domain.util.DataResult

/**
 * Generates PDF documents from processed page images. Android uses PdfDocument and iOS
 * uses UIGraphicsPDFRenderer. Must stream pages to stay memory-efficient for 100+ pages.
 */
interface PdfGenerator {
    /**
     * @param imagePaths processed page images, in order.
     * @param outputPath destination file path for the generated PDF.
     * @param password optional owner/user password for an encrypted PDF.
     */
    suspend fun generatePdf(
        imagePaths: List<String>,
        outputPath: String,
        quality: PdfQuality = PdfQuality.HIGH,
        password: String? = null,
    ): DataResult<String>

    /** Export a single image to a JPG file. */
    suspend fun exportJpg(
        imagePath: String,
        outputPath: String,
        quality: PdfQuality = PdfQuality.HIGH,
    ): DataResult<String>
}
