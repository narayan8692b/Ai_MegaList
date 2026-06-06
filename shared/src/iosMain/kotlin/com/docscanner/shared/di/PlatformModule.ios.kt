package com.docscanner.shared.di

import com.docscanner.shared.data.local.DatabaseDriverFactory
import com.docscanner.shared.domain.platform.BiometricAuthenticator
import com.docscanner.shared.domain.platform.CloudStorageClient
import com.docscanner.shared.domain.platform.FileSharer
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.platform.MediaCapture
import com.docscanner.shared.domain.platform.OcrEngine
import com.docscanner.shared.domain.platform.PdfGenerator
import com.docscanner.shared.domain.platform.PlatformInfo
import com.docscanner.shared.domain.platform.SecureStorage
import com.docscanner.shared.platform.IosBiometricAuthenticator
import com.docscanner.shared.platform.IosCloudStorageClient
import com.docscanner.shared.platform.IosFileSharer
import com.docscanner.shared.platform.IosFileStorage
import com.docscanner.shared.platform.IosImageProcessor
import com.docscanner.shared.platform.IosMediaCapture
import com.docscanner.shared.platform.IosPdfGenerator
import com.docscanner.shared.platform.IosPlatformInfo
import com.docscanner.shared.platform.IosSecureStorage
import com.docscanner.shared.platform.VisionOcrEngine
import com.russhwolf.settings.NSUserDefaultsSettings
import com.russhwolf.settings.Settings
import io.ktor.client.HttpClient
import io.ktor.client.engine.darwin.Darwin
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.logging.Logging
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import org.koin.core.module.Module
import org.koin.dsl.module
import platform.Foundation.NSUserDefaults

/**
 * iOS [platformModule] binding the concrete Apple-backed implementations of every platform
 * abstraction, plus the SQLDelight driver factory, multiplatform-settings (NSUserDefaults),
 * and a Darwin-engine Ktor [HttpClient].
 *
 * NOTE: `IdGenerator` and `TimeProvider` are bound in commonMain by another team and are
 * intentionally NOT declared here.
 */
actual fun platformModule(): Module = module {
    single { DatabaseDriverFactory() }

    single<ImageProcessor> { IosImageProcessor(get()) }
    single<OcrEngine> { VisionOcrEngine() }
    single<PdfGenerator> { IosPdfGenerator() }
    single<BiometricAuthenticator> { IosBiometricAuthenticator() }
    single<SecureStorage> { IosSecureStorage() }
    single<FileStorage> { IosFileStorage() }
    single<FileSharer> { IosFileSharer() }
    single<MediaCapture> { IosMediaCapture(get()) }
    single<PlatformInfo> { IosPlatformInfo() }
    single<CloudStorageClient> { IosCloudStorageClient() }

    single<Settings> {
        NSUserDefaultsSettings(NSUserDefaults.standardUserDefaults)
    }

    single {
        HttpClient(Darwin) {
            install(ContentNegotiation) {
                json(
                    Json {
                        ignoreUnknownKeys = true
                        isLenient = true
                    },
                )
            }
            install(Logging)
        }
    }
}
