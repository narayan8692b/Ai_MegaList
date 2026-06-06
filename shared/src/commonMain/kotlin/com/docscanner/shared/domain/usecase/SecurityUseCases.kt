package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.platform.BiometricAuthenticator
import com.docscanner.shared.domain.repository.SettingsRepository
import com.docscanner.shared.domain.util.DataResult

class AuthenticateBiometricUseCase(private val authenticator: BiometricAuthenticator) {
    suspend fun isAvailable(): Boolean = authenticator.isAvailable()

    suspend operator fun invoke(
        title: String = "Unlock DocScanner",
        subtitle: String = "Authenticate to access your documents",
    ): DataResult<Unit> = authenticator.authenticate(title, subtitle)
}

class VerifyPinUseCase(private val settingsRepository: SettingsRepository) {
    suspend operator fun invoke(pin: String): Boolean = settingsRepository.verifyPin(pin)
}

class SetPinUseCase(private val settingsRepository: SettingsRepository) {
    suspend operator fun invoke(pin: String) {
        settingsRepository.setPin(pin)
        settingsRepository.setPinLockEnabled(true)
    }
}
