package com.docscanner.shared.domain

import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.PointF
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class GeometryTest {

    @Test
    fun fromList_toList_roundTrip() {
        val points = listOf(
            PointF(0.1f, 0.2f),
            PointF(0.9f, 0.15f),
            PointF(0.85f, 0.95f),
            PointF(0.05f, 0.9f),
        )
        val corners = DocumentCorners.fromList(points)

        assertEquals(points[0], corners.topLeft)
        assertEquals(points[1], corners.topRight)
        assertEquals(points[2], corners.bottomRight)
        assertEquals(points[3], corners.bottomLeft)
        assertEquals(points, corners.toList())
    }

    @Test
    fun fromList_requiresExactlyFourPoints() {
        assertFailsWith<IllegalArgumentException> {
            DocumentCorners.fromList(listOf(PointF(0f, 0f), PointF(1f, 1f)))
        }
    }

    @Test
    fun full_coversWholeImage() {
        val full = DocumentCorners.FULL
        assertEquals(PointF(0f, 0f), full.topLeft)
        assertEquals(PointF(1f, 0f), full.topRight)
        assertEquals(PointF(1f, 1f), full.bottomRight)
        assertEquals(PointF(0f, 1f), full.bottomLeft)
    }

    @Test
    fun serialization_roundTrip() {
        val original = DocumentCorners(
            topLeft = PointF(0.12f, 0.34f),
            topRight = PointF(0.88f, 0.30f),
            bottomRight = PointF(0.90f, 0.92f),
            bottomLeft = PointF(0.10f, 0.95f),
        )
        val json = Json.encodeToString(DocumentCorners.serializer(), original)
        val decoded = Json.decodeFromString(DocumentCorners.serializer(), json)
        assertEquals(original, decoded)
    }
}
