package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.PdfQuality
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.platform.FileSharer
import com.docscanner.shared.domain.platform.PdfGenerator
import com.docscanner.shared.domain.util.DataResult

/** Generate a (optionally password-protected) PDF from a document's processed pages. */
class GeneratePdfUseCase(
    private val pdfGenerator: PdfGenerator,
    private val fileStorage: FileStorage,
) {
    suspend operator fun invoke(
        document: Document,
        quality: PdfQuality = PdfQuality.HIGH,
        password: String? = null,
    ): DataResult<String> {
        if (document.pages.isEmpty()) {
            return DataResult.Failure(
                com.docscanner.shared.domain.util.AppError.PdfGeneration("Document has no pages"),
            )
        }
        val output = fileStorage.newFilePath(fileStorage.exportsDir(), "pdf")
        return pdfGenerator.generatePdf(
            imagePaths = document.pages.map { it.processedImagePath },
            outputPath = output,
            quality = quality,
            password = password,
        )
    }
}

/** Export a single page as JPG. */
class ExportJpgUseCase(
    private val pdfGenerator: PdfGenerator,
    private val fileStorage: FileStorage,
) {
    suspend operator fun invoke(
        imagePath: String,
        quality: PdfQuality = PdfQuality.HIGH,
    ): DataResult<String> {
        val output = fileStorage.newFilePath(fileStorage.exportsDir(), "jpg")
        return pdfGenerator.exportJpg(imagePath, output, quality)
    }
}

/** Share a previously exported file through the native share sheet. */
class ShareFileUseCase(private val fileSharer: FileSharer) {
    suspend operator fun invoke(path: String, mimeType: String): DataResult<Unit> =
        fileSharer.shareFile(path, mimeType)
}

/** Export the concatenated OCR text of a document to a .txt file. */
class ExportOcrTextUseCase(private val fileStorage: FileStorage) {
    suspend operator fun invoke(document: Document): DataResult<String> {
        val output = fileStorage.newFilePath(fileStorage.exportsDir(), "txt")
        return fileStorage.writeText(output, document.ocrText)
    }
}
