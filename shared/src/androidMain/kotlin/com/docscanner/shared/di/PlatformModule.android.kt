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
import com.docscanner.shared.platform.AndroidBiometricAuthenticator
import com.docscanner.shared.platform.AndroidCloudStorageClient
import com.docscanner.shared.platform.AndroidFileSharer
import com.docscanner.shared.platform.AndroidFileStorage
import com.docscanner.shared.platform.AndroidImageProcessor
import com.docscanner.shared.platform.AndroidMediaCapture
import com.docscanner.shared.platform.AndroidPdfGenerator
import com.docscanner.shared.platform.AndroidPlatformInfo
import com.docscanner.shared.platform.AndroidSecureStorage
import com.docscanner.shared.platform.MlKitOcrEngine
import com.russhwolf.settings.Settings
import com.russhwolf.settings.SharedPreferencesSettings
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logging
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import org.koin.android.ext.koin.androidContext
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Android implementation of the platform Koin module. Binds every platform abstraction to
 * its Android `actual`, plus the shared SQLDelight driver factory, settings store and Ktor
 * client. `IdGenerator`/`TimeProvider` are bound in commonMain and intentionally omitted.
 */
actual fun platformModule(): Module = module {
    single { DatabaseDriverFactory(androidContext()) }

    single<ImageProcessor> { AndroidImageProcessor(androidContext()) }
    single<OcrEngine> { MlKitOcrEngine(androidContext()) }
    single<PdfGenerator> { AndroidPdfGenerator(androidContext()) }
    single<BiometricAuthenticator> { AndroidBiometricAuthenticator() }
    single<SecureStorage> { AndroidSecureStorage(androidContext()) }
    single<FileStorage> { AndroidFileStorage(androidContext()) }
    single<FileSharer> { AndroidFileSharer(androidContext()) }
    single<MediaCapture> { AndroidMediaCapture(get()) }
    single<PlatformInfo> { AndroidPlatformInfo() }
    single<CloudStorageClient> { AndroidCloudStorageClient() }

    single<Settings> {
        SharedPreferencesSettings(
            androidContext().getSharedPreferences(
                "docscanner_settings",
                android.content.Context.MODE_PRIVATE,
            ),
        )
    }

    single {
        HttpClient(OkHttp) {
            install(ContentNegotiation) {
                json(
                    Json {
                        ignoreUnknownKeys = true
                        isLenient = true
                    },
                )
            }
            install(Logging) {
                level = LogLevel.INFO
            }
        }
    }
}
