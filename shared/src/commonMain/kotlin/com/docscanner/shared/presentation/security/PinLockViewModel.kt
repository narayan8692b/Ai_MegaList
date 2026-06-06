package com.docscanner.shared.presentation.security

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.docscanner.shared.domain.usecase.AuthenticateBiometricUseCase
import com.docscanner.shared.domain.usecase.VerifyPinUseCase
import com.docscanner.shared.domain.util.DataResult
import com.docscanner.shared.presentation.common.launchSafe
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** UI state for the PIN lock gate. */
data class PinLockUiState(
    val entered: String = "",
    val error: String? = null,
    val unlocked: Boolean = false,
    val biometricAvailable: Boolean = false,
)

/**
 * Gate ViewModel: verifies a numeric PIN and offers a biometric shortcut. On success it sets
 * [PinLockUiState.unlocked] which the host observes to dismiss the lock screen.
 */
class PinLockViewModel(
    private val verifyPin: VerifyPinUseCase,
    private val authenticateBiometric: AuthenticateBiometricUseCase,
) : ViewModel() {

    private val _state = MutableStateFlow(PinLockUiState())
    val state: StateFlow<PinLockUiState> = _state.asStateFlow()

    private val maxLength = 8

    init {
        viewModelScope.launchSafe {
            _state.value = _state.value.copy(biometricAvailable = authenticateBiometric.isAvailable())
        }
    }

    fun appendDigit(digit: Char) {
        if (_state.value.entered.length >= maxLength) return
        _state.value = _state.value.copy(entered = _state.value.entered + digit, error = null)
    }

    fun deleteDigit() {
        val current = _state.value.entered
        if (current.isNotEmpty()) {
            _state.value = _state.value.copy(entered = current.dropLast(1), error = null)
        }
    }

    fun submit() {
        val pin = _state.value.entered
        if (pin.length < 4) {
            _state.value = _state.value.copy(error = "Enter at least 4 digits")
            return
        }
        viewModelScope.launchSafe {
            if (verifyPin(pin)) {
                _state.value = _state.value.copy(unlocked = true)
            } else {
                _state.value = _state.value.copy(entered = "", error = "Incorrect PIN")
            }
        }
    }

    fun authenticateBiometric() {
        viewModelScope.launchSafe {
            when (authenticateBiometric()) {
                is DataResult.Success -> _state.value = _state.value.copy(unlocked = true)
                is DataResult.Failure -> _state.value = _state.value.copy(error = "Authentication failed")
            }
        }
    }
}
