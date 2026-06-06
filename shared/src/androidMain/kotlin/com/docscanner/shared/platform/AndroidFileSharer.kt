package com.docscanner.shared.platform

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.docscanner.shared.domain.platform.FileSharer
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.ArrayList

/**
 * Android [FileSharer] using the system share sheet ([Intent.ACTION_SEND] /
 * [Intent.ACTION_SEND_MULTIPLE]) with content URIs exposed through the app's
 * [FileProvider] (authority `com.docscanner.fileprovider`).
 */
class AndroidFileSharer(private val context: Context) : FileSharer {

    private val authority = "com.docscanner.fileprovider"

    private fun uriFor(path: String): Uri =
        FileProvider.getUriForFile(context, authority, File(path))

    override suspend fun shareFile(path: String, mimeType: String): DataResult<Unit> =
        withContext(Dispatchers.Main) {
            try {
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = mimeType
                    putExtra(Intent.EXTRA_STREAM, uriFor(path))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                launch(intent)
                DataResult.Success(Unit)
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("Unable to share file", e))
            }
        }

    override suspend fun shareFiles(paths: List<String>, mimeType: String): DataResult<Unit> =
        withContext(Dispatchers.Main) {
            try {
                val uris = ArrayList(paths.map { uriFor(it) })
                val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                    type = mimeType
                    putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                launch(intent)
                DataResult.Success(Unit)
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("Unable to share files", e))
            }
        }

    private fun launch(intent: Intent) {
        val chooser = Intent.createChooser(intent, "Share")
        val activity = ActivityHolder.currentActivity
        if (activity != null) {
            activity.startActivity(chooser)
        } else {
            // No foreground activity; start from application context.
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)
        }
    }
}
