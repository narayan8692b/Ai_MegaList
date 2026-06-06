package com.docscanner.android

import android.net.Uri
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import androidx.fragment.app.FragmentActivity
import com.docscanner.shared.platform.ActivityHolder
import com.docscanner.shared.platform.MediaCaptureBridge
import com.docscanner.shared.presentation.App
import java.io.File

/**
 * Host activity. Uses [FragmentActivity] (required by `BiometricPrompt`) and registers the
 * Activity Result launchers that back [MediaCaptureBridge] for camera + gallery capture,
 * then renders the shared Compose root [App].
 */
class MainActivity : FragmentActivity() {

    private lateinit var takePictureLauncher: ActivityResultLauncher<Uri>
    private lateinit var pickMediaLauncher: ActivityResultLauncher<PickVisualMediaRequest>
    private lateinit var pickMultipleMediaLauncher: ActivityResultLauncher<PickVisualMediaRequest>

    // Path/uri of the pending camera capture, awaiting the TakePicture result.
    private var pendingCameraPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        registerLaunchers()
        ActivityHolder.currentActivity = this

        setContent {
            App()
        }
    }

    private fun registerLaunchers() {
        // --- Camera: TakePicture writes the full-resolution photo to a FileProvider uri. ---
        takePictureLauncher = registerForActivityResult(
            ActivityResultContracts.TakePicture(),
        ) { success ->
            MediaCaptureBridge.completeCamera(if (success) pendingCameraPath else null)
            pendingCameraPath = null
        }

        // --- Gallery (single). ---
        pickMediaLauncher = registerForActivityResult(
            ActivityResultContracts.PickVisualMedia(),
        ) { uri ->
            MediaCaptureBridge.completeGallery(if (uri != null) listOf(uri) else emptyList())
        }

        // --- Gallery (multiple). ---
        pickMultipleMediaLauncher = registerForActivityResult(
            ActivityResultContracts.PickMultipleVisualMedia(),
        ) { uris ->
            MediaCaptureBridge.completeGallery(uris)
        }

        MediaCaptureBridge.onLaunchCamera = {
            val dir = File(filesDir, "originals").apply { mkdirs() }
            val file = File(dir, "${System.currentTimeMillis()}.jpg")
            pendingCameraPath = file.absolutePath
            val uri = FileProvider.getUriForFile(
                this,
                "com.docscanner.fileprovider",
                file,
            )
            takePictureLauncher.launch(uri)
        }

        MediaCaptureBridge.onLaunchGallery = { allowMultiple ->
            val request = PickVisualMediaRequest.Builder()
                .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly)
                .build()
            if (allowMultiple) {
                pickMultipleMediaLauncher.launch(request)
            } else {
                pickMediaLauncher.launch(request)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        ActivityHolder.currentActivity = this
    }

    override fun onDestroy() {
        if (ActivityHolder.currentActivity === this) {
            ActivityHolder.currentActivity = null
        }
        MediaCaptureBridge.onLaunchCamera = null
        MediaCaptureBridge.onLaunchGallery = null
        super.onDestroy()
    }
}
