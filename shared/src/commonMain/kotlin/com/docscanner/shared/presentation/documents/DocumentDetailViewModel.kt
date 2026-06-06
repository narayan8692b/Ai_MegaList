package com.docscanner.shared.presentation.documents

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.AppSettings
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.repository.SettingsRepository
import com.docscanner.shared.domain.usecase.ExportJpgUseCase
import com.docscanner.shared.domain.usecase.ExportOcrTextUseCase
import com.docscanner.shared.domain.usecase.GeneratePdfUseCase
import com.docscanner.shared.domain.usecase.GetDocumentUseCase
import com.docscanner.shared.domain.usecase.GetTagsUseCase
import com.docscanner.shared.domain.usecase.SetDocumentTagsUseCase
import com.docscanner.shared.domain.usecase.ShareFileUseCase
import com.docscanner.shared.domain.usecase.ToggleFavoriteUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.stateIn

/** A transient one-shot message for the document-detail screen (snackbars/toasts). */
data class DetailMessage(val text: String, val isError: Boolean = false)

/** UI state for the document-detail screen. */
data class DocumentDetailUiState(
    val document: Document? = null,
    val allTags: List<Tag> = emptyList(),
    val isBusy: Boolean = false,
    val message: DetailMessage? = null,
)

/**
 * Backs the document-detail screen: observes the document, exposes export (PDF/JPG/text) +
 * share, favourite/lock toggles, rename and tag editing. Exports use the configured
 * [AppSettings.pdfQuality]. After an export the produced path is shared via the native sheet.
 */
class DocumentDetailViewModel(
    private val documentId: String,
    getDocument: GetDocumentUseCase,
    getTags: GetTagsUseCase,
    private val generatePdf: GeneratePdfUseCase,
    private val exportJpg: ExportJpgUseCase,
    private val exportOcrText: ExportOcrTextUseCase,
    private val shareFile: ShareFileUseCase,
    private val toggleFavorite: ToggleFavoriteUseCase,
    private val setDocumentTags: SetDocumentTagsUseCase,
    private val documentRepository: DocumentRepository,
    settingsRepository: SettingsRepository,
) : ViewModel() {

    private val settings: StateFlow<AppSettings> =
        settingsRepository.observeSettings()
            .stateIn(viewModelScope, SharingStarted.Eagerly, AppSettings())

    private val _state = MutableStateFlow(DocumentDetailUiState())
    val state: StateFlow<DocumentDetailUiState> = _state.asStateFlow()

    init {
        getDocument(documentId)
            .onEach { doc -> _state.value = _state.value.copy(document = doc) }
            .launchIn(viewModelScope)
        getTags()
            .onEach { tags -> _state.value = _state.value.copy(allTags = tags) }
            .launchIn(viewModelScope)
    }

    fun onToggleFavorite() {
        val doc = _state.value.document ?: return
        viewModelScope.launchSafe { toggleFavorite(doc.id, !doc.isFavorite) }
    }

    fun onToggleLock() {
        val doc = _state.value.document ?: return
        viewModelScope.launchSafe { documentRepository.setLocked(doc.id, !doc.isLocked) }
    }

    fun onRename(newTitle: String) {
        val doc = _state.value.document ?: return
        if (newTitle.isBlank()) return
        viewModelScope.launchSafe {
            documentRepository.upsertDocument(doc.copy(title = newTitle.trim()))
        }
    }

    fun onSetTags(tagIds: List<String>) {
        val doc = _state.value.document ?: return
        viewModelScope.launchSafe { setDocumentTags(doc.id, tagIds) }
    }

    /** Generate a (optionally password-protected) PDF and share it. */
    fun exportAndSharePdf(password: String?) {
        val doc = _state.value.document ?: return
        runExport(successMessage = "PDF shared") {
            generatePdf(doc, settings.value.pdfQuality, password?.ifBlank { null })
                .shareAs("application/pdf")
        }
    }

    /** Export the first page as JPG and share it. */
    fun exportAndShareJpg() {
        val doc = _state.value.document ?: return
        val firstPage = doc.pages.firstOrNull()?.processedImagePath
        if (firstPage == null) {
            _state.value = _state.value.copy(message = DetailMessage("No page to export", true))
            return
        }
        runExport(successMessage = "Image shared") {
            exportJpg(firstPage, settings.value.pdfQuality).shareAs("image/jpeg")
        }
    }

    /** Export OCR text to a .txt file and share it. */
    fun exportAndShareText() {
        val doc = _state.value.document ?: return
        runExport(successMessage = "Text shared") {
            exportOcrText(doc).shareAs("text/plain")
        }
    }

    fun consumeMessage() {
        _state.value = _state.value.copy(message = null)
    }

    /** Run an export lambda that returns the final share result, updating busy/message state. */
    private fun runExport(successMessage: String, block: suspend () -> DataResult<Unit>) {
        if (_state.value.isBusy) return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isBusy = true)
            val result = block()
            _state.value = _state.value.copy(
                isBusy = false,
                message = when (result) {
                    is DataResult.Success -> DetailMessage(successMessage)
                    is DataResult.Failure -> DetailMessage(result.error.message, isError = true)
                },
            )
        }
    }

    /** Chain: take a produced-file result, then share it; propagate failures. */
    private suspend fun DataResult<String>.shareAs(mimeType: String): DataResult<Unit> =
        when (this) {
            is DataResult.Failure -> this
            is DataResult.Success -> shareFile(data, mimeType)
        }
}
