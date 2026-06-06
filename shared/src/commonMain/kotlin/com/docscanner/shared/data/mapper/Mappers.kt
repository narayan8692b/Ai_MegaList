package com.docscanner.shared.data.mapper

import com.docscanner.shared.database.DocumentEntity
import com.docscanner.shared.database.PageEntity
import com.docscanner.shared.database.TagEntity
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.Page
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.model.Tag
import kotlinx.serialization.json.Json

/**
 * Pure mapping functions between SQLDelight row types and domain models.
 *
 * [DocumentCorners] is persisted in the `corners TEXT` column as kotlinx-serialization
 * JSON. Enum columns ([SyncStatus], [ScanFilter]) are stored by [Enum.name] and decoded
 * with a safe fallback so that an unknown/legacy value never crashes the read path.
 */
internal val MapperJson: Json = Json {
    ignoreUnknownKeys = true
    encodeDefaults = true
}

// ---- Enum helpers -----------------------------------------------------------

private inline fun <reified T : Enum<T>> safeValueOf(name: String?, default: T): T =
    name?.let { value -> enumValues<T>().firstOrNull { it.name == value } } ?: default

private fun String.toSyncStatus(): SyncStatus =
    safeValueOf(this, SyncStatus.LOCAL_ONLY)

private fun String.toScanFilter(): ScanFilter =
    safeValueOf(this, ScanFilter.ORIGINAL)

// ---- Corners (de)serialization ----------------------------------------------

private fun encodeCorners(corners: DocumentCorners?): String? =
    corners?.let { MapperJson.encodeToString(DocumentCorners.serializer(), it) }

private fun decodeCorners(raw: String?): DocumentCorners? =
    raw?.takeIf { it.isNotBlank() }?.let {
        runCatching { MapperJson.decodeFromString(DocumentCorners.serializer(), it) }.getOrNull()
    }

// ---- Page -------------------------------------------------------------------

fun PageEntity.toDomain(): Page = Page(
    id = id,
    documentId = documentId,
    orderIndex = orderIndex.toInt(),
    originalImagePath = originalImagePath,
    processedImagePath = processedImagePath,
    corners = decodeCorners(corners),
    filter = filter.toScanFilter(),
    ocrText = ocrText,
    width = width.toInt(),
    height = height.toInt(),
)

/** Column values for `pageEntityQueries.upsert`, in declared order. */
class PageColumns(
    val id: String,
    val documentId: String,
    val orderIndex: Long,
    val originalImagePath: String,
    val processedImagePath: String,
    val corners: String?,
    val filter: String,
    val ocrText: String,
    val width: Long,
    val height: Long,
)

fun Page.toColumns(): PageColumns = PageColumns(
    id = id,
    documentId = documentId,
    orderIndex = orderIndex.toLong(),
    originalImagePath = originalImagePath,
    processedImagePath = processedImagePath,
    corners = encodeCorners(corners),
    filter = filter.name,
    ocrText = ocrText,
    width = width.toLong(),
    height = height.toLong(),
)

// ---- Tag --------------------------------------------------------------------

fun TagEntity.toDomain(): Tag = Tag(
    id = id,
    name = name,
    color = color,
)

// ---- Document ---------------------------------------------------------------

/**
 * Maps a [DocumentEntity] row to a [Document], attaching the already-loaded [pages] and
 * [tags] which live in separate tables and are fetched by the repository.
 */
fun DocumentEntity.toDomain(pages: List<Page>, tags: List<Tag>): Document = Document(
    id = id,
    title = title,
    pages = pages,
    folderId = folderId,
    tags = tags,
    ocrText = ocrText,
    createdAt = createdAt,
    updatedAt = updatedAt,
    isFavorite = isFavorite != 0L,
    isLocked = isLocked != 0L,
    syncStatus = syncStatus.toSyncStatus(),
)

/** Column values for `documentEntityQueries.upsert`, in declared order. */
class DocumentColumns(
    val id: String,
    val title: String,
    val folderId: String?,
    val ocrText: String,
    val createdAt: Long,
    val updatedAt: Long,
    val isFavorite: Long,
    val isLocked: Long,
    val syncStatus: String,
)

fun Document.toColumns(): DocumentColumns = DocumentColumns(
    id = id,
    title = title,
    folderId = folderId,
    ocrText = ocrText,
    createdAt = createdAt,
    updatedAt = updatedAt,
    isFavorite = if (isFavorite) 1L else 0L,
    isLocked = if (isLocked) 1L else 0L,
    syncStatus = syncStatus.name,
)
