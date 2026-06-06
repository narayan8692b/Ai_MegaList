package com.docscanner.shared.usecase

import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.usecase.ProcessPageUseCase
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.fake.FakeImageProcessor
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ProcessPageUseCaseTest {

    @Test
    fun appliesPerspectiveThenFilter_andReturnsFilteredPath() = runTest {
        val processor = FakeImageProcessor()
        val useCase = ProcessPageUseCase(processor)

        val result = useCase("/originals/cap.jpg", DocumentCorners.FULL, ScanFilter.MAGIC_COLOR)

        assertTrue(result is DataResult.Success)
        // perspectiveCorrect -> "<path>.corrected", then applyFilter -> "<path>.MAGIC_COLOR"
        assertEquals("/originals/cap.jpg.corrected.MAGIC_COLOR", result.data)

        // Ordering: perspective correction ran on the original, filter ran on the corrected.
        assertEquals(listOf("/originals/cap.jpg"), processor.perspectiveCalls.map { it.first })
        assertEquals(
            listOf("/originals/cap.jpg.corrected" to ScanFilter.MAGIC_COLOR),
            processor.filterCalls,
        )
    }

    @Test
    fun perspectiveFailure_propagatesAndSkipsFilter() = runTest {
        val error = AppError.Storage("disk full")
        val processor = FakeImageProcessor(perspectiveFailure = error)
        val useCase = ProcessPageUseCase(processor)

        val result = useCase("/originals/cap.jpg", DocumentCorners.FULL, ScanFilter.GRAYSCALE)

        assertTrue(result is DataResult.Failure)
        assertEquals(error, result.error)
        assertTrue(processor.filterCalls.isEmpty(), "filter must not run when correction fails")
    }
}
