package com.docscanner.shared.data.repository

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import com.docscanner.shared.data.mapper.toDomain
import com.docscanner.shared.database.DocScannerDatabase
import com.docscanner.shared.domain.model.Folder
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.domain.repository.FolderRepository
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

/**
 * SQLDelight-backed [FolderRepository] handling folders, tags and the document<->tag
 * cross-reference table. The `selectAll` / `selectByParent` queries project an extra
 * `documentCount` column (a correlated sub-query) which is surfaced on [Folder].
 */
class FolderRepositoryImpl(
    private val database: DocScannerDatabase,
    private val dispatcher: CoroutineDispatcher,
) : FolderRepository {

    private val folderQueries get() = database.folderEntityQueries
    private val tagQueries get() = database.tagEntityQueries

    // ---- Folders ------------------------------------------------------------

    override fun observeFolders(parentId: String?): Flow<List<Folder>> {
        return if (parentId == null) {
            folderQueries.selectAll().asFlow().mapToList(dispatcher).map { rows ->
                rows.map { Folder(it.id, it.name, it.parentId, it.color, it.createdAt, it.documentCount.toInt()) }
            }
        } else {
            folderQueries.selectByParent(parentId).asFlow().mapToList(dispatcher).map { rows ->
                rows.map { Folder(it.id, it.name, it.parentId, it.color, it.createdAt, it.documentCount.toInt()) }
            }
        }
    }

    override suspend fun createFolder(folder: Folder): DataResult<Unit> = storageUnit {
        folderQueries.insert(
            id = folder.id,
            name = folder.name,
            parentId = folder.parentId,
            color = folder.color,
            createdAt = folder.createdAt,
        )
    }

    override suspend fun renameFolder(id: String, name: String): DataResult<Unit> = storageUnit {
        folderQueries.rename(name = name, id = id)
    }

    override suspend fun deleteFolder(id: String): DataResult<Unit> = storageUnit {
        folderQueries.deleteById(id)
    }

    // ---- Tags ---------------------------------------------------------------

    override fun observeTags(): Flow<List<Tag>> =
        tagQueries.selectAllTags().asFlow().mapToList(dispatcher).map { rows ->
            rows.map { it.toDomain() }
        }

    override suspend fun createTag(tag: Tag): DataResult<Unit> = storageUnit {
        tagQueries.insertTag(id = tag.id, name = tag.name, color = tag.color)
    }

    override suspend fun deleteTag(id: String): DataResult<Unit> = storageUnit {
        tagQueries.deleteTag(id)
    }

    override suspend fun setDocumentTags(documentId: String, tagIds: List<String>): DataResult<Unit> =
        storageUnit {
            database.transaction {
                tagQueries.deleteCrossRefsForDocument(documentId)
                tagIds.forEach { tagId ->
                    tagQueries.insertCrossRef(documentId = documentId, tagId = tagId)
                }
            }
        }

    // ---- Helpers ------------------------------------------------------------

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
