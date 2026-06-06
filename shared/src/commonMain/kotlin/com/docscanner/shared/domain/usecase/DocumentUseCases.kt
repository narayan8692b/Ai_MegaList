package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow

/** Observe documents in a folder (or all when [folderId] is null). */
class GetDocumentsUseCase(private val repository: DocumentRepository) {
    operator fun invoke(folderId: String? = null): Flow<List<Document>> =
        repository.observeDocuments(folderId)
}

class GetDocumentUseCase(private val repository: DocumentRepository) {
    operator fun invoke(id: String): Flow<Document?> = repository.observeDocument(id)
}

/** Full-text search across titles, tags and extracted OCR text. */
class SearchDocumentsUseCase(private val repository: DocumentRepository) {
    operator fun invoke(query: String): Flow<List<Document>> =
        repository.searchDocuments(query.trim())
}

class DeleteDocumentUseCase(private val repository: DocumentRepository) {
    suspend operator fun invoke(id: String): DataResult<Unit> = repository.deleteDocument(id)
}

class ToggleFavoriteUseCase(private val repository: DocumentRepository) {
    suspend operator fun invoke(id: String, favorite: Boolean): DataResult<Unit> =
        repository.setFavorite(id, favorite)
}

class MoveDocumentUseCase(private val repository: DocumentRepository) {
    suspend operator fun invoke(documentId: String, folderId: String?): DataResult<Unit> =
        repository.moveToFolder(documentId, folderId)
}
