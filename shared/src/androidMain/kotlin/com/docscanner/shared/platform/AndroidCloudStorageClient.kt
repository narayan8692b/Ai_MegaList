package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.CloudStorageClient
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult

/**
 * Android [CloudStorageClient] STUB for Google Drive.
 *
 * A production implementation would:
 *  1. Authenticate the user with Google Identity Services / `GoogleSignIn` requesting the
 *     `https://www.googleapis.com/auth/drive.file` scope.
 *  2. Use the Drive REST API (v3) via Ktor (or the Drive Java client) with the obtained
 *     OAuth access token to create an app folder and upload/download encrypted blobs.
 *  3. Map Drive file IDs to the `remotePath` keys used by the sync layer.
 *
 * Until that is wired up, network operations fail with a clear [AppError.Network] so the
 * sync layer can surface "not configured" to the user, and read-only checks return safe
 * defaults. The class compiles and satisfies the interface contract.
 */
class AndroidCloudStorageClient : CloudStorageClient {

    private fun notConfigured(): DataResult.Failure =
        DataResult.Failure(AppError.Network("Google Drive not configured"))

    override suspend fun isAuthenticated(): Boolean = false

    override suspend fun authenticate(): DataResult<Unit> = notConfigured()

    override suspend fun upload(remotePath: String, localPath: String): DataResult<Unit> =
        notConfigured()

    override suspend fun download(remotePath: String, localPath: String): DataResult<String> =
        notConfigured()

    override suspend fun list(remoteDir: String): DataResult<List<String>> = notConfigured()

    override suspend fun delete(remotePath: String): DataResult<Unit> = notConfigured()
}
