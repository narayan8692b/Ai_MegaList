package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.util.DataResult

/**
 * Secure cloud storage backend used by the sync layer. Implemented per platform
 * (Google Drive on Android, iCloud / CloudKit on iOS). Files are encrypted before upload.
 */
interface CloudStorageClient {
    suspend fun isAuthenticated(): Boolean

    suspend fun authenticate(): DataResult<Unit>

    suspend fun upload(remotePath: String, localPath: String): DataResult<Unit>

    suspend fun download(remotePath: String, localPath: String): DataResult<String>

    suspend fun list(remoteDir: String): DataResult<List<String>>

    suspend fun delete(remotePath: String): DataResult<Unit>
}
