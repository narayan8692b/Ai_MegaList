package com.docscanner.shared.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.AppSettings
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.ThemeMode
import com.docscanner.shared.domain.platform.PlatformInfo
import com.docscanner.shared.domain.repository.SettingsRepository
import com.docscanner.shared.domain.repository.SyncState
import com.docscanner.shared.domain.usecase.AuthenticateBiometricUseCase
import com.docscanner.shared.domain.usecase.ObserveSyncStateUseCase
import com.docscanner.shared.domain.usecase.SetPinUseCase
import com.docscanner.shared.domain.usecase.SyncNowUseCase
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.stateIn

/** UI state for the settings screen. */
data class SettingsUiState(
    val settings: AppSettings = AppSettings(),
    val syncState: SyncState = SyncState(),
    val biometricAvailable: Boolean = false,
    val platformName: String = "",
)

/**
 * Backs the settings screen: theme, lock options (biometric + PIN), default filter, auto edge
 * detection, cloud sync toggle and manual sync, plus platform/about info.
 */
class SettingsViewModel(
    private val settingsRepository: SettingsRepository,
    observeSyncState: ObserveSyncStateUseCase,
    private val syncNow: SyncNowUseCase,
    private val authenticateBiometric: AuthenticateBiometricUseCase,
    private val setPin: SetPinUseCase,
    private val platformInfo: PlatformInfo,
) : ViewModel() {

    private val _state = MutableStateFlow(SettingsUiState(platformName = platformInfo.name))
    val state: StateFlow<SettingsUiState> = _state.asStateFlow()

    init {
        settingsRepository.observeSettings()
            .onEach { _state.value = _state.value.copy(settings = it) }
            .launchIn(viewModelScope)
        observeSyncState()
            .onEach { _state.value = _state.value.copy(syncState = it) }
            .launchIn(viewModelScope)
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(biometricAvailable = authenticateBiometric.isAvailable())
        }
    }

    fun setThemeMode(mode: ThemeMode) {
        viewModelScope.launchSafe { settingsRepository.setThemeMode(mode) }
    }

    fun setBiometricLock(enabled: Boolean) {
        viewModelScope.launchSafe { settingsRepository.setBiometricLockEnabled(enabled) }
    }

    fun setDefaultFilter(filter: ScanFilter) {
        viewModelScope.launchSafe { settingsRepository.setDefaultFilter(filter) }
    }

    fun setAutoEdgeDetection(enabled: Boolean) {
        viewModelScope.launchSafe { settingsRepository.setAutoEdgeDetection(enabled) }
    }

    fun setCloudSync(enabled: Boolean) {
        viewModelScope.launchSafe { settingsRepository.setCloudSyncEnabled(enabled) }
    }

    /** Set (and enable) the PIN lock. */
    fun setPin(pin: String) {
        if (pin.length < 4) return
        viewModelScope.launchSafe { setPin.invoke(pin) }
    }

    fun syncNow() {
        viewModelScope.launchSafe { syncNow.invoke() }
    }
}
