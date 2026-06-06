package com.docscanner.shared.platform

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.PointF
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.abs

/**
 * Android [ImageProcessor] built on the platform `android.graphics` APIs (Canvas +
 * ColorMatrix + Matrix), avoiding any native dependency such as OpenCV.
 *
 * Outputs are written to a `processed/` sub-directory of the app cache so callers can
 * safely persist or discard them.
 */
class AndroidImageProcessor(private val context: Context) : ImageProcessor {

    private val outputDir: File by lazy {
        File(context.filesDir, "processed").apply { mkdirs() }
    }

    private fun newOutputFile(ext: String = "jpg"): File =
        File(outputDir, "${UUID.randomUUID()}.$ext")

    /**
     * Pragmatic edge detection heuristic (no OpenCV):
     *
     * 1. Decode the image at a small fixed working size for speed.
     * 2. Convert to luminance and compute a simple Sobel-like gradient magnitude.
     * 3. For each edge of a candidate inset rectangle, scan inward from the image border
     *    until the first strong gradient row/column is found — i.e. the document margin.
     * 4. If the detected inset is implausible (too small / inconsistent), fall back to
     *    [DocumentCorners.FULL].
     *
     * This is intentionally lightweight and approximate; production should swap in a real
     * contour/quadrilateral detector (OpenCV `findContours` + `approxPolyDP`).
     */
    override suspend fun detectEdges(imagePath: String): DataResult<DocumentCorners> =
        withContext(Dispatchers.Default) {
            try {
                val targetW = 300
                val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(imagePath, opts)
                if (opts.outWidth <= 0 || opts.outHeight <= 0) {
                    return@withContext DataResult.Failure(
                        AppError.Storage("Unable to decode image: $imagePath"),
                    )
                }
                val sample = (opts.outWidth / targetW).coerceAtLeast(1)
                val decodeOpts = BitmapFactory.Options().apply { inSampleSize = sample }
                val bmp = BitmapFactory.decodeFile(imagePath, decodeOpts)
                    ?: return@withContext DataResult.Failure(
                        AppError.Storage("Unable to decode image: $imagePath"),
                    )

                val w = bmp.width
                val h = bmp.height
                if (w < 8 || h < 8) {
                    bmp.recycle()
                    return@withContext DataResult.Success(DocumentCorners.FULL)
                }

                // Luminance buffer.
                val pixels = IntArray(w * h)
                bmp.getPixels(pixels, 0, w, 0, 0, w, h)
                bmp.recycle()
                val lum = FloatArray(w * h)
                for (i in pixels.indices) {
                    val p = pixels[i]
                    val r = (p shr 16) and 0xFF
                    val g = (p shr 8) and 0xFF
                    val b = p and 0xFF
                    lum[i] = 0.299f * r + 0.587f * g + 0.114f * b
                }

                // Average gradient magnitude per row / column (interior only).
                val rowGrad = FloatArray(h)
                val colGrad = FloatArray(w)
                for (y in 1 until h - 1) {
                    var rowSum = 0f
                    for (x in 1 until w - 1) {
                        val gx = abs(lum[y * w + x + 1] - lum[y * w + x - 1])
                        val gy = abs(lum[(y + 1) * w + x] - lum[(y - 1) * w + x])
                        val mag = gx + gy
                        rowSum += mag
                        colGrad[x] += mag
                    }
                    rowGrad[y] = rowSum / (w - 2)
                }
                for (x in 0 until w) colGrad[x] /= (h - 2).coerceAtLeast(1)

                // Threshold = mean + factor * stddev of the row gradients.
                val threshold = strongEdgeThreshold(rowGrad) + strongEdgeThreshold(colGrad)
                val half = threshold / 2f

                val top = scanInward(rowGrad, from = 0, to = h / 2, step = 1, threshold = half)
                val bottom = scanInward(rowGrad, from = h - 1, to = h / 2, step = -1, threshold = half)
                val left = scanInward(colGrad, from = 0, to = w / 2, step = 1, threshold = half)
                val right = scanInward(colGrad, from = w - 1, to = w / 2, step = -1, threshold = half)

                // Validate: detected box must be plausible (covers >40% of each dimension).
                val boxW = (right - left).toFloat()
                val boxH = (bottom - top).toFloat()
                if (boxW < w * 0.4f || boxH < h * 0.4f || right <= left || bottom <= top) {
                    return@withContext DataResult.Success(DocumentCorners.FULL)
                }

                val l = left / w.toFloat()
                val r = right / w.toFloat()
                val t = top / h.toFloat()
                val b = bottom / h.toFloat()
                DataResult.Success(
                    DocumentCorners(
                        topLeft = PointF(l, t),
                        topRight = PointF(r, t),
                        bottomRight = PointF(r, b),
                        bottomLeft = PointF(l, b),
                    ),
                )
            } catch (e: Throwable) {
                // Detection is best-effort; never hard-fail the pipeline.
                DataResult.Success(DocumentCorners.FULL)
            }
        }

    private fun strongEdgeThreshold(values: FloatArray): Float {
        var sum = 0f
        var count = 0
        for (v in values) {
            if (v > 0f) {
                sum += v
                count++
            }
        }
        if (count == 0) return Float.MAX_VALUE
        val mean = sum / count
        var varSum = 0f
        for (v in values) if (v > 0f) varSum += (v - mean) * (v - mean)
        val std = kotlin.math.sqrt(varSum / count)
        return mean + std
    }

    /** Scan [values] from [from] toward [to] returning the first index above [threshold]. */
    private fun scanInward(values: FloatArray, from: Int, to: Int, step: Int, threshold: Float): Int {
        var i = from
        while (i != to) {
            if (values[i] >= threshold) return i
            i += step
        }
        return from
    }

    override suspend fun perspectiveCorrect(
        imagePath: String,
        corners: DocumentCorners,
    ): DataResult<String> = withContext(Dispatchers.IO) {
        try {
            val src = BitmapFactory.decodeFile(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )
            val iw = src.width.toFloat()
            val ih = src.height.toFloat()

            // Source quad in pixels (clockwise from top-left).
            val srcPoly = floatArrayOf(
                corners.topLeft.x * iw, corners.topLeft.y * ih,
                corners.topRight.x * iw, corners.topRight.y * ih,
                corners.bottomRight.x * iw, corners.bottomRight.y * ih,
                corners.bottomLeft.x * iw, corners.bottomLeft.y * ih,
            )

            // Output rectangle size = max of opposing edge lengths.
            fun dist(ax: Float, ay: Float, bx: Float, by: Float): Float {
                val dx = ax - bx; val dy = ay - by
                return kotlin.math.sqrt(dx * dx + dy * dy)
            }
            val widthTop = dist(srcPoly[0], srcPoly[1], srcPoly[2], srcPoly[3])
            val widthBottom = dist(srcPoly[6], srcPoly[7], srcPoly[4], srcPoly[5])
            val heightLeft = dist(srcPoly[0], srcPoly[1], srcPoly[6], srcPoly[7])
            val heightRight = dist(srcPoly[2], srcPoly[3], srcPoly[4], srcPoly[5])
            val outW = maxOf(widthTop, widthBottom).toInt().coerceAtLeast(1)
            val outH = maxOf(heightLeft, heightRight).toInt().coerceAtLeast(1)

            val dstPoly = floatArrayOf(
                0f, 0f,
                outW.toFloat(), 0f,
                outW.toFloat(), outH.toFloat(),
                0f, outH.toFloat(),
            )

            val matrix = Matrix()
            matrix.setPolyToPoly(srcPoly, 0, dstPoly, 0, 4)

            val out = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(out)
            canvas.drawColor(Color.WHITE)
            val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
            canvas.drawBitmap(src, matrix, paint)
            src.recycle()

            val result = saveJpeg(out, 95)
            out.recycle()
            DataResult.Success(result)
        } catch (e: Throwable) {
            DataResult.Failure(AppError.Storage("Perspective correction failed", e))
        }
    }

    override suspend fun applyFilter(
        imagePath: String,
        filter: ScanFilter,
    ): DataResult<String> = withContext(Dispatchers.Default) {
        try {
            val src = BitmapFactory.decodeFile(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )
            if (filter == ScanFilter.ORIGINAL) {
                val path = saveJpeg(src, 95)
                src.recycle()
                return@withContext DataResult.Success(path)
            }

            val out = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(out)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            paint.colorFilter = ColorMatrixColorFilter(colorMatrixFor(filter))
            canvas.drawBitmap(src, 0f, 0f, paint)
            src.recycle()

            val path = saveJpeg(out, 95)
            out.recycle()
            DataResult.Success(path)
        } catch (e: Throwable) {
            DataResult.Failure(AppError.Storage("Filter application failed", e))
        }
    }

    private fun colorMatrixFor(filter: ScanFilter): ColorMatrix = when (filter) {
        ScanFilter.ORIGINAL -> ColorMatrix()
        ScanFilter.GRAYSCALE -> ColorMatrix().apply { setSaturation(0f) }
        ScanFilter.HIGH_CONTRAST -> {
            // Scale around mid-gray to boost contrast.
            val c = 1.6f
            val t = (-0.5f * c + 0.5f) * 255f
            ColorMatrix(
                floatArrayOf(
                    c, 0f, 0f, 0f, t,
                    0f, c, 0f, 0f, t,
                    0f, 0f, c, 0f, t,
                    0f, 0f, 0f, 1f, 0f,
                ),
            )
        }
        ScanFilter.BLACK_AND_WHITE -> {
            // Grayscale, then a steep contrast curve approximating a threshold.
            val gray = ColorMatrix().apply { setSaturation(0f) }
            val c = 8f
            val t = (-0.5f * c + 0.5f) * 255f
            val threshold = ColorMatrix(
                floatArrayOf(
                    c, 0f, 0f, 0f, t,
                    0f, c, 0f, 0f, t,
                    0f, 0f, c, 0f, t,
                    0f, 0f, 0f, 1f, 0f,
                ),
            )
            ColorMatrix().apply {
                postConcat(gray)
                postConcat(threshold)
            }
        }
        ScanFilter.MAGIC_COLOR -> {
            // Saturation + contrast boost for vivid "document enhance" look.
            val sat = ColorMatrix().apply { setSaturation(1.3f) }
            val c = 1.25f
            val t = (-0.5f * c + 0.5f) * 255f
            val contrast = ColorMatrix(
                floatArrayOf(
                    c, 0f, 0f, 0f, t,
                    0f, c, 0f, 0f, t,
                    0f, 0f, c, 0f, t,
                    0f, 0f, 0f, 1f, 0f,
                ),
            )
            ColorMatrix().apply {
                postConcat(sat)
                postConcat(contrast)
            }
        }
    }

    override suspend fun createThumbnail(imagePath: String, maxSize: Int): DataResult<String> =
        withContext(Dispatchers.IO) {
            try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(imagePath, bounds)
                if (bounds.outWidth <= 0) {
                    return@withContext DataResult.Failure(
                        AppError.Storage("Unable to decode image: $imagePath"),
                    )
                }
                val largest = maxOf(bounds.outWidth, bounds.outHeight)
                var sample = 1
                while (largest / sample > maxSize * 2) sample *= 2
                val decoded = BitmapFactory.decodeFile(
                    imagePath,
                    BitmapFactory.Options().apply { inSampleSize = sample },
                ) ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )

                val scale = maxSize.toFloat() / maxOf(decoded.width, decoded.height)
                val thumb = if (scale < 1f) {
                    Bitmap.createScaledBitmap(
                        decoded,
                        (decoded.width * scale).toInt().coerceAtLeast(1),
                        (decoded.height * scale).toInt().coerceAtLeast(1),
                        true,
                    ).also { if (it != decoded) decoded.recycle() }
                } else {
                    decoded
                }

                val path = saveJpeg(thumb, 80)
                thumb.recycle()
                DataResult.Success(path)
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("Thumbnail creation failed", e))
            }
        }

    override suspend fun imageDimensions(imagePath: String): DataResult<Pair<Int, Int>> =
        withContext(Dispatchers.IO) {
            try {
                val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(imagePath, opts)
                if (opts.outWidth <= 0 || opts.outHeight <= 0) {
                    DataResult.Failure(AppError.Storage("Unable to read dimensions: $imagePath"))
                } else {
                    DataResult.Success(opts.outWidth to opts.outHeight)
                }
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("Unable to read dimensions", e))
            }
        }

    private fun saveJpeg(bitmap: Bitmap, quality: Int): String {
        val file = newOutputFile("jpg")
        FileOutputStream(file).use { os ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, os)
            os.flush()
        }
        return file.absolutePath
    }
}
