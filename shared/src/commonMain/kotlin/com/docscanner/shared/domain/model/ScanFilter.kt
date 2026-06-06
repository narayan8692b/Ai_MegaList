package com.docscanner.shared.domain.model

/**
 * Image enhancement filters applied after perspective correction. Implementations of
 * the platform `ImageProcessor` map each value to a concrete pixel transform.
 */
enum class ScanFilter(val displayName: String) {
    ORIGINAL("Original"),
    MAGIC_COLOR("Magic Color"),
    BLACK_AND_WHITE("Black & White"),
    GRAYSCALE("Grayscale"),
    HIGH_CONTRAST("High Contrast"),
}
