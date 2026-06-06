package com.docscanner.android

import android.app.Application
import com.docscanner.shared.di.initKoin
import io.github.aakira.napier.DebugAntilog
import io.github.aakira.napier.Napier
import org.koin.android.ext.koin.androidContext

/**
 * Application entry point. Starts Koin with the Android context and installs Napier logging.
 */
class DocScannerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Napier.base(DebugAntilog())
        initKoin {
            androidContext(this@DocScannerApplication)
        }
    }
}
