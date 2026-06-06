package com.docscanner.shared.domain.model

import kotlinx.serialization.Serializable

/** A normalized point. Coordinates are in the range [0f, 1f] relative to image size. */
@Serializable
data class PointF(val x: Float, val y: Float)

/**
 * The four detected/adjusted corners of a document, ordered clockwise starting from
 * the top-left. All coordinates are normalized (0f..1f) so they remain valid across
 * image resizes and are independent of pixel dimensions.
 */
@Serializable
data class DocumentCorners(
    val topLeft: PointF,
    val topRight: PointF,
    val bottomRight: PointF,
    val bottomLeft: PointF,
) {
    fun toList(): List<PointF> = listOf(topLeft, topRight, bottomRight, bottomLeft)

    companion object {
        /** Corners covering the full image — the default when detection fails. */
        val FULL = DocumentCorners(
            topLeft = PointF(0f, 0f),
            topRight = PointF(1f, 0f),
            bottomRight = PointF(1f, 1f),
            bottomLeft = PointF(0f, 1f),
        )

        fun fromList(points: List<PointF>): DocumentCorners {
            require(points.size == 4) { "DocumentCorners requires exactly 4 points" }
            return DocumentCorners(points[0], points[1], points[2], points[3])
        }
    }
}
