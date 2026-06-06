package com.docscanner.shared.platform

import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.PointF
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.CValue
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import platform.CoreGraphics.CGPoint
import platform.CoreGraphics.CGRectMake
import platform.CoreGraphics.CGSizeMake
import platform.CoreImage.CIContext
import platform.CoreImage.CIDetector
import platform.CoreImage.CIDetectorAccuracy
import platform.CoreImage.CIDetectorAccuracyHigh
import platform.CoreImage.CIDetectorTypeRectangle
import platform.CoreImage.CIFilter
import platform.CoreImage.CIImage
import platform.CoreImage.CIRectangleFeature
import platform.CoreImage.CIVector
import platform.Foundation.NSData
import platform.Foundation.NSNumber
import platform.Foundation.numberWithFloat
import platform.Foundation.writeToFile
import platform.UIKit.UIImage
import platform.UIKit.UIImageJPEGRepresentation

/**
 * iOS [ImageProcessor] implemented with Core Image (CIImage / CIFilter / CIDetector) and
 * UIKit (UIImage encode/decode). Heavy work runs on [Dispatchers.Default].
 *
 * Coordinate conventions:
 *  - Domain [DocumentCorners] are normalized (0..1) with a TOP-LEFT origin (UIKit style).
 *  - Core Image uses a BOTTOM-LEFT origin, so when we read rectangle features or feed
 *    corner points into CIPerspectiveCorrection we flip the Y axis accordingly.
 *
 * Pragmatic choices (documented):
 *  - Edge detection uses CIDetector(CIDetectorTypeRectangle), high accuracy, returning the
 *    first/strongest feature. If none is found we return [DocumentCorners.FULL].
 *  - Filters are approximated with CIColorControls / CIPhotoEffectMono. BLACK_AND_WHITE is a
 *    high-contrast mono pass (not a true adaptive threshold) to stay dependency-free.
 *  - All outputs are JPEG written into [fileStorage].processedDir().
 */
@OptIn(ExperimentalForeignApi::class)
class IosImageProcessor(
    private val fileStorage: FileStorage,
) : ImageProcessor {

    private val ciContext: CIContext by lazy { CIContext.contextWithOptions(null) }

    override suspend fun detectEdges(imagePath: String): DataResult<DocumentCorners> =
        withContext(Dispatchers.Default) {
            try {
                val ciImage = loadCIImage(imagePath)
                    ?: return@withContext DataResult.Success(DocumentCorners.FULL)

                val width = ciImage.extent.useContents { size.width }
                val height = ciImage.extent.useContents { size.height }
                if (width <= 0.0 || height <= 0.0) {
                    return@withContext DataResult.Success(DocumentCorners.FULL)
                }

                val detector = CIDetector.detectorOfType(
                    type = CIDetectorTypeRectangle,
                    context = ciContext,
                    options = mapOf<Any?, Any?>(CIDetectorAccuracy to CIDetectorAccuracyHigh),
                )
                val features = detector?.featuresInImage(ciImage)
                val rect = features?.firstOrNull() as? CIRectangleFeature
                    ?: return@withContext DataResult.Success(DocumentCorners.FULL)

                // CIRectangleFeature corners are in image pixel space, bottom-left origin.
                // toPointF() normalizes and flips Y to the domain's top-left origin.
                val corners = DocumentCorners(
                    topLeft = rect.topLeft.toPointF(width, height),
                    topRight = rect.topRight.toPointF(width, height),
                    bottomRight = rect.bottomRight.toPointF(width, height),
                    bottomLeft = rect.bottomLeft.toPointF(width, height),
                )
                DataResult.Success(corners)
            } catch (t: Throwable) {
                // Detection is best-effort; never hard-fail the pipeline.
                DataResult.Success(DocumentCorners.FULL)
            }
        }

    private fun CValue<CGPoint>.toPointF(width: Double, height: Double): PointF =
        useContents {
            val nx = (x / width).coerceIn(0.0, 1.0)
            // Flip Y: CoreImage bottom-left -> domain top-left.
            val ny = (1.0 - (y / height)).coerceIn(0.0, 1.0)
            PointF(nx.toFloat(), ny.toFloat())
        }

    override suspend fun perspectiveCorrect(
        imagePath: String,
        corners: DocumentCorners,
    ): DataResult<String> = withContext(Dispatchers.Default) {
        try {
            val ciImage = loadCIImage(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )
            val width = ciImage.extent.useContents { size.width }
            val height = ciImage.extent.useContents { size.height }

            // Convert normalized top-left-origin corners to pixel bottom-left-origin CIVectors.
            fun vec(p: PointF): CIVector {
                val px = p.x.toDouble() * width
                // Flip Y back to bottom-left origin for Core Image.
                val py = (1.0 - p.y.toDouble()) * height
                return CIVector.vectorWithX(px, y = py)
            }

            val filter = CIFilter.filterWithName("CIPerspectiveCorrection")
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("CIPerspectiveCorrection unavailable"),
                )
            filter.setValue(ciImage, forKey = "inputImage")
            filter.setValue(vec(corners.topLeft), forKey = "inputTopLeft")
            filter.setValue(vec(corners.topRight), forKey = "inputTopRight")
            filter.setValue(vec(corners.bottomRight), forKey = "inputBottomRight")
            filter.setValue(vec(corners.bottomLeft), forKey = "inputBottomLeft")

            val output = filter.outputImage
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Perspective correction produced no output"),
                )
            val path = renderToJpeg(output, quality = 0.95)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Failed to encode corrected image"),
                )
            DataResult.Success(path)
        } catch (t: Throwable) {
            DataResult.Failure(AppError.Storage("Perspective correction failed", t))
        }
    }

    override suspend fun applyFilter(
        imagePath: String,
        filter: ScanFilter,
    ): DataResult<String> = withContext(Dispatchers.Default) {
        try {
            val ciImage = loadCIImage(imagePath)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Unable to decode image: $imagePath"),
                )

            val output = when (filter) {
                ScanFilter.ORIGINAL -> ciImage
                ScanFilter.GRAYSCALE -> colorControls(ciImage, saturation = 0.0, contrast = 1.0, brightness = 0.0)
                ScanFilter.HIGH_CONTRAST -> colorControls(ciImage, saturation = 1.0, contrast = 1.6, brightness = 0.0)
                ScanFilter.MAGIC_COLOR -> colorControls(ciImage, saturation = 1.3, contrast = 1.25, brightness = 0.02)
                ScanFilter.BLACK_AND_WHITE -> {
                    // Mono + strong contrast to approximate a B/W threshold scan.
                    val mono = colorControls(ciImage, saturation = 0.0, contrast = 1.0, brightness = 0.0)
                    colorControls(mono, saturation = 0.0, contrast = 4.0, brightness = 0.0)
                }
            }
            val path = renderToJpeg(output, quality = 0.95)
                ?: return@withContext DataResult.Failure(
                    AppError.Storage("Failed to encode filtered image"),
                )
            DataResult.Success(path)
        } catch (t: Throwable) {
            DataResult.Failure(AppError.Storage("Filter application failed", t))
        }
    }

    private fun colorControls(
        input: CIImage,
        saturation: Double,
        contrast: Double,
        brightness: Double,
    ): CIImage {
        val filter = CIFilter.filterWithName("CIColorControls") ?: return input
        filter.setValue(input, forKey = "inputImage")
        filter.setValue(NSNumber.numberWithFloat(saturation.toFloat()), forKey = "inputSaturation")
        filter.setValue(NSNumber.numberWithFloat(contrast.toFloat()), forKey = "inputContrast")
        filter.setValue(NSNumber.numberWithFloat(brightness.toFloat()), forKey = "inputBrightness")
        return filter.outputImage ?: input
    }

    override suspend fun createThumbnail(imagePath: String, maxSize: Int): DataResult<String> =
        withContext(Dispatchers.Default) {
            try {
                val image = UIImage.imageWithContentsOfFile(imagePath)
                    ?: return@withContext DataResult.Failure(
                        AppError.Storage("Unable to decode image: $imagePath"),
                    )
                val (w, h) = image.size.useContents { width to height }
                if (w <= 0.0 || h <= 0.0) {
                    return@withContext DataResult.Failure(
                        AppError.Storage("Invalid image dimensions: $imagePath"),
                    )
                }
                val scale = maxSize.toDouble() / maxOf(w, h)
                val targetW = if (scale < 1.0) w * scale else w
                val targetH = if (scale < 1.0) h * scale else h

                // UIGraphicsImageRenderer-free path: use the legacy begin/end context.
                platform.UIKit.UIGraphicsBeginImageContextWithOptions(
                    CGSizeMake(targetW, targetH), false, 1.0,
                )
                image.drawInRect(CGRectMake(0.0, 0.0, targetW, targetH))
                val thumb = platform.UIKit.UIGraphicsGetImageFromCurrentImageContext()
                platform.UIKit.UIGraphicsEndImageContext()

                val data = thumb?.let { UIImageJPEGRepresentation(it, 0.8) }
                    ?: return@withContext DataResult.Failure(
                        AppError.Storage("Failed to render thumbnail"),
                    )
                val path = writeJpegData(data)
                    ?: return@withContext DataResult.Failure(
                        AppError.Storage("Failed to write thumbnail"),
                    )
                DataResult.Success(path)
            } catch (t: Throwable) {
                DataResult.Failure(AppError.Storage("Thumbnail creation failed", t))
            }
        }

    override suspend fun imageDimensions(imagePath: String): DataResult<Pair<Int, Int>> =
        withContext(Dispatchers.Default) {
            try {
                val image = UIImage.imageWithContentsOfFile(imagePath)
                    ?: return@withContext DataResult.Failure(
                        AppError.Storage("Unable to read dimensions: $imagePath"),
                    )
                val (w, h) = image.size.useContents { width to height }
                if (w <= 0.0 || h <= 0.0) {
                    DataResult.Failure(AppError.Storage("Invalid dimensions: $imagePath"))
                } else {
                    // Pixel dimensions = point size * scale.
                    val scale = image.scale
                    DataResult.Success((w * scale).toInt() to (h * scale).toInt())
                }
            } catch (t: Throwable) {
                DataResult.Failure(AppError.Storage("Unable to read dimensions", t))
            }
        }

    // --- helpers ---------------------------------------------------------

    private fun loadCIImage(imagePath: String): CIImage? {
        val uiImage = UIImage.imageWithContentsOfFile(imagePath) ?: return null
        val cg = uiImage.CGImage ?: return null
        return CIImage.imageWithCGImage(cg)
    }

    private fun renderToJpeg(image: CIImage, quality: Double): String? {
        val cg = ciContext.createCGImage(image, fromRect = image.extent) ?: return null
        val uiImage = UIImage.imageWithCGImage(cg)
        val data = UIImageJPEGRepresentation(uiImage, quality) ?: return null
        return writeJpegData(data)
    }

    private fun writeJpegData(data: NSData): String? {
        val path = fileStorage.newFilePath(fileStorage.processedDir(), "jpg")
        val ok = data.writeToFile(path, atomically = true)
        return if (ok) path else null
    }
}
