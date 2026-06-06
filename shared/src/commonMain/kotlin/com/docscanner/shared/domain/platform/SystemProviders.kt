package com.docscanner.shared.domain.platform

/** Generates unique identifiers. Backed by platform UUID APIs. */
interface IdGenerator {
    fun newId(): String
}

/** Wall-clock time source, abstracted for testability. */
interface TimeProvider {
    fun nowMillis(): Long
}

/** Describes the running platform. */
interface PlatformInfo {
    val name: String
    val isAndroid: Boolean
    val isIos: Boolean
}
