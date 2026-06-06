package com.docscanner.shared.presentation.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/**
 * Loads and displays an image from a local file [path] in a platform-appropriate way,
 * without adding an image-loading dependency (no Coil/Kamel, which are not in the catalog).
 *
 * Android decodes via `BitmapFactory` off the main thread; iOS uses `UIImage`. Implementations
 * must show something sensible (placeholder) while loading or on failure.
 */
@Composable
expect fun PlatformImage(
    path: String,
    contentDescription: String?,
    modifier: Modifier = Modifier,
)
