package com.docscanner.shared.domain.repository

import com.docscanner.shared.domain.model.AppSettings
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.ThemeMode
import kotlinx.coroutines.flow.Flow

interface SettingsRepository {
    fun observeSettings(): Flow<AppSettings>

    suspend fun setThemeMode(mode: ThemeMode)

    suspend fun setBiometricLockEnabled(enabled: Boolean)

    suspend fun setPinLockEnabled(enabled: Boolean)

    suspend fun setPin(pin: String)

    suspend fun verifyPin(pin: String): Boolean

    suspend fun setDefaultFilter(filter: ScanFilter)

    suspend fun setAutoEdgeDetection(enabled: Boolean)

    suspend fun setCloudSyncEnabled(enabled: Boolean)
}
