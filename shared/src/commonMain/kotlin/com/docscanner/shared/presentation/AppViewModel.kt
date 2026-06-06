package com.docscanner.shared.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.model.AppSettings
import com.docscanner.shared.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

/**
 * App-level state: the resolved [AppSettings] used to pick the theme and decide whether a
 * lock gate must be shown at startup.
 */
class AppViewModel(
    settingsRepository: SettingsRepository,
) : ViewModel() {

    val settings: StateFlow<AppSettings> = settingsRepository.observeSettings()
        .stateIn(viewModelScope, SharingStarted.Eagerly, AppSettings())
}
