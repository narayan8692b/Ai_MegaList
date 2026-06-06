package com.docscanner.shared.usecase

import app.cash.turbine.test
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.usecase.SearchDocumentsUseCase
import com.docscanner.shared.fake.FakeDocumentRepository
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class SearchDocumentsUseCaseTest {

    private fun document(
        id: String,
        title: String,
        ocrText: String,
    ) = Document(
        id = id,
        title = title,
        pages = emptyList(),
        folderId = null,
        tags = emptyList(),
        ocrText = ocrText,
        createdAt = 0L,
        updatedAt = 0L,
        syncStatus = SyncStatus.LOCAL_ONLY,
    )

    private val invoice = document("1", "March Invoice", "Total due: 1500 USD")
    private val recipe = document("2", "Pasta Recipe", "Boil water and add salt")
    private val passport = document("3", "Passport", "Nationality and visa stamps")

    @Test
    fun matchesByTitle() = runTest {
        val repo = FakeDocumentRepository(listOf(invoice, recipe, passport))
        val useCase = SearchDocumentsUseCase(repo)

        useCase("recipe").test {
            val result = awaitItem()
            assertEquals(listOf("2"), result.map { it.id })
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun matchesByOcrText_caseInsensitive() = runTest {
        val repo = FakeDocumentRepository(listOf(invoice, recipe, passport))
        val useCase = SearchDocumentsUseCase(repo)

        useCase("VISA").test {
            val result = awaitItem()
            assertEquals(listOf("3"), result.map { it.id })
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun blankQueryReturnsEverything() = runTest {
        val repo = FakeDocumentRepository(listOf(invoice, recipe, passport))
        val useCase = SearchDocumentsUseCase(repo)

        // SearchDocumentsUseCase trims the query, so whitespace becomes a blank query.
        useCase("   ").test {
            val result = awaitItem()
            assertEquals(setOf("1", "2", "3"), result.map { it.id }.toSet())
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun noMatchReturnsEmpty() = runTest {
        val repo = FakeDocumentRepository(listOf(invoice, recipe, passport))
        val useCase = SearchDocumentsUseCase(repo)

        useCase("nonexistent").test {
            val result = awaitItem()
            assertEquals(emptyList(), result)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
