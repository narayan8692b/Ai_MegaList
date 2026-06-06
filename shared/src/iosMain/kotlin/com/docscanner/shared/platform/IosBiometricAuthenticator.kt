package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.BiometricAuthenticator
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.suspendCancellableCoroutine
import platform.LocalAuthentication.LAContext
import platform.LocalAuthentication.LAPolicyDeviceOwnerAuthentication
import kotlin.coroutines.resume

/**
 * iOS [BiometricAuthenticator] backed by LocalAuthentication ([LAContext]).
 *
 * Uses `LAPolicyDeviceOwnerAuthentication` which allows biometrics (Face ID / Touch ID) with
 * an automatic fallback to the device passcode — appropriate for an app lock. The evaluation
 * callback is bridged to a coroutine via [suspendCancellableCoroutine].
 */
@OptIn(ExperimentalForeignApi::class)
class IosBiometricAuthenticator : BiometricAuthenticator {

    override suspend fun isAvailable(): Boolean {
        val context = LAContext()
        return context.canEvaluatePolicy(LAPolicyDeviceOwnerAuthentication, error = null)
    }

    override suspend fun authenticate(
        title: String,
        subtitle: String,
    ): DataResult<Unit> = suspendCancellableCoroutine { cont ->
        val context = LAContext()
        if (!context.canEvaluatePolicy(LAPolicyDeviceOwnerAuthentication, error = null)) {
            cont.resume(DataResult.Failure(AppError.Auth("Biometric authentication unavailable")))
            return@suspendCancellableCoroutine
        }
        // The reason string is shown in the system prompt; combine the supplied title/subtitle.
        val reason = if (subtitle.isNotBlank()) "$title\n$subtitle" else title
        context.evaluatePolicy(
            LAPolicyDeviceOwnerAuthentication,
            localizedReason = reason,
        ) { success, error ->
            if (!cont.isActive) return@evaluatePolicy
            if (success) {
                cont.resume(DataResult.Success(Unit))
            } else {
                cont.resume(
                    DataResult.Failure(
                        AppError.Auth(error?.localizedDescription ?: "Authentication failed"),
                    ),
                )
            }
        }
    }
}
