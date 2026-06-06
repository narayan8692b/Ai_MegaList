package com.docscanner.shared.presentation.documents

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.usecase.SearchDocumentsUseCase
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn

/** UI state for full-text search. */
data class SearchUiState(
    val query: String = "",
    val results: List<Document> = emptyList(),
)

/** Debounced full-text search across titles, tags and OCR text. */
@OptIn(ExperimentalCoroutinesApi::class, FlowPreview::class)
class SearchViewModel(
    private val searchDocuments: SearchDocumentsUseCase,
) : ViewModel() {

    private val query = MutableStateFlow("")

    private val results = query
        .debounce(250)
        .flatMapLatest { q -> if (q.isBlank()) flowOf(emptyList()) else searchDocuments(q) }

    val state: StateFlow<SearchUiState> = combine(query, results) { q, r ->
        SearchUiState(query = q, results = r)
    }.stateIn(viewModelScope, SharingStarted.Eagerly, SearchUiState())

    fun onQueryChange(value: String) {
        query.value = value
    }
}
