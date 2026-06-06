package com.docscanner.shared

import androidx.compose.ui.window.ComposeUIViewController
import com.docscanner.shared.di.initKoinIos
import com.docscanner.shared.presentation.App
import org.koin.core.context.GlobalContext
import platform.UIKit.UIViewController

/**
 * Swift entry point. Returns a UIViewController hosting the Compose Multiplatform [App].
 * Exposed to Swift as `MainViewControllerKt.MainViewController()`.
 *
 * Koin is started lazily here (guarded against double-start) so the Swift host does not need
 * to call into Kotlin DI separately.
 */
fun MainViewController(): UIViewController {
    ensureKoinStarted()
    return ComposeUIViewController { App() }
}

/** Public helper Swift can call explicitly if it prefers to initialize DI up front. */
fun startKoinIos() {
    ensureKoinStarted()
}

private fun ensureKoinStarted() {
    if (GlobalContext.getOrNull() == null) {
        initKoinIos()
    }
}
