package com.docscanner.shared.domain

import com.docscanner.shared.domain.model.ScanFilter
import kotlin.test.Test
import kotlin.test.assertEquals

class ScanFilterTest {

    @Test
    fun allFiltersExist() {
        assertEquals(5, ScanFilter.entries.size)
        val names = ScanFilter.entries.map { it.name }.toSet()
        assertEquals(
            setOf("ORIGINAL", "MAGIC_COLOR", "BLACK_AND_WHITE", "GRAYSCALE", "HIGH_CONTRAST"),
            names,
        )
    }

    @Test
    fun displayNameMapping() {
        assertEquals("Original", ScanFilter.ORIGINAL.displayName)
        assertEquals("Magic Color", ScanFilter.MAGIC_COLOR.displayName)
        assertEquals("Black & White", ScanFilter.BLACK_AND_WHITE.displayName)
        assertEquals("Grayscale", ScanFilter.GRAYSCALE.displayName)
        assertEquals("High Contrast", ScanFilter.HIGH_CONTRAST.displayName)
    }
}
