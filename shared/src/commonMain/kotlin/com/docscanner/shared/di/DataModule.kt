package com.docscanner.shared.di

import com.docscanner.shared.data.local.createDatabase
import com.docscanner.shared.data.provider.SystemTimeProvider
import com.docscanner.shared.data.provider.UuidIdGenerator
import com.docscanner.shared.data.remote.SyncApiClient
import com.docscanner.shared.data.repository.DocumentRepositoryImpl
import com.docscanner.shared.data.repository.FolderRepositoryImpl
import com.docscanner.shared.data.repository.SettingsRepositoryImpl
import com.docscanner.shared.data.repository.SyncRepositoryImpl
import com.docscanner.shared.database.DocScannerDatabase
import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.platform.TimeProvider
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.repository.FolderRepository
import com.docscanner.shared.domain.repository.SettingsRepository
import com.docscanner.shared.domain.repository.SyncRepository
import kotlinx.coroutines.Dispatchers
import org.koin.dsl.module

/**
 * Data-layer Koin graph: the SQLDelight database, repository implementations, the common
 * id/time providers and the sync transport. Platform-supplied dependencies (the database
 * driver factory, secure storage, settings, cloud client, file storage and the configured
 * Ktor [io.ktor.client.HttpClient]) are resolved from `platformModule()`.
 *
 * The name `dataModule` is referenced by [initKoin] and must not change.
 */
val dataModule = module {
    // Database — driver factory comes from the platform module.
    single<DocScannerDatabase> { createDatabase(get()) }

    // Repositories. Dispatchers.Default is passed directly to avoid binding a generic
    // CoroutineDispatcher (which would clash with any platform dispatcher bindings).
    single<DocumentRepository> { DocumentRepositoryImpl(get(), Dispatchers.Default) }
    single<FolderRepository> { FolderRepositoryImpl(get(), Dispatchers.Default) }
    single<SettingsRepository> { SettingsRepositoryImpl(get(), get()) }
    single<SyncRepository> { SyncRepositoryImpl(get(), get(), get(), Dispatchers.Default) }

    // Common providers.
    single<IdGenerator> { UuidIdGenerator() }
    single<TimeProvider> { SystemTimeProvider() }

    // Sync transport — HttpClient comes from the platform module.
    single { SyncApiClient(get()) }
}
