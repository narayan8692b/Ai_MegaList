package com.docscanner.shared.data.repository

import com.docscanner.shared.domain.model.AppSettings
import com.docscanner.shared.domain.model.CloudProvider
import com.docscanner.shared.domain.model.PdfQuality
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.ThemeMode
import com.docscanner.shared.domain.platform.SecureStorage
import com.docscanner.shared.domain.repository.SettingsRepository
import com.russhwolf.settings.Settings
import com.russhwolf.settings.get
import com.russhwolf.settings.set
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * [SettingsRepository] backed by multiplatform-settings for primitive preferences and by
 * [SecureStorage] for the salted PIN hash.
 *
 * Settings emit reactively through a [MutableStateFlow] seeded from persisted values and
 * refreshed after each setter. Enum fields are stored by [Enum.name] and decoded with a
 * safe fallback so unknown/legacy values can never crash the read path.
 */
class SettingsRepositoryImpl(
    private val settings: Settings,
    private val secureStorage: SecureStorage,
) : SettingsRepository {

    private val state = MutableStateFlow(readSnapshot())

    override fun observeSettings(): Flow<AppSettings> = state.asStateFlow()

    override suspend fun setThemeMode(mode: ThemeMode) {
        settings[KEY_THEME_MODE] = mode.name
        refresh()
    }

    override suspend fun setBiometricLockEnabled(enabled: Boolean) {
        settings[KEY_BIOMETRIC_LOCK] = enabled
        refresh()
    }

    override suspend fun setPinLockEnabled(enabled: Boolean) {
        settings[KEY_PIN_LOCK] = enabled
        refresh()
    }

    override suspend fun setPin(pin: String) {
        // NOTE: this is a deterministic, salted string hash for portability across KMP
        // targets. A production implementation should use PBKDF2/Argon2 with a random,
        // per-user salt stored alongside the hash.
        secureStorage.putString(KEY_PIN_HASH, hashPin(pin))
    }

    override suspend fun verifyPin(pin: String): Boolean {
        val stored = secureStorage.getString(KEY_PIN_HASH) ?: return false
        return stored == hashPin(pin)
    }

    override suspend fun setDefaultFilter(filter: ScanFilter) {
        settings[KEY_DEFAULT_FILTER] = filter.name
        refresh()
    }

    override suspend fun setAutoEdgeDetection(enabled: Boolean) {
        settings[KEY_AUTO_EDGE] = enabled
        refresh()
    }

    override suspend fun setCloudSyncEnabled(enabled: Boolean) {
        settings[KEY_CLOUD_SYNC] = enabled
        refresh()
    }

    // ---- Internal -----------------------------------------------------------

    private fun refresh() {
        state.value = readSnapshot()
    }

    private fun readSnapshot(): AppSettings = AppSettings(
        themeMode = safeEnum(settings[KEY_THEME_MODE], ThemeMode.SYSTEM),
        biometricLockEnabled = settings[KEY_BIOMETRIC_LOCK, false],
        pinLockEnabled = settings[KEY_PIN_LOCK, false],
        defaultFilter = safeEnum(settings[KEY_DEFAULT_FILTER], ScanFilter.MAGIC_COLOR),
        autoEdgeDetection = settings[KEY_AUTO_EDGE, true],
        cloudSyncEnabled = settings[KEY_CLOUD_SYNC, false],
        cloudProvider = safeEnum(settings[KEY_CLOUD_PROVIDER], CloudProvider.NONE),
        pdfQuality = safeEnum(settings[KEY_PDF_QUALITY], PdfQuality.HIGH),
    )

    private fun hashPin(pin: String): String {
        var h = 1125899906842597L // prime seed acting as a fixed salt
        val salted = PIN_SALT + pin
        for (c in salted) {
            h = 31 * h + c.code
        }
        return h.toString()
    }

    private companion object {
        const val KEY_THEME_MODE = "settings.themeMode"
        const val KEY_BIOMETRIC_LOCK = "settings.biometricLockEnabled"
        const val KEY_PIN_LOCK = "settings.pinLockEnabled"
        const val KEY_DEFAULT_FILTER = "settings.defaultFilter"
        const val KEY_AUTO_EDGE = "settings.autoEdgeDetection"
        const val KEY_CLOUD_SYNC = "settings.cloudSyncEnabled"
        const val KEY_CLOUD_PROVIDER = "settings.cloudProvider"
        const val KEY_PDF_QUALITY = "settings.pdfQuality"
        const val KEY_PIN_HASH = "secure.pinHash"
        const val PIN_SALT = "docscanner::pin::v1::"

        inline fun <reified T : Enum<T>> safeEnum(name: String?, default: T): T =
            name?.let { value -> enumValues<T>().firstOrNull { it.name == value } } ?: default
    }
}
