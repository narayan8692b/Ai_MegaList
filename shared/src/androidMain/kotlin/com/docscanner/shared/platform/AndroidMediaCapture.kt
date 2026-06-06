package com.docscanner.shared.platform

import android.content.Context
import android.net.Uri
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.platform.MediaCapture
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Android [MediaCapture] that delegates the UI-bound work (camera intent / photo picker)
 * to [MediaCaptureBridge], which the host Activity wires up with Activity Result launchers.
 *
 * Gallery selections are content URIs; we copy their bytes into app-private storage via
 * [FileStorage] so the rest of the pipeline only deals with stable file paths.
 */
class AndroidMediaCapture(
    private val fileStorage: FileStorage,
) : MediaCapture {

    // Application context is required only to resolve content-resolver streams for gallery
    // picks. We obtain it lazily from the foreground activity to avoid an extra DI param.
    private val context: Context?
        get() = ActivityHolder.currentActivity?.applicationContext

    override suspend fun captureFromCamera(): DataResult<String?> {
        val launch = MediaCaptureBridge.onLaunchCamera
            ?: return DataResult.Failure(AppError.Camera("Camera launcher not registered"))
        return try {
            val deferred = CompletableDeferred<String?>()
            MediaCaptureBridge.cameraResult = deferred
            withContext(Dispatchers.Main) { launch() }
            DataResult.Success(deferred.await())
        } catch (e: Throwable) {
            MediaCaptureBridge.cameraResult = null
            DataResult.Failure(AppError.Camera("Camera capture failed", e))
        }
    }

    override suspend fun pickFromGallery(allowMultiple: Boolean): DataResult<List<String>> {
        val launch = MediaCaptureBridge.onLaunchGallery
            ?: return DataResult.Failure(AppError.Storage("Gallery launcher not registered"))
        return try {
            val deferred = CompletableDeferred<List<Uri>>()
            MediaCaptureBridge.galleryResult = deferred
            withContext(Dispatchers.Main) { launch(allowMultiple) }
            val uris = deferred.await()
            val paths = withContext(Dispatchers.IO) { uris.mapNotNull { copyIntoStorage(it) } }
            DataResult.Success(paths)
        } catch (e: Throwable) {
            MediaCaptureBridge.galleryResult = null
            DataResult.Failure(AppError.Storage("Gallery import failed", e))
        }
    }

    /** Copy a picked content [uri] into the originals directory; returns the new path. */
    private fun copyIntoStorage(uri: Uri): String? {
        val ctx = context ?: return null
        val destPath = fileStorage.newFilePath(fileStorage.originalsDir(), "jpg")
        return try {
            ctx.contentResolver.openInputStream(uri)?.use { input ->
                File(destPath).outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            destPath
        } catch (e: Throwable) {
            null
        }
    }
}
