package com.docscanner.shared.data.provider

import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.platform.TimeProvider
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid
import kotlinx.datetime.Clock

/** [IdGenerator] backed by the Kotlin stdlib multiplatform UUID generator. */
class UuidIdGenerator : IdGenerator {
    @OptIn(ExperimentalUuidApi::class)
    override fun newId(): String = Uuid.random().toString()
}

/** [TimeProvider] backed by the system wall clock via kotlinx-datetime. */
class SystemTimeProvider : TimeProvider {
    override fun nowMillis(): Long = Clock.System.now().toEpochMilliseconds()
}
