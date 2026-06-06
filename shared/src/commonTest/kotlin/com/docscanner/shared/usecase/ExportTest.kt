package com.docscanner.shared.usecase

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.Page
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.usecase.ExportOcrTextUseCase
import com.docscanner.shared.domain.usecase.GeneratePdfUseCase
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.fake.FakeFileStorage
import com.docscanner.shared.fake.FakePdfGenerator
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ExportTest {

    private fun page(id: String, processed: String) = Page(
        id = id,
        documentId = "doc",
        orderIndex = 0,
        originalImagePath = "/o/$id.jpg",
        processedImagePath = processed,
        corners = DocumentCorners.FULL,
        filter = ScanFilter.MAGIC_COLOR,
    )

    private fun document(pages: List<Page>, ocrText: String = "") = Document(
        id = "doc",
        title = "Doc",
        pages = pages,
        folderId = null,
        tags = emptyList(),
        ocrText = ocrText,
        createdAt = 0L,
        updatedAt = 0L,
        syncStatus = SyncStatus.LOCAL_ONLY,
    )

    @Test
    fun generatePdf_emptyDocument_failsWithPdfGenerationError() = runTest {
        val pdf = FakePdfGenerator()
        val storage = FakeFileStorage()
        val useCase = GeneratePdfUseCase(pdf, storage)

        val result = useCase(document(emptyList()))

        assertTrue(result is DataResult.Failure)
        assertTrue(
            result.error is AppError.PdfGeneration,
            "expected PdfGeneration error but was ${result.error}",
        )
        assertTrue(pdf.generateCalls.isEmpty(), "generator must not run for empty document")
    }

    @Test
    fun generatePdf_successPath_producesPdfPathFromProcessedPages() = runTest {
        val pdf = FakePdfGenerator()
        val storage = FakeFileStorage()
        val useCase = GeneratePdfUseCase(pdf, storage)

        val doc = document(
            listOf(
                page("a", "/processed/a.jpg"),
                page("b", "/processed/b.jpg"),
            ),
        )

        val result = useCase(doc)

        assertTrue(result is DataResult.Success)
        assertEquals("/exports/file0.pdf", result.data)
        // The generator received the processed page paths in order.
        assertEquals(
            listOf(listOf("/processed/a.jpg", "/processed/b.jpg")),
            pdf.generateCalls,
        )
    }

    @Test
    fun exportOcrText_writesDocumentOcrTextViaFileStorage() = runTest {
        val storage = FakeFileStorage()
        val useCase = ExportOcrTextUseCase(storage)

        val doc = document(emptyList(), ocrText = "hello world\nsecond line")

        val result = useCase(doc)

        assertTrue(result is DataResult.Success)
        assertEquals("/exports/file0.txt", result.data)
        assertEquals("hello world\nsecond line", storage.files["/exports/file0.txt"])
    }
}
