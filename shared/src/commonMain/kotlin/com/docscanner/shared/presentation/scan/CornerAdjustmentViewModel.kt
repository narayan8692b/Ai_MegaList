package com.docscanner.shared.presentation.scan

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.CapturedImage
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.PointF
import com.docscanner.shared.domain.usecase.DetectEdgesUseCase
import com.docscanner.shared.domain.usecase.ProcessPageUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Identifies which of the four corners is being dragged. */
enum class CornerHandle { TOP_LEFT, TOP_RIGHT, BOTTOM_RIGHT, BOTTOM_LEFT }

/** UI state for the corner-adjustment screen. */
data class CornerUiState(
    val capture: CapturedImage? = null,
    /** Live, user-editable corners (normalized 0..1). */
    val corners: DocumentCorners = DocumentCorners.FULL,
    val isProcessing: Boolean = false,
    val errorMessage: String? = null,
    /** When set, the corrected image is ready and the host should advance to filters. */
    val confirmed: Boolean = false,
)

/**
 * Backs the corner-adjustment screen. Reads the active capture from the shared
 * [ScanSessionStore], lets the user drag corners, can re-run auto edge detection, reset to
 * full bounds, and on confirm runs [ProcessPageUseCase] to produce the perspective-corrected
 * image before advancing to the filter screen.
 */
class CornerAdjustmentViewModel(
    private val store: ScanSessionStore,
    private val detectEdges: DetectEdgesUseCase,
    private val processPage: ProcessPageUseCase,
) : ViewModel() {

    private val _state = MutableStateFlow(
        CornerUiState(
            capture = store.activeCapture.value,
            corners = store.activeCorners,
        ),
    )
    val state: StateFlow<CornerUiState> = _state.asStateFlow()

    /**
     * Update one corner to a new normalized position, clamped to [0,1]. Called continuously
     * during a drag gesture.
     */
    fun moveCorner(handle: CornerHandle, normX: Float, normY: Float) {
        val p = PointF(normX.coerceIn(0f, 1f), normY.coerceIn(0f, 1f))
        val c = _state.value.corners
        val updated = when (handle) {
            CornerHandle.TOP_LEFT -> c.copy(topLeft = p)
            CornerHandle.TOP_RIGHT -> c.copy(topRight = p)
            CornerHandle.BOTTOM_RIGHT -> c.copy(bottomRight = p)
            CornerHandle.BOTTOM_LEFT -> c.copy(bottomLeft = p)
        }
        _state.value = _state.value.copy(corners = updated)
        store.activeCorners = updated
    }

    /** Re-run automatic edge detection on the active capture. */
    fun autoDetect() {
        val capture = _state.value.capture ?: return
        if (_state.value.isProcessing) return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isProcessing = true, errorMessage = null)
            val detected = detectEdges(capture.imagePath).getOrNull() ?: DocumentCorners.FULL
            store.activeCorners = detected
            _state.value = _state.value.copy(isProcessing = false, corners = detected)
        }
    }

    /** Reset corners to the full image bounds. */
    fun reset() {
        store.activeCorners = DocumentCorners.FULL
        _state.value = _state.value.copy(corners = DocumentCorners.FULL)
    }

    /** Apply perspective correction with the current corners + filter, then advance. */
    fun confirm() {
        val capture = _state.value.capture ?: return
        if (_state.value.isProcessing) return
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(isProcessing = true, errorMessage = null)
            when (
                val result = processPage(
                    imagePath = capture.imagePath,
                    corners = _state.value.corners,
                    filter = store.activeFilter,
                )
            ) {
                is DataResult.Failure ->
                    _state.value = _state.value.copy(
                        isProcessing = false,
                        errorMessage = result.error.message,
                    )

                is DataResult.Success -> {
                    store.activeCorrectedPath = result.data
                    _state.value = _state.value.copy(isProcessing = false, confirmed = true)
                }
            }
        }
    }

    fun onConfirmConsumed() {
        _state.value = _state.value.copy(confirmed = false)
    }
}
