package com.docscanner.shared.presentation.scan

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.usecase.ApplyFilterUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** UI state for the filter-selection screen. */
data class FilterUiState(
    val availableFilters: List<ScanFilter> = ScanFilter.entries.toList(),
    val selected: ScanFilter = ScanFilter.MAGIC_COLOR,
    /** Path to the current preview image (perspective-corrected + selected filter applied). */
    val previewPath: String? = null,
    val isProcessing: Boolean = false,
    val errorMessage: String? = null,
    /** Set when the page was committed and the host should add another page (go to Scan). */
    val addAnother: Boolean = false,
    /** Set when the whole scan is finalized; host opens this document id. */
    val savedDocumentId: String? = null,
)

/**
 * Backs the filter screen. The base (perspective-corrected) image comes from the shared
 * [ScanSessionStore]; selecting a filter runs [ApplyFilterUseCase] for a live preview.
 * "Save page" commits the active page; "Done" / finalize is delegated back to the scan flow
 * via the host (which calls [ScanViewModel.finish]).
 */
class FilterViewModel(
    private val store: ScanSessionStore,
    private val applyFilter: ApplyFilterUseCase,
    private val idGenerator: IdGenerator,
) : ViewModel() {

    private val correctedBasePath: String? = store.activeCorrectedPath

    /** The most recent filtered preview path (defaults to the unfiltered corrected base). */
    private var filteredPath: String? = store.activeCorrectedPath

    private val _state = MutableStateFlow(
        FilterUiState(
            selected = store.activeFilter,
            previewPath = store.activeCorrectedPath,
        ),
    )
    val state: StateFlow<FilterUiState> = _state.asStateFlow()

    /** Select a filter and render a fresh preview from the corrected base image. */
    fun selectFilter(filter: ScanFilter) {
        store.activeFilter = filter
        _state.value = _state.value.copy(selected = filter)
        val base = correctedBasePath ?: return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isProcessing = true, errorMessage = null)
            when (val result = applyFilter(base, filter)) {
                is DataResult.Failure ->
                    _state.value = _state.value.copy(
                        isProcessing = false,
                        errorMessage = result.error.message,
                    )

                is DataResult.Success -> {
                    // Keep the corrected base intact; only the preview/committed path changes.
                    filteredPath = result.data
                    _state.value = _state.value.copy(
                        isProcessing = false,
                        previewPath = result.data,
                    )
                }
            }
        }
    }

    /** Commit the active page into the session and signal to capture another. */
    fun savePageAndAddAnother() {
        store.activeCorrectedPath = filteredPath
        store.commitActivePage(idGenerator.newId())
        _state.value = _state.value.copy(addAnother = true)
    }

    /** Commit the active page; the host then finalizes the whole scan. */
    fun savePageForFinish() {
        store.activeCorrectedPath = filteredPath
        store.commitActivePage(idGenerator.newId())
    }

    fun onAddAnotherConsumed() {
        _state.value = _state.value.copy(addAnother = false)
    }
}
