package com.docscanner.shared.presentation.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.usePinned
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.skia.Image as SkiaImage
import platform.Foundation.NSData
import platform.UIKit.UIImage
import platform.UIKit.UIImageJPEGRepresentation
import androidx.compose.ui.graphics.toComposeImageBitmap

/**
 * iOS implementation: load the file via [UIImage], re-encode to JPEG bytes, then decode with
 * Skia into a Compose [ImageBitmap]. Decoding happens off the main thread via [produceState].
 *
 * Going through a JPEG round-trip is the simplest dependency-free way to get raw, decodable
 * bytes out of a `UIImage` (whose internal CGImage backing is not directly exposed to Skia).
 * Shows a spinner while loading and a neutral surface on failure.
 */
@OptIn(ExperimentalForeignApi::class)
@Composable
actual fun PlatformImage(
    path: String,
    contentDescription: String?,
    modifier: Modifier,
) {
    val bitmap by produceState<ImageBitmap?>(initialValue = null, key1 = path) {
        value = withContext(Dispatchers.Default) {
            runCatching { decodeIosImage(path) }.getOrNull()
        }
    }

    val current = bitmap
    if (current != null) {
        Image(
            bitmap = current,
            contentDescription = contentDescription,
            modifier = modifier,
            contentScale = ContentScale.Fit,
        )
    } else {
        Box(
            modifier = modifier.background(MaterialTheme.colorScheme.surfaceVariant),
            contentAlignment = Alignment.Center,
        ) {
            if (path.isNotBlank()) {
                CircularProgressIndicator(modifier = Modifier.fillMaxSize(fraction = 0.2f))
            }
        }
    }
}

@OptIn(ExperimentalForeignApi::class)
private fun decodeIosImage(path: String): ImageBitmap? {
    val uiImage = UIImage(contentsOfFile = path) ?: return null
    val data: NSData = UIImageJPEGRepresentation(uiImage, 0.95) ?: return null
    val bytes = data.toByteArray() ?: return null
    return SkiaImage.makeFromEncoded(bytes).toComposeImageBitmap()
}

@OptIn(ExperimentalForeignApi::class)
private fun NSData.toByteArray(): ByteArray? {
    val size = this.length.toInt()
    if (size == 0) return null
    val result = ByteArray(size)
    result.usePinned { pinned ->
        platform.posix.memcpy(pinned.addressOf(0), this.bytes, this.length)
    }
    return result
}
