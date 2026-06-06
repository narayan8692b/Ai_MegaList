package com.docscanner.shared.presentation.documents

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Folder
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.domain.usecase.CreateFolderUseCase
import com.docscanner.shared.domain.usecase.DeleteDocumentUseCase
import com.docscanner.shared.domain.usecase.GetDocumentsUseCase
import com.docscanner.shared.domain.usecase.GetFoldersUseCase
import com.docscanner.shared.domain.usecase.GetTagsUseCase
import com.docscanner.shared.domain.usecase.MoveDocumentUseCase
import com.docscanner.shared.domain.usecase.SearchDocumentsUseCase
import com.docscanner.shared.domain.usecase.ToggleFavoriteUseCase
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn

/** UI state for the documents browser. */
data class DocumentsUiState(
    val isLoading: Boolean = true,
    val documents: List<Document> = emptyList(),
    val folders: List<Folder> = emptyList(),
    val tags: List<Tag> = emptyList(),
    val query: String = "",
    val selectedTagId: String? = null,
)

/**
 * Drives the documents browser. Observes documents (or search results when a query is set),
 * folders and tags, and supports favourite toggle, delete, move-to-folder, create-folder and
 * a tag filter applied client-side.
 */
@OptIn(ExperimentalCoroutinesApi::class, FlowPreview::class)
class DocumentsViewModel(
    private val getDocuments: GetDocumentsUseCase,
    private val searchDocuments: SearchDocumentsUseCase,
    getFolders: GetFoldersUseCase,
    getTags: GetTagsUseCase,
    private val toggleFavorite: ToggleFavoriteUseCase,
    private val deleteDocument: DeleteDocumentUseCase,
    private val moveDocument: MoveDocumentUseCase,
    private val createFolder: CreateFolderUseCase,
) : ViewModel() {

    private val query = MutableStateFlow("")
    private val selectedTagId = MutableStateFlow<String?>(null)

    private val documentsFlow = query
        .debounce(250)
        .flatMapLatest { q ->
            if (q.isBlank()) getDocuments(null) else searchDocuments(q)
        }

    val state: StateFlow<DocumentsUiState> = combine(
        documentsFlow,
        getFolders(null),
        getTags(),
        query,
        selectedTagId,
    ) { docs, folders, tags, q, tagId ->
        val filtered = if (tagId == null) docs else docs.filter { d -> d.tags.any { it.id == tagId } }
        DocumentsUiState(
            isLoading = false,
            documents = filtered,
            folders = folders,
            tags = tags,
            query = q,
            selectedTagId = tagId,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, DocumentsUiState())

    fun onQueryChange(value: String) {
        query.value = value
    }

    fun onTagSelected(tagId: String?) {
        selectedTagId.value = if (selectedTagId.value == tagId) null else tagId
    }

    fun onToggleFavorite(document: Document) {
        viewModelScope.launchSafe { toggleFavorite(document.id, !document.isFavorite) }
    }

    fun onDelete(documentId: String) {
        viewModelScope.launchSafe { deleteDocument(documentId) }
    }

    fun onMove(documentId: String, folderId: String?) {
        viewModelScope.launchSafe { moveDocument(documentId, folderId) }
    }

    fun onCreateFolder(name: String) {
        if (name.isBlank()) return
        viewModelScope.launchSafe { createFolder(name) }
    }
}
