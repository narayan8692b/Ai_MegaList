package com.docscanner.shared.presentation.documents

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.usecase.DeleteDocumentUseCase
import com.docscanner.shared.domain.usecase.GetDocumentsUseCase
import com.docscanner.shared.domain.usecase.MoveDocumentUseCase
import com.docscanner.shared.domain.usecase.ToggleFavoriteUseCase
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

/** UI state for a folder's contents. */
data class FolderDetailUiState(
    val isLoading: Boolean = true,
    val documents: List<Document> = emptyList(),
)

/** Observes the documents contained in a single folder. */
class FolderDetailViewModel(
    private val folderId: String,
    getDocuments: GetDocumentsUseCase,
    private val toggleFavorite: ToggleFavoriteUseCase,
    private val deleteDocument: DeleteDocumentUseCase,
    private val moveDocument: MoveDocumentUseCase,
) : ViewModel() {

    val state: StateFlow<FolderDetailUiState> = getDocuments(folderId)
        .map { FolderDetailUiState(isLoading = false, documents = it) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, FolderDetailUiState())

    fun onToggleFavorite(document: Document) {
        viewModelScope.launchSafe { toggleFavorite(document.id, !document.isFavorite) }
    }

    fun onDelete(documentId: String) {
        viewModelScope.launchSafe { deleteDocument(documentId) }
    }

    /** Remove a document from this folder (move to root). */
    fun onRemoveFromFolder(documentId: String) {
        viewModelScope.launchSafe { moveDocument(documentId, null) }
    }
}
