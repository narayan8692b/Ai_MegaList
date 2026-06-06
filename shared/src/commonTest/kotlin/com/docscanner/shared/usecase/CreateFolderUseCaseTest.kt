package com.docscanner.shared.usecase

import app.cash.turbine.test
import com.docscanner.shared.domain.usecase.CreateFolderUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.fake.FakeFolderRepository
import com.docscanner.shared.fake.FixedIdGenerator
import com.docscanner.shared.fake.FixedTimeProvider
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CreateFolderUseCaseTest {

    @Test
    fun createsFolderWithGeneratedIdFixedTime_andPersists() = runTest {
        val repo = FakeFolderRepository()
        val useCase = CreateFolderUseCase(
            repository = repo,
            idGenerator = FixedIdGenerator("folder"),
            timeProvider = FixedTimeProvider(777L),
        )

        val result = useCase(name = "  Receipts  ", color = 0xFF00FF00)

        assertTrue(result is DataResult.Success)

        // observeFolders(null) returns top-level folders (parentId == null).
        repo.observeFolders().test {
            val folders = awaitItem()
            assertEquals(1, folders.size)
            val folder = folders.first()
            assertEquals("folder-0", folder.id)
            assertEquals("Receipts", folder.name) // trimmed
            assertEquals(777L, folder.createdAt)
            assertEquals(0xFF00FF00, folder.color)
            assertNull(folder.parentId)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
