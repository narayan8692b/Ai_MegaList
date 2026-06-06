package com.docscanner.shared.di

import com.docscanner.shared.domain.usecase.ApplyFilterUseCase
import com.docscanner.shared.domain.usecase.AuthenticateBiometricUseCase
import com.docscanner.shared.domain.usecase.CreateFolderUseCase
import com.docscanner.shared.domain.usecase.CreateTagUseCase
import com.docscanner.shared.domain.usecase.DeleteDocumentUseCase
import com.docscanner.shared.domain.usecase.DeleteFolderUseCase
import com.docscanner.shared.domain.usecase.DetectEdgesUseCase
import com.docscanner.shared.domain.usecase.ExportJpgUseCase
import com.docscanner.shared.domain.usecase.ExportOcrTextUseCase
import com.docscanner.shared.domain.usecase.GeneratePdfUseCase
import com.docscanner.shared.domain.usecase.GetDocumentUseCase
import com.docscanner.shared.domain.usecase.GetDocumentsUseCase
import com.docscanner.shared.domain.usecase.GetFoldersUseCase
import com.docscanner.shared.domain.usecase.GetTagsUseCase
import com.docscanner.shared.domain.usecase.MoveDocumentUseCase
import com.docscanner.shared.domain.usecase.ObserveSyncStateUseCase
import com.docscanner.shared.domain.usecase.ProcessPageUseCase
import com.docscanner.shared.domain.usecase.SaveScanUseCase
import com.docscanner.shared.domain.usecase.SearchDocumentsUseCase
import com.docscanner.shared.domain.usecase.SetDocumentTagsUseCase
import com.docscanner.shared.domain.usecase.SetPinUseCase
import com.docscanner.shared.domain.usecase.ShareFileUseCase
import com.docscanner.shared.domain.usecase.SyncNowUseCase
import com.docscanner.shared.domain.usecase.ToggleFavoriteUseCase
import com.docscanner.shared.domain.usecase.VerifyPinUseCase
import org.koin.dsl.module

/** Use-case graph. Depends only on domain repository + platform interfaces. */
val useCaseModule = module {
    // Documents
    factory { GetDocumentsUseCase(get()) }
    factory { GetDocumentUseCase(get()) }
    factory { SearchDocumentsUseCase(get()) }
    factory { DeleteDocumentUseCase(get()) }
    factory { ToggleFavoriteUseCase(get()) }
    factory { MoveDocumentUseCase(get()) }

    // Scan & image processing
    factory { DetectEdgesUseCase(get()) }
    factory { ProcessPageUseCase(get()) }
    factory { ApplyFilterUseCase(get()) }
    factory { SaveScanUseCase(get(), get(), get(), get(), get()) }

    // Export & share
    factory { GeneratePdfUseCase(get(), get()) }
    factory { ExportJpgUseCase(get(), get()) }
    factory { ExportOcrTextUseCase(get()) }
    factory { ShareFileUseCase(get()) }

    // Organization
    factory { GetFoldersUseCase(get()) }
    factory { CreateFolderUseCase(get(), get(), get()) }
    factory { DeleteFolderUseCase(get()) }
    factory { GetTagsUseCase(get()) }
    factory { CreateTagUseCase(get(), get()) }
    factory { SetDocumentTagsUseCase(get()) }

    // Security
    factory { AuthenticateBiometricUseCase(get()) }
    factory { VerifyPinUseCase(get()) }
    factory { SetPinUseCase(get()) }

    // Sync
    factory { ObserveSyncStateUseCase(get()) }
    factory { SyncNowUseCase(get()) }
}
