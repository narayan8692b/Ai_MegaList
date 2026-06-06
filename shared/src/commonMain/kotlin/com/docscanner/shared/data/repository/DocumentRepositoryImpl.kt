package com.docscanner.shared.data.repository

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import app.cash.sqldelight.coroutines.mapToOneOrNull
import com.docscanner.shared.data.mapper.toColumns
import com.docscanner.shared.data.mapper.toDomain
import com.docscanner.shared.database.DocScannerDatabase
import com.docscanner.shared.database.DocumentEntity
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Page
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

/**
 * SQLDelight-backed [DocumentRepository]. Document rows live in `DocumentEntity` while a
 * document's [Page]s and [com.docscanner.shared.domain.model.Tag]s live in their own tables;
 * the reactive queries here combine those streams to emit fully-assembled [Document]s.
 */
class DocumentRepositoryImpl(
    private val database: DocScannerDatabase,
    private val dispatcher: CoroutineDispatcher,
) : DocumentRepository {

    private val documentQueries get() = database.documentEntityQueries
    private val pageQueries get() = database.pageEntityQueries
    private val tagQueries get() = database.tagEntityQueries

    // ---- Reactive reads -----------------------------------------------------

    override fun observeDocuments(folderId: String?): Flow<List<Document>> {
        val rowsFlow = if (folderId == null) {
            documentQueries.selectAll().asFlow().mapToList(dispatcher)
        } else {
            documentQueries.selectByFolder(folderId).asFlow().mapToList(dispatcher)
        }
        return rowsFlow.assembleList()
    }

    override fun observeDocument(id: String): Flow<Document?> =
        documentQueries.selectById(id).asFlow().mapToOneOrNull(dispatcher)
            .flatMapLatest { row ->
                if (row == null) flowOf(null) else row.assembleOne()
            }

    override fun searchDocuments(query: String): Flow<List<Document>> =
        documentQueries.search(query).asFlow().mapToList(dispatcher).assembleList()

    /** Joins each document row with its pages + tags streams to build full [Document]s. */
    private fun Flow<List<DocumentEntity>>.assembleList(): Flow<List<Document>> =
        flatMapLatest { rows ->
            if (rows.isEmpty()) {
                flowOf(emptyList())
            } else {
                combine(rows.map { it.assembleOne() }) { it.toList() }
            }
        }

    private fun DocumentEntity.assembleOne(): Flow<Document> {
        val row = this
        val pagesFlow = pageQueries.selectByDocument(row.id).asFlow().mapToList(dispatcher)
        val tagsFlow = tagQueries.selectTagsForDocument(row.id).asFlow().mapToList(dispatcher)
        return combine(pagesFlow, tagsFlow) { pageRows, tagRows ->
            row.toDomain(
                pages = pageRows.map { it.toDomain() },
                tags = tagRows.map { it.toDomain() },
            )
        }
    }

    // ---- One-shot reads -----------------------------------------------------

    override suspend fun getDocument(id: String): DataResult<Document> = storage {
        val row = documentQueries.selectById(id).executeAsOneOrNull()
            ?: return@storage DataResult.Failure(AppError.NotFound("Document $id not found"))
        val pages = pageQueries.selectByDocument(id).executeAsList().map { it.toDomain() }
        val tags = tagQueries.selectTagsForDocument(id).executeAsList().map { it.toDomain() }
        DataResult.Success(row.toDomain(pages, tags))
    }

    // ---- Writes -------------------------------------------------------------

    override suspend fun upsertDocument(document: Document): DataResult<Unit> = storageUnit {
        val doc = document.toColumns()
        database.transaction {
            documentQueries.upsert(
                id = doc.id,
                title = doc.title,
                folderId = doc.folderId,
                ocrText = doc.ocrText,
                createdAt = doc.createdAt,
                updatedAt = doc.updatedAt,
                isFavorite = doc.isFavorite,
                isLocked = doc.isLocked,
                syncStatus = doc.syncStatus,
            )
            document.pages.forEach { page ->
                val p = page.toColumns()
                pageQueries.upsert(
                    id = p.id,
                    documentId = p.documentId,
                    orderIndex = p.orderIndex,
                    originalImagePath = p.originalImagePath,
                    processedImagePath = p.processedImagePath,
                    corners = p.corners,
                    filter = p.filter,
                    ocrText = p.ocrText,
                    width = p.width,
                    height = p.height,
                )
            }
        }
    }

    override suspend fun addPage(documentId: String, page: Page): DataResult<Unit> = storageUnit {
        val p = page.copy(documentId = documentId).toColumns()
        pageQueries.upsert(
            id = p.id,
            documentId = p.documentId,
            orderIndex = p.orderIndex,
            originalImagePath = p.originalImagePath,
            processedImagePath = p.processedImagePath,
            corners = p.corners,
            filter = p.filter,
            ocrText = p.ocrText,
            width = p.width,
            height = p.height,
        )
    }

    override suspend fun deleteDocument(id: String): DataResult<Unit> = storageUnit {
        // Pages are removed via FK ON DELETE CASCADE when enabled; delete explicitly too
        // so the operation is correct regardless of the driver's foreign-key setting.
        database.transaction {
            pageQueries.deleteByDocument(id)
            documentQueries.deleteById(id)
        }
    }

    override suspend fun setFavorite(id: String, favorite: Boolean): DataResult<Unit> = storageUnit {
        documentQueries.setFavorite(
            favorite = if (favorite) 1L else 0L,
            updatedAt = nowMillis(),
            id = id,
        )
    }

    override suspend fun setLocked(id: String, locked: Boolean): DataResult<Unit> = storageUnit {
        documentQueries.setLocked(
            locked = if (locked) 1L else 0L,
            updatedAt = nowMillis(),
            id = id,
        )
    }

    override suspend fun moveToFolder(documentId: String, folderId: String?): DataResult<Unit> =
        storageUnit {
            documentQueries.moveToFolder(
                folderId = folderId,
                updatedAt = nowMillis(),
                id = documentId,
            )
        }

    override suspend fun updateSyncStatus(id: String, status: SyncStatus): DataResult<Unit> =
        storageUnit {
            documentQueries.updateSyncStatus(syncStatus = status.name, id = id)
        }

    // ---- Helpers ------------------------------------------------------------

    private fun nowMillis(): Long =
        kotlinx.datetime.Clock.System.now().toEpochMilliseconds()

    private suspend inline fun <T> storage(
        crossinline block: suspend () -> DataResult<T>,
    ): DataResult<T> = withContext(dispatcher) {
        try {
            block()
        } catch (t: Throwable) {
            DataResult.Failure(AppError.Storage(t.message ?: "Database error", t))
        }
    }

    private suspend inline fun storageUnit(
        crossinline block: suspend () -> Unit,
    ): DataResult<Unit> = withContext(dispatcher) {
        try {
            block()
            DataResult.Success(Unit)
        } catch (t: Throwable) {
            DataResult.Failure(AppError.Storage(t.message ?: "Database error", t))
        }
    }
}
