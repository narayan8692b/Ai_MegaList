package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.util.DataResult

/**
 * Native camera + gallery integration. Implementations launch the platform camera
 * (Android CameraX activity / iOS UIImagePickerController) or photo picker and return
 * the resulting image file paths copied into app storage.
 */
interface MediaCapture {
    /** Capture a single photo. Returns its file path, or null if the user cancelled. */
    suspend fun captureFromCamera(): DataResult<String?>

    /** Import one or more images from the gallery. */
    suspend fun pickFromGallery(allowMultiple: Boolean = true): DataResult<List<String>>
}
