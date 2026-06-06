package com.docscanner.shared.platform

import android.net.Uri
import kotlinx.coroutines.CompletableDeferred

/**
 * Bridges the shared [com.docscanner.shared.domain.platform.MediaCapture] abstraction to the
 * Android Activity Result APIs, which can only be registered from an Activity/Fragment.
 *
 * The host `MainActivity` registers the launchers (camera + gallery picker) and assigns the
 * [onLaunchCamera] / [onLaunchGallery] callbacks. [AndroidMediaCapture] then invokes those
 * callbacks and awaits results via [CompletableDeferred].
 */
object MediaCaptureBridge {

    /**
     * Invoked to launch the camera. The Activity must:
     *  - create a temp output file + FileProvider [Uri],
     *  - launch its `TakePicture` launcher with that uri,
     *  - on result, complete [cameraResult] with the file path (or null if cancelled).
     */
    var onLaunchCamera: (() -> Unit)? = null

    /**
     * Invoked to launch the gallery picker. The boolean indicates whether multiple
     * selection is allowed. On result, the Activity completes [galleryResult] with the
     * selected content [Uri]s (empty if cancelled).
     */
    var onLaunchGallery: ((allowMultiple: Boolean) -> Unit)? = null

    /** Pending result holders, set by [AndroidMediaCapture] before launching. */
    @Volatile
    var cameraResult: CompletableDeferred<String?>? = null

    @Volatile
    var galleryResult: CompletableDeferred<List<Uri>>? = null

    /** Called by the Activity's camera launcher callback. */
    fun completeCamera(path: String?) {
        cameraResult?.complete(path)
        cameraResult = null
    }

    /** Called by the Activity's gallery launcher callback. */
    fun completeGallery(uris: List<Uri>) {
        galleryResult?.complete(uris)
        galleryResult = null
    }
}
