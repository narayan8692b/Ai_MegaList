package com.docscanner.shared.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.usecase.GetDocumentsUseCase
import com.docscanner.shared.domain.usecase.ToggleFavoriteUseCase
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.launchIn

/** UI state for the Home screen. */
data class HomeUiState(
    val isLoading: Boolean = true,
    val recent: List<Document> = emptyList(),
    val favorites: List<Document> = emptyList(),
)

/**
 * Drives the Home dashboard: observes all documents, derives the most-recent and the
 * favourite subsets, and exposes a favourite toggle.
 */
class HomeViewModel(
    getDocuments: GetDocumentsUseCase,
    private val toggleFavorite: ToggleFavoriteUseCase,
) : ViewModel() {

    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    init {
        getDocuments()
            .onEach { docs ->
                _state.value = HomeUiState(
                    isLoading = false,
                    recent = docs.sortedByDescending { it.updatedAt }.take(10),
                    favorites = docs.filter { it.isFavorite },
                )
            }
            .launchIn(viewModelScope)
    }

    fun onToggleFavorite(document: Document) {
        viewModelScope.launchSafe {
            toggleFavorite(document.id, !document.isFavorite)
        }
    }
}
