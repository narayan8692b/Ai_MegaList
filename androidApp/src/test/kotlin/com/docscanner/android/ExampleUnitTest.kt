package com.docscanner.android

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Minimal JVM unit-test smoke check for the Android application module.
 *
 * The bulk of the business logic lives in the shared KMP module and is covered by its
 * `commonTest` suite. This placeholder keeps the `:androidApp:testDebugUnitTest` task
 * green without depending on any platform-team source files.
 */
class ExampleUnitTest {

    @Test
    fun arithmetic_isCorrect() {
        assertEquals(4, 2 + 2)
    }
}
