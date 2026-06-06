package com.docscanner.shared.domain.repository

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Page
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow

interface DocumentRepository {
    /** Observe all documents, optionally filtered by folder. */
    fun observeDocuments(folderId: String? = null): Flow<List<Document>>

    fun observeDocument(id: String): Flow<Document?>

    /** Full-text search across titles, tags and extracted OCR text. */
    fun searchDocuments(query: String): Flow<List<Document>>

    suspend fun getDocument(id: String): DataResult<Document>

    suspend fun upsertDocument(document: Document): DataResult<Unit>

    suspend fun deleteDocument(id: String): DataResult<Unit>

    suspend fun setFavorite(id: String, favorite: Boolean): DataResult<Unit>

    suspend fun setLocked(id: String, locked: Boolean): DataResult<Unit>

    suspend fun moveToFolder(documentId: String, folderId: String?): DataResult<Unit>

    suspend fun addPage(documentId: String, page: Page): DataResult<Unit>

    suspend fun updateSyncStatus(id: String, status: SyncStatus): DataResult<Unit>
}
