package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.platform.MediaCapture
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import platform.Foundation.NSURL
import platform.PhotosUI.PHPickerConfiguration
import platform.PhotosUI.PHPickerFilter
import platform.PhotosUI.PHPickerResult
import platform.PhotosUI.PHPickerViewController
import platform.PhotosUI.PHPickerViewControllerDelegateProtocol
import platform.UIKit.UIApplication
import platform.UIKit.UIImage
import platform.UIKit.UIImageJPEGRepresentation
import platform.UIKit.UIImagePickerController
import platform.UIKit.UIImagePickerControllerDelegateProtocol
import platform.UIKit.UIImagePickerControllerOriginalImage
import platform.UIKit.UIImagePickerControllerSourceType
import platform.UIKit.UINavigationControllerDelegateProtocol
import platform.UIKit.UIViewController
import platform.UIKit.UIWindow
import platform.UIKit.UIWindowScene
import platform.darwin.NSObject
import platform.Foundation.writeToFile
import kotlin.coroutines.resume

/**
 * iOS [MediaCapture]:
 *  - [captureFromCamera] presents a [UIImagePickerController] with the camera source.
 *  - [pickFromGallery] presents a [PHPickerViewController] (modern, multi-select capable).
 *
 * Delegate-retention approach (important): UIKit holds its picker delegate WEAKLY. A Kotlin
 * delegate object created locally would be garbage-collected before the user finishes, so we
 * keep a strong reference in [retainedDelegate] for the lifetime of the presentation and
 * clear it inside the delegate callback (after we resume the coroutine). The continuation is
 * also captured by the delegate, keeping everything alive until completion.
 *
 * Selected images are re-encoded to JPEG and written into [fileStorage].originalsDir().
 */
@OptIn(ExperimentalForeignApi::class)
class IosMediaCapture(
    private val fileStorage: FileStorage,
) : MediaCapture {

    // Strong reference holder so the active delegate is not collected mid-presentation.
    private var retainedDelegate: NSObject? = null

    override suspend fun captureFromCamera(): DataResult<String?> =
        withContext(Dispatchers.Main) {
            val presenter = topViewController()
                ?: return@withContext DataResult.Failure(
                    AppError.Camera("No view controller available to present the camera"),
                )
            if (!UIImagePickerController.isSourceTypeAvailable(
                    UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera,
                )
            ) {
                return@withContext DataResult.Failure(AppError.Camera("Camera unavailable"))
            }

            suspendCancellableCoroutine { cont ->
                val picker = UIImagePickerController()
                picker.sourceType =
                    UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera

                val delegate = CameraPickerDelegate(
                    onResult = { image ->
                        retainedDelegate = null
                        val path = image?.let { saveImage(it) }
                        if (cont.isActive) cont.resume(DataResult.Success(path))
                    },
                )
                retainedDelegate = delegate
                picker.delegate = delegate
                presenter.presentViewController(picker, animated = true, completion = null)
            }
        }

    override suspend fun pickFromGallery(allowMultiple: Boolean): DataResult<List<String>> =
        withContext(Dispatchers.Main) {
            val presenter = topViewController()
                ?: return@withContext DataResult.Failure(
                    AppError.Camera("No view controller available to present the picker"),
                )

            suspendCancellableCoroutine { cont ->
                val config = PHPickerConfiguration()
                config.filter = PHPickerFilter.imagesFilter()
                config.selectionLimit = if (allowMultiple) 0L else 1L // 0 == unlimited

                val picker = PHPickerViewController(configuration = config)
                val delegate = GalleryPickerDelegate(
                    onResults = { images ->
                        retainedDelegate = null
                        val paths = images.mapNotNull { saveImage(it) }
                        if (cont.isActive) cont.resume(DataResult.Success(paths))
                    },
                )
                retainedDelegate = delegate
                picker.delegate = delegate
                presenter.presentViewController(picker, animated = true, completion = null)
            }
        }

    private fun saveImage(image: UIImage): String? {
        val data = UIImageJPEGRepresentation(image, 0.95) ?: return null
        val path = fileStorage.newFilePath(fileStorage.originalsDir(), "jpg")
        val ok = data.writeToFile(path, atomically = true)
        return if (ok) path else null
    }

    private fun topViewController(): UIViewController? {
        val scenes = UIApplication.sharedApplication.connectedScenes
        var window: UIWindow? = null
        for (scene in scenes) {
            val windowScene = scene as? UIWindowScene ?: continue
            window = (windowScene.windows.firstOrNull { (it as? UIWindow)?.isKeyWindow() == true }
                ?: windowScene.windows.firstOrNull()) as? UIWindow
            if (window != null) break
        }
        var top = window?.rootViewController
        while (top?.presentedViewController != null) {
            top = top.presentedViewController
        }
        return top
    }
}

/**
 * Delegate for [UIImagePickerController]. Dismisses the picker then forwards the chosen image
 * (or null on cancel). Conforms to the navigation-controller delegate protocol as the picker
 * requires both.
 */
@OptIn(ExperimentalForeignApi::class)
private class CameraPickerDelegate(
    private val onResult: (UIImage?) -> Unit,
) : NSObject(), UIImagePickerControllerDelegateProtocol, UINavigationControllerDelegateProtocol {

    override fun imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo: Map<Any?, *>,
    ) {
        val image = didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] as? UIImage
        picker.dismissViewControllerAnimated(true) { onResult(image) }
    }

    override fun imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) { onResult(null) }
    }
}

/**
 * Delegate for [PHPickerViewController]. Loads each selected result's UIImage off its
 * item provider, collecting them before resuming. Loads are async; we count completions and
 * report once all have finished.
 */
@OptIn(ExperimentalForeignApi::class)
private class GalleryPickerDelegate(
    private val onResults: (List<UIImage>) -> Unit,
) : NSObject(), PHPickerViewControllerDelegateProtocol {

    override fun picker(
        picker: PHPickerViewController,
        didFinishPicking: List<*>,
    ) {
        @Suppress("UNCHECKED_CAST")
        val results = didFinishPicking as List<PHPickerResult>
        picker.dismissViewControllerAnimated(true, completion = null)

        if (results.isEmpty()) {
            onResults(emptyList())
            return
        }

        val collected = mutableListOf<UIImage>()
        var remaining = results.size
        for (result in results) {
            val provider = result.itemProvider
            if (provider.canLoadObjectOfClass(UIImage)) {
                provider.loadObjectOfClass(UIImage) { obj, _ ->
                    (obj as? UIImage)?.let { collected.add(it) }
                    remaining -= 1
                    if (remaining == 0) onResults(collected.toList())
                }
            } else {
                remaining -= 1
                if (remaining == 0) onResults(collected.toList())
            }
        }
    }
}
