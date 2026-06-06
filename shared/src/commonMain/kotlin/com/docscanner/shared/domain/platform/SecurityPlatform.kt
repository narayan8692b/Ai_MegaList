package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.util.DataResult

/** Biometric / device-credential authentication (Android BiometricPrompt, iOS LocalAuthentication). */
interface BiometricAuthenticator {
    suspend fun isAvailable(): Boolean

    suspend fun authenticate(
        title: String,
        subtitle: String,
    ): DataResult<Unit>
}

/**
 * Encrypted key-value storage for secrets such as the PIN hash and cloud tokens.
 * Android uses EncryptedSharedPreferences; iOS uses the Keychain.
 */
interface SecureStorage {
    fun putString(key: String, value: String)
    fun getString(key: String): String?
    fun remove(key: String)
    fun clear()
}

/** Shares files (PDF/JPG) via the native share sheet. */
interface FileSharer {
    suspend fun shareFile(path: String, mimeType: String): DataResult<Unit>
    suspend fun shareFiles(paths: List<String>, mimeType: String): DataResult<Unit>
}
