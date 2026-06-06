package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.CloudStorageClient
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult

/**
 * iOS [CloudStorageClient] — STUB.
 *
 * A full implementation would use the iCloud ubiquity container via
 * `NSFileManager.URLForUbiquityContainerIdentifier(null)` (requires the iCloud capability,
 * an `iCloud.<bundle-id>` container, and entitlements that cannot be configured from shared
 * Kotlin code). Until that capability is wired up in the Xcode project, every operation
 * fails fast with an [AppError.Network] so the sync layer can surface a clear "not
 * configured" state instead of hanging.
 *
 * TODO: implement against NSFileManager ubiquity container:
 *   - isAuthenticated(): NSFileManager.defaultManager.ubiquityIdentityToken != null
 *   - upload/download: copy items in/out of URLForUbiquityContainerIdentifier(null)
 *   - list: enumerate the Documents subdirectory of the ubiquity container
 */
class IosCloudStorageClient : CloudStorageClient {

    override suspend fun isAuthenticated(): Boolean = false

    override suspend fun authenticate(): DataResult<Unit> = notConfigured()

    override suspend fun upload(remotePath: String, localPath: String): DataResult<Unit> =
        notConfigured()

    override suspend fun download(remotePath: String, localPath: String): DataResult<String> =
        notConfigured()

    override suspend fun list(remoteDir: String): DataResult<List<String>> = notConfigured()

    override suspend fun delete(remotePath: String): DataResult<Unit> = notConfigured()

    private fun notConfigured(): DataResult<Nothing> =
        DataResult.Failure(AppError.Network("iCloud not configured"))
}
