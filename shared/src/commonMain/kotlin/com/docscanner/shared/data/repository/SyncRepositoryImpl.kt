package com.docscanner.shared.data.repository

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.platform.CloudStorageClient
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.repository.SyncRepository
import com.docscanner.shared.domain.repository.SyncState
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock

/**
 * Coordinates cloud synchronization. Documents flagged [SyncStatus.PENDING_UPLOAD] or
 * [SyncStatus.ERROR] are pushed up (page files via [CloudStorageClient], then status flipped
 * to [SyncStatus.SYNCED]); remote documents are pulled down. Progress is published through
 * [observeSyncState].
 *
 * The cloud transport is abstracted, so this class only owns the orchestration/state logic.
 */
class SyncRepositoryImpl(
    private val documentRepository: DocumentRepository,
    private val cloudClient: CloudStorageClient,
    private val fileStorage: FileStorage,
    private val dispatcher: CoroutineDispatcher,
) : SyncRepository {

    private val state = MutableStateFlow(SyncState())

    override fun observeSyncState(): Flow<SyncState> = state.asStateFlow()

    override suspend fun syncUp(): DataResult<Unit> = withContext(dispatcher) {
        runSync { uploadPending() }
    }

    override suspend fun syncDown(): DataResult<Unit> = withContext(dispatcher) {
        runSync { downloadRemote() }
    }

    override suspend fun syncAll(): DataResult<Unit> = withContext(dispatcher) {
        runSync {
            uploadPending()
            downloadRemote()
        }
    }

    // ---- Orchestration ------------------------------------------------------

    private suspend fun runSync(body: suspend () -> Unit): DataResult<Unit> {
        state.value = state.value.copy(isSyncing = true, errorMessage = null)
        return try {
            if (!cloudClient.isAuthenticated()) {
                cloudClient.authenticate().also { auth ->
                    if (auth is DataResult.Failure) {
                        state.value = state.value.copy(isSyncing = false, errorMessage = auth.error.message)
                        return DataResult.Failure(auth.error)
                    }
                }
            }
            body()
            state.value = state.value.copy(
                isSyncing = false,
                lastSyncedAt = Clock.System.now().toEpochMilliseconds(),
                pendingCount = 0,
                errorMessage = null,
            )
            DataResult.Success(Unit)
        } catch (t: Throwable) {
            val error = AppError.Network(t.message ?: "Sync failed", t)
            state.value = state.value.copy(isSyncing = false, errorMessage = error.message)
            DataResult.Failure(error)
        }
    }

    private suspend fun uploadPending() {
        val pending = documentRepository.observeDocuments().first()
            .filter { it.syncStatus == SyncStatus.PENDING_UPLOAD || it.syncStatus == SyncStatus.ERROR }
        state.value = state.value.copy(pendingCount = pending.size)

        for (document in pending) {
            documentRepository.updateSyncStatus(document.id, SyncStatus.SYNCING)
            val result = uploadDocument(document)
            val newStatus = if (result is DataResult.Success) SyncStatus.SYNCED else SyncStatus.ERROR
            documentRepository.updateSyncStatus(document.id, newStatus)
            state.value = state.value.copy(pendingCount = (state.value.pendingCount - 1).coerceAtLeast(0))
        }
    }

    private suspend fun uploadDocument(document: Document): DataResult<Unit> {
        document.pages.forEach { page ->
            val local = page.processedImagePath
            if (fileStorage.exists(local)) {
                val remotePath = remotePagePath(document.id, page.id)
                val upload = cloudClient.upload(remotePath, local)
                if (upload is DataResult.Failure) return upload
            }
        }
        return DataResult.Success(Unit)
    }

    private suspend fun downloadRemote() {
        val listing = cloudClient.list(REMOTE_ROOT)
        if (listing is DataResult.Failure) throw IllegalStateException(listing.error.message)
        val remotePaths = (listing as DataResult.Success).data
        for (remotePath in remotePaths) {
            val dest = fileStorage.newFilePath(fileStorage.processedDir(), "jpg")
            cloudClient.download(remotePath, dest)
        }
        // NOTE: a full implementation would reconcile downloaded metadata into the local
        // database (upsert documents/pages). The transport + file retrieval are wired here;
        // metadata reconciliation depends on the remote schema and is left as a follow-up.
    }

    private fun remotePagePath(documentId: String, pageId: String): String =
        "$REMOTE_ROOT/$documentId/$pageId.jpg"

    private companion object {
        const val REMOTE_ROOT = "documents"
    }
}
