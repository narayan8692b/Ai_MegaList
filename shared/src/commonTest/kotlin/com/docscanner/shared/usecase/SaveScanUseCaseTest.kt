package com.docscanner.shared.usecase

import app.cash.turbine.test
import com.docscanner.shared.domain.model.CapturedImage
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.ScanPage
import com.docscanner.shared.domain.model.ScanSession
import com.docscanner.shared.domain.usecase.SaveScanUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.fake.FakeDocumentRepository
import com.docscanner.shared.fake.FakeImageProcessor
import com.docscanner.shared.fake.FakeOcrEngine
import com.docscanner.shared.fake.FixedIdGenerator
import com.docscanner.shared.fake.FixedTimeProvider
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SaveScanUseCaseTest {

    private fun scanPage(id: String, path: String) = ScanPage(
        id = id,
        original = CapturedImage(id = id, imagePath = path, width = 800, height = 1200),
        corners = DocumentCorners.FULL,
        filter = ScanFilter.MAGIC_COLOR,
    )

    @Test
    fun savesDocumentWithTwoPages_orderedConcatenatedAndPersisted() = runTest {
        val repo = FakeDocumentRepository()
        val useCase = SaveScanUseCase(
            documentRepository = repo,
            imageProcessor = FakeImageProcessor(),
            ocrEngine = FakeOcrEngine(),
            idGenerator = FixedIdGenerator("doc"),
            timeProvider = FixedTimeProvider(42L),
        )

        val session = ScanSession(
            documentTitle = "Contract",
            pages = listOf(scanPage("a", "/o/a.jpg"), scanPage("b", "/o/b.jpg")),
        )

        val result = useCase(session, folderId = "folder-1")

        assertTrue(result is DataResult.Success)
        val doc = result.data

        // Deterministic id (first id is consumed for the document) and time.
        assertEquals("doc-0", doc.id)
        assertEquals(42L, doc.createdAt)
        assertEquals(42L, doc.updatedAt)
        assertEquals("folder-1", doc.folderId)
        assertEquals("Contract", doc.title)

        // Two pages, ordered 0 then 1.
        assertEquals(2, doc.pages.size)
        assertEquals(listOf(0, 1), doc.pages.map { it.orderIndex })

        // Processed paths follow the fake: perspectiveCorrect then applyFilter.
        assertEquals("/o/a.jpg.corrected.MAGIC_COLOR", doc.pages[0].processedImagePath)
        assertEquals("/o/b.jpg.corrected.MAGIC_COLOR", doc.pages[1].processedImagePath)

        // OCR concatenated across both pages.
        assertEquals("sample text\nsample text", doc.ocrText)

        // Persisted in the repository.
        repo.observeDocuments().test {
            val emitted = awaitItem()
            assertEquals(1, emitted.size)
            assertEquals("doc-0", emitted.first().id)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
