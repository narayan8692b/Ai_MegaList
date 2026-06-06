package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.FileSharer
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import platform.Foundation.NSURL
import platform.UIKit.UIActivityViewController
import platform.UIKit.UIApplication
import platform.UIKit.UIViewController
import platform.UIKit.UIWindow
import platform.UIKit.UIWindowScene
import kotlin.coroutines.resume

/**
 * iOS [FileSharer] presenting a [UIActivityViewController] from the key window's top-most
 * view controller.
 *
 * Threading: UIKit presentation must run on the main thread, so we hop to
 * [Dispatchers.Main] for the actual present. We resume the coroutine with success as soon as
 * the share sheet has been presented (the interface does not require us to await the user's
 * choice). [mimeType] is accepted for API symmetry with Android; iOS infers the type from the
 * file URL extension.
 */
@OptIn(ExperimentalForeignApi::class)
class IosFileSharer : FileSharer {

    override suspend fun shareFile(path: String, mimeType: String): DataResult<Unit> =
        present(listOf(path))

    override suspend fun shareFiles(paths: List<String>, mimeType: String): DataResult<Unit> =
        present(paths)

    private suspend fun present(paths: List<String>): DataResult<Unit> =
        withContext(Dispatchers.Main) {
            val items = paths.mapNotNull { NSURL.fileURLWithPath(it) }
            if (items.isEmpty()) {
                return@withContext DataResult.Failure(AppError.Storage("No files to share"))
            }
            val presenter = topViewController()
                ?: return@withContext DataResult.Failure(
                    AppError.Unknown("No view controller available to present the share sheet"),
                )

            suspendCancellableCoroutine { cont ->
                val controller = UIActivityViewController(
                    activityItems = items,
                    applicationActivities = null,
                )
                // iPad: a popover source is required; anchor to the presenter's view.
                controller.popoverPresentationController?.sourceView = presenter.view
                presenter.presentViewController(controller, animated = true) {
                    if (cont.isActive) cont.resume(DataResult.Success(Unit))
                }
            }
        }

    /** Resolve the foreground key window's top-most presented view controller. */
    private fun topViewController(): UIViewController? {
        val window = keyWindow() ?: return null
        var top = window.rootViewController
        while (top?.presentedViewController != null) {
            top = top.presentedViewController
        }
        return top
    }

    private fun keyWindow(): UIWindow? {
        val scenes = UIApplication.sharedApplication.connectedScenes
        for (scene in scenes) {
            val windowScene = scene as? UIWindowScene ?: continue
            val key = windowScene.windows.firstOrNull { (it as? UIWindow)?.isKeyWindow() == true }
            if (key != null) return key as UIWindow
            (windowScene.windows.firstOrNull() as? UIWindow)?.let { return it }
        }
        return null
    }
}
