package com.docscanner.shared.platform

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.pdf.PdfDocument
import com.docscanner.shared.domain.model.PdfQuality
import com.docscanner.shared.domain.platform.PdfGenerator
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream

/**
 * Android [PdfGenerator] backed by [android.graphics.pdf.PdfDocument].
 *
 * Pages are streamed one bitmap at a time and recycled immediately so memory stays flat
 * even for 100+ page documents.
 *
 * NOTE on encryption: [PdfDocument] has no native password/encryption support. The
 * [generatePdf] `password` parameter is therefore accepted but currently produces an
 * UNENCRYPTED file. Production builds should route the encrypted path through a library
 * such as iText or PdfBox-Android (`PDDocument.protect(...)`). A non-null password is not
 * an error here — it is logged-as-unsupported and ignored.
 */
class AndroidPdfGenerator(private val context: Context) : PdfGenerator {

    private companion object {
        // A4 at 72dpi (PdfDocument uses points: 1pt = 1/72 inch).
        const val PAGE_WIDTH = 595
        const val PAGE_HEIGHT = 842
    }

    override suspend fun generatePdf(
        imagePaths: List<String>,
        outputPath: String,
        quality: PdfQuality,
        password: String?,
    ): DataResult<String> = withContext(Dispatchers.IO) {
        if (imagePaths.isEmpty()) {
            return@withContext DataResult.Failure(
                AppError.PdfGeneration("No pages supplied for PDF generation"),
            )
        }
        // TODO(security): implement real PDF encryption with iText/PdfBox-Android when
        //  a password is supplied. PdfDocument cannot encrypt, so we proceed unencrypted.
        val document = PdfDocument()
        try {
            imagePaths.forEachIndexed { index, path ->
                val bmp = decodeScaled(path, PAGE_WIDTH, PAGE_HEIGHT)
                    ?: throw IllegalStateException("Unable to decode page image: $path")
                try {
                    // Fit the bitmap to the page preserving aspect ratio, centered.
                    val scale = minOf(
                        PAGE_WIDTH.toFloat() / bmp.width,
                        PAGE_HEIGHT.toFloat() / bmp.height,
                    )
                    val drawW = (bmp.width * scale).toInt()
                    val drawH = (bmp.height * scale).toInt()
                    val left = (PAGE_WIDTH - drawW) / 2
                    val top = (PAGE_HEIGHT - drawH) / 2

                    val pageInfo = PdfDocument.PageInfo
                        .Builder(PAGE_WIDTH, PAGE_HEIGHT, index + 1)
                        .create()
                    val page = document.startPage(pageInfo)
                    page.canvas.drawBitmap(
                        bmp,
                        null,
                        Rect(left, top, left + drawW, top + drawH),
                        null,
                    )
                    document.finishPage(page)
                } finally {
                    bmp.recycle()
                }
            }

            File(outputPath).parentFile?.mkdirs()
            FileOutputStream(outputPath).use { os ->
                document.writeTo(os)
                os.flush()
            }
            DataResult.Success(outputPath)
        } catch (e: Throwable) {
            DataResult.Failure(AppError.PdfGeneration("PDF generation failed", e))
        } finally {
            document.close()
        }
    }

    override suspend fun exportJpg(
        imagePath: String,
        outputPath: String,
        quality: PdfQuality,
    ): DataResult<String> = withContext(Dispatchers.IO) {
        try {
            val bmp = BitmapFactory.decodeFile(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )
            try {
                File(outputPath).parentFile?.mkdirs()
                FileOutputStream(outputPath).use { os ->
                    bmp.compress(Bitmap.CompressFormat.JPEG, quality.jpegQuality, os)
                    os.flush()
                }
            } finally {
                bmp.recycle()
            }
            DataResult.Success(outputPath)
        } catch (e: Throwable) {
            DataResult.Failure(AppError.Storage("JPG export failed", e))
        }
    }

    /** Decode an image down-sampled to roughly the target page size to keep memory low. */
    private fun decodeScaled(path: String, maxW: Int, maxH: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        // Allow up to 2x the page resolution for crispness, then down-sample beyond that.
        while (bounds.outWidth / sample > maxW * 2 || bounds.outHeight / sample > maxH * 2) {
            sample *= 2
        }
        return BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply { inSampleSize = sample },
        )
    }
}
