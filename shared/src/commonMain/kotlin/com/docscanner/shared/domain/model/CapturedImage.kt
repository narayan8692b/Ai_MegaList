package com.docscanner.shared.domain.model

/**
 * An image produced by the camera or imported from the gallery, before it has been
 * turned into a [Page]. Held in the scan session until the user confirms corners,
 * filter and ordering.
 */
data class CapturedImage(
    val id: String,
    val imagePath: String,
    val width: Int,
    val height: Int,
    /** Auto-detected document corners, or [DocumentCorners.FULL] when none found. */
    val detectedCorners: DocumentCorners = DocumentCorners.FULL,
)
