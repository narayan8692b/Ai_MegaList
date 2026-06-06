package com.docscanner.shared.di

import com.docscanner.shared.presentation.AppViewModel
import com.docscanner.shared.presentation.documents.DocumentDetailViewModel
import com.docscanner.shared.presentation.documents.DocumentsViewModel
import com.docscanner.shared.presentation.documents.FolderDetailViewModel
import com.docscanner.shared.presentation.documents.SearchViewModel
import com.docscanner.shared.presentation.home.HomeViewModel
import com.docscanner.shared.presentation.navigation.AppNavigator
import com.docscanner.shared.presentation.scan.CornerAdjustmentViewModel
import com.docscanner.shared.presentation.scan.FilterViewModel
import com.docscanner.shared.presentation.scan.ScanSessionStore
import com.docscanner.shared.presentation.scan.ScanViewModel
import com.docscanner.shared.presentation.security.PinLockViewModel
import com.docscanner.shared.presentation.settings.SettingsViewModel
import org.koin.core.module.dsl.viewModel
import org.koin.dsl.module

/**
 * Presentation-layer Koin graph. Registers every screen ViewModel via the
 * `koin-compose-viewmodel` `viewModel { }` DSL, plus the session-scoped singletons used by
 * the navigator and the scan flow.
 *
 * The name `viewModelModule` is referenced by [initKoin] and must not change.
 */
val viewModelModule = module {
    // App-session singletons.
    single { AppNavigator() }
    single { ScanSessionStore() }

    // Root / app-level.
    viewModel { AppViewModel(get()) }

    // Home.
    viewModel { HomeViewModel(get(), get()) }

    // Scan flow.
    viewModel { ScanViewModel(get(), get(), get(), get(), get(), get(), get()) }
    viewModel { CornerAdjustmentViewModel(get(), get(), get()) }
    viewModel { FilterViewModel(get(), get(), get()) }

    // Documents.
    viewModel { DocumentsViewModel(get(), get(), get(), get(), get(), get(), get(), get()) }
    viewModel { SearchViewModel(get()) }
    viewModel { (documentId: String) ->
        DocumentDetailViewModel(
            documentId = documentId,
            getDocument = get(),
            getTags = get(),
            generatePdf = get(),
            exportJpg = get(),
            exportOcrText = get(),
            shareFile = get(),
            toggleFavorite = get(),
            setDocumentTags = get(),
            documentRepository = get(),
            settingsRepository = get(),
        )
    }
    viewModel { (folderId: String) ->
        FolderDetailViewModel(
            folderId = folderId,
            getDocuments = get(),
            toggleFavorite = get(),
            deleteDocument = get(),
            moveDocument = get(),
        )
    }

    // Settings.
    viewModel { SettingsViewModel(get(), get(), get(), get(), get(), get()) }

    // Security.
    viewModel { PinLockViewModel(get(), get()) }
}
