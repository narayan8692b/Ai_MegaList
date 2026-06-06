package com.docscanner.shared.presentation.scan

import com.docscanner.shared.domain.model.CapturedImage
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.ScanPage
import com.docscanner.shared.domain.model.ScanSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Holds the in-progress [ScanSession] shared across the capture flow screens
 * (Scan -> CornerAdjustment -> Filter). Registered as a Koin `single` so the same instance
 * is injected into every scan-flow ViewModel.
 *
 * The session is kept here (rather than inside a single ViewModel) because the lightweight
 * navigator pushes separate screens — each with its own ViewModel — that must mutate one
 * coherent draft document.
 */
class ScanSessionStore {

    private val _session = MutableStateFlow(ScanSession(documentTitle = ""))
    val session: StateFlow<ScanSession> = _session.asStateFlow()

    /** The capture currently being edited on the corner/filter screens (the last page added). */
    private val _activeCapture = MutableStateFlow<CapturedImage?>(null)
    val activeCapture: StateFlow<CapturedImage?> = _activeCapture.asStateFlow()

    /** Working corners for the active capture (edited on the corner screen). */
    var activeCorners: DocumentCorners = DocumentCorners.FULL

    /** Working filter for the active capture (edited on the filter screen). */
    var activeFilter: ScanFilter = ScanFilter.MAGIC_COLOR

    /** Path of the perspective-corrected image produced after confirming corners. */
    var activeCorrectedPath: String? = null

    fun reset(defaultFilter: ScanFilter) {
        _session.value = ScanSession(documentTitle = "")
        _activeCapture.value = null
        activeCorners = DocumentCorners.FULL
        activeFilter = defaultFilter
        activeCorrectedPath = null
    }

    /** Begin editing a freshly captured/imported image. */
    fun beginCapture(capture: CapturedImage, defaultFilter: ScanFilter) {
        _activeCapture.value = capture
        activeCorners = capture.detectedCorners
        activeFilter = defaultFilter
        activeCorrectedPath = null
    }

    /** Commit the active capture as a finished [ScanPage] in the session. */
    fun commitActivePage(id: String) {
        val capture = _activeCapture.value ?: return
        val page = ScanPage(
            id = id,
            original = capture,
            corners = activeCorners,
            filter = activeFilter,
            processedImagePath = activeCorrectedPath,
        )
        _session.value = _session.value.copy(pages = _session.value.pages + page)
        _activeCapture.value = null
    }

    fun setTitle(title: String) {
        _session.value = _session.value.copy(documentTitle = title)
    }

    fun removePage(pageId: String) {
        _session.value = _session.value.copy(
            pages = _session.value.pages.filterNot { it.id == pageId },
        )
    }
}
