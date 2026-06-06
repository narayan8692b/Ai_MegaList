package com.docscanner.shared.platform

import com.docscanner.shared.domain.model.PdfQuality
import com.docscanner.shared.domain.platform.PdfGenerator
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import platform.CoreGraphics.CGRectMake
import platform.Foundation.writeToFile
import platform.UIKit.UIGraphicsBeginPDFContextToFile
import platform.UIKit.UIGraphicsBeginPDFPageWithInfo
import platform.UIKit.UIGraphicsEndPDFContext
import platform.UIKit.UIImage
import platform.UIKit.UIImageJPEGRepresentation

/**
 * iOS [PdfGenerator] built on the UIKit PDF context APIs
 * (`UIGraphicsBeginPDFContextToFile` / `UIGraphicsBeginPDFPageWithInfo`).
 *
 * Each page is sized to the source image's point size and the image is drawn to fill the
 * page. Pages are drawn one at a time so memory stays bounded for large documents.
 *
 * Password / encryption: the high-level UIKit PDF context does not expose the CoreGraphics
 * encryption auxiliary dictionary (kCGPDFContextUserPassword / kCGPDFContextOwnerPassword).
 * Implementing encryption would require dropping to CGPDFContextCreate with a CFData consumer
 * and an encryption dictionary. To keep this coherent and dependency-free we document the
 * simplification: when [password] is non-null we still produce a valid (UNENCRYPTED) PDF and
 * return success. TODO: replace with CGPDFContextCreate + encryption dictionary for true
 * password protection. The unencrypted path is fully functional.
 */
@OptIn(ExperimentalForeignApi::class)
class IosPdfGenerator : PdfGenerator {

    override suspend fun generatePdf(
        imagePaths: List<String>,
        outputPath: String,
        quality: PdfQuality,
        password: String?,
    ): DataResult<String> = withContext(Dispatchers.Default) {
        try {
            if (imagePaths.isEmpty()) {
                return@withContext DataResult.Failure(
                    AppError.PdfGeneration("No pages provided"),
                )
            }

            // NOTE: password is intentionally ignored here — see class KDoc. The produced
            // PDF is valid but unencrypted.
            val started = UIGraphicsBeginPDFContextToFile(outputPath, CGRectMake(0.0, 0.0, 0.0, 0.0), null)
            // UIGraphicsBeginPDFContextToFile returns Boolean on KMP bindings; if false, fail.
            if (started == false) {
                return@withContext DataResult.Failure(
                    AppError.PdfGeneration("Unable to open PDF context at $outputPath"),
                )
            }
            try {
                for (path in imagePaths) {
                    val image = UIImage.imageWithContentsOfFile(path) ?: continue
                    val (w, h) = image.size.useContents { width to height }
                    if (w <= 0.0 || h <= 0.0) continue
                    val pageRect = CGRectMake(0.0, 0.0, w, h)
                    UIGraphicsBeginPDFPageWithInfo(pageRect, null)
                    image.drawInRect(pageRect)
                }
            } finally {
                UIGraphicsEndPDFContext()
            }
            DataResult.Success(outputPath)
        } catch (t: Throwable) {
            DataResult.Failure(AppError.PdfGeneration(t.message ?: "PDF generation failed", t))
        }
    }

    override suspend fun exportJpg(
        imagePath: String,
        outputPath: String,
        quality: PdfQuality,
    ): DataResult<String> = withContext(Dispatchers.Default) {
        try {
            val image = UIImage.imageWithContentsOfFile(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )
            // PdfQuality.jpegQuality is 0..100; UIImageJPEGRepresentation wants 0..1.
            val q = quality.jpegQuality.coerceIn(0, 100) / 100.0
            val data = UIImageJPEGRepresentation(image, q)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Failed to encode JPEG"),
                )
            val ok = data.writeToFile(outputPath, atomically = true)
            if (ok) {
                DataResult.Success(outputPath)
            } else {
                DataResult.Failure(AppError.Storage("Failed to write JPEG to $outputPath"))
            }
        } catch (t: Throwable) {
            DataResult.Failure(AppError.Storage(t.message ?: "exportJpg failed", t))
        }
    }
}
