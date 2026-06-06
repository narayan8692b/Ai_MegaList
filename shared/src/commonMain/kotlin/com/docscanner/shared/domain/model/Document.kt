package com.docscanner.shared.domain.model

/**
 * A scanned document composed of one or more [Page]s. Documents may be organized
 * into a [Folder] and decorated with [Tag]s. Extracted OCR text from every page is
 * concatenated into [ocrText] to support full-text search.
 */
data class Document(
    val id: String,
    val title: String,
    val pages: List<Page>,
    val folderId: String?,
    val tags: List<Tag>,
    val ocrText: String,
    val createdAt: Long,
    val updatedAt: Long,
    val isFavorite: Boolean = false,
    val isLocked: Boolean = false,
    val syncStatus: SyncStatus = SyncStatus.LOCAL_ONLY,
) {
    val pageCount: Int get() = pages.size
}
