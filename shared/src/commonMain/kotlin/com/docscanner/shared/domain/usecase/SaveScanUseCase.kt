package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Page
import com.docscanner.shared.domain.model.ScanSession
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.platform.OcrEngine
import com.docscanner.shared.domain.platform.TimeProvider
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.util.DataResult

/**
 * Finalize a [ScanSession] into a persisted [Document]: ensure each page is
 * perspective-corrected and filtered, run OCR over every page, concatenate the text
 * for search, and persist via the repository.
 */
class SaveScanUseCase(
    private val documentRepository: DocumentRepository,
    private val imageProcessor: ImageProcessor,
    private val ocrEngine: OcrEngine,
    private val idGenerator: IdGenerator,
    private val timeProvider: TimeProvider,
) {
    suspend operator fun invoke(
        session: ScanSession,
        folderId: String? = null,
    ): DataResult<Document> {
        val now = timeProvider.nowMillis()
        val documentId = idGenerator.newId()
        val pages = mutableListOf<Page>()
        val ocrBuilder = StringBuilder()

        session.pages.forEachIndexed { index, scanPage ->
            val processedPath = scanPage.processedImagePath ?: run {
                val corrected = imageProcessor.perspectiveCorrect(
                    scanPage.original.imagePath,
                    scanPage.corners,
                )
                val correctedPath = corrected.getOrNull()
                    ?: return DataResult.Failure((corrected as DataResult.Failure).error)
                val filtered = imageProcessor.applyFilter(correctedPath, scanPage.filter)
                filtered.getOrNull()
                    ?: return DataResult.Failure((filtered as DataResult.Failure).error)
            }

            val ocrText = scanPage.ocrText.ifBlank {
                ocrEngine.recognizeText(processedPath).getOrNull()?.fullText.orEmpty()
            }
            if (ocrText.isNotBlank()) ocrBuilder.append(ocrText).append('\n')

            pages += Page(
                id = idGenerator.newId(),
                documentId = documentId,
                orderIndex = index,
                originalImagePath = scanPage.original.imagePath,
                processedImagePath = processedPath,
                corners = scanPage.corners,
                filter = scanPage.filter,
                ocrText = ocrText,
                width = scanPage.original.width,
                height = scanPage.original.height,
            )
        }

        val document = Document(
            id = documentId,
            title = session.documentTitle.ifBlank { "Scan $documentId" },
            pages = pages,
            folderId = folderId,
            tags = emptyList(),
            ocrText = ocrBuilder.toString().trim(),
            createdAt = now,
            updatedAt = now,
            syncStatus = SyncStatus.LOCAL_ONLY,
        )

        return documentRepository.upsertDocument(document).map { document }
    }
}
