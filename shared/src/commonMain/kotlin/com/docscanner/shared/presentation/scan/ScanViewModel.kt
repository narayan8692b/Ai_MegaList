package com.docscanner.shared.presentation.scan

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.AppSettings
import com.docscanner.shared.domain.model.CapturedImage
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.platform.MediaCapture
import com.docscanner.shared.domain.repository.SettingsRepository
import com.docscanner.shared.domain.usecase.DetectEdgesUseCase
import com.docscanner.shared.domain.usecase.SaveScanUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

/** UI state for the capture entry screen. */
data class ScanUiState(
    val isBusy: Boolean = false,
    val pageCount: Int = 0,
    val errorMessage: String? = null,
    /** Signals the host to navigate to corner adjustment for a freshly captured image. */
    val readyForCornerAdjustment: Boolean = false,
    /** When set, the scan was saved and the host should open this document id. */
    val savedDocumentId: String? = null,
)

/**
 * Drives the capture flow. Launches the camera or gallery picker, seeds detected corners,
 * and hands the active image to the shared [ScanSessionStore]. Multi-page scans accumulate
 * in the store; [finish] persists them via [SaveScanUseCase].
 */
class ScanViewModel(
    private val mediaCapture: MediaCapture,
    private val detectEdges: DetectEdgesUseCase,
    private val imageProcessor: ImageProcessor,
    private val idGenerator: IdGenerator,
    private val saveScan: SaveScanUseCase,
    private val store: ScanSessionStore,
    settingsRepository: SettingsRepository,
) : ViewModel() {

    private val settings: StateFlow<AppSettings> =
        settingsRepository.observeSettings()
            .stateIn(viewModelScope, SharingStarted.Eagerly, AppSettings())

    private val _state = MutableStateFlow(ScanUiState())
    val state: StateFlow<ScanUiState> = _state.asStateFlow()

    /** Number of pages already committed to the session. */
    val sessionPageCount: StateFlow<Int> = store.session
        .map { it.pages.size }
        .stateIn(viewModelScope, SharingStarted.Eagerly, 0)

    /** Capture a single photo from the camera, then prepare corner adjustment. */
    fun captureFromCamera() {
        if (_state.value.isBusy) return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isBusy = true, errorMessage = null)
            when (val result = mediaCapture.captureFromCamera()) {
                is DataResult.Failure -> fail(result.error.message)
                is DataResult.Success -> {
                    val path = result.data
                    if (path == null) {
                        _state.value = _state.value.copy(isBusy = false) // user cancelled
                    } else {
                        prepareCapture(path)
                    }
                }
            }
        }
    }

    /** Import one image (first selected) from the gallery, then prepare corner adjustment. */
    fun importFromGallery() {
        if (_state.value.isBusy) return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isBusy = true, errorMessage = null)
            when (val result = mediaCapture.pickFromGallery(allowMultiple = false)) {
                is DataResult.Failure -> fail(result.error.message)
                is DataResult.Success -> {
                    val path = result.data.firstOrNull()
                    if (path == null) {
                        _state.value = _state.value.copy(isBusy = false) // cancelled
                    } else {
                        prepareCapture(path)
                    }
                }
            }
        }
    }

    private suspend fun prepareCapture(path: String) {
        val (w, h) = imageProcessor.imageDimensions(path).getOrNull() ?: (0 to 0)
        val detected = if (settings.value.autoEdgeDetection) {
            detectEdges(path).getOrNull() ?: DocumentCorners.FULL
        } else {
            DocumentCorners.FULL
        }
        val capture = CapturedImage(
            id = idGenerator.newId(),
            imagePath = path,
            width = w,
            height = h,
            detectedCorners = detected,
        )
        store.beginCapture(capture, settings.value.defaultFilter)
        _state.value = _state.value.copy(isBusy = false, readyForCornerAdjustment = true)
    }

    fun onCornerAdjustmentConsumed() {
        _state.value = _state.value.copy(readyForCornerAdjustment = false)
    }

    /** Finalize the session into a persisted document. */
    fun finish() {
        if (_state.value.isBusy) return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isBusy = true, errorMessage = null)
            when (val result = saveScan(store.session.value)) {
                is DataResult.Failure -> fail(result.error.message)
                is DataResult.Success -> {
                    store.reset(settings.value.defaultFilter)
                    _state.value = _state.value.copy(
                        isBusy = false,
                        savedDocumentId = result.data.id,
                    )
                }
            }
        }
    }

    fun onSavedDocumentConsumed() {
        _state.value = _state.value.copy(savedDocumentId = null)
    }

    fun clearSession() {
        store.reset(settings.value.defaultFilter)
    }

    private fun fail(message: String) {
        _state.value = _state.value.copy(isBusy = false, errorMessage = message)
    }
}
