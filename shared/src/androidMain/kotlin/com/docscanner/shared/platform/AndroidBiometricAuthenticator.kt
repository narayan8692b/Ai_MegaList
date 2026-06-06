package com.docscanner.shared.platform

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import com.docscanner.shared.domain.platform.BiometricAuthenticator
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume

/**
 * Android [BiometricAuthenticator] using [androidx.biometric.BiometricPrompt].
 *
 * Requires a foreground [androidx.fragment.app.FragmentActivity], obtained from
 * [ActivityHolder]. Allows both strong biometrics and device credential as a fallback.
 */
class AndroidBiometricAuthenticator : BiometricAuthenticator {

    private val authenticators =
        BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL

    override suspend fun isAvailable(): Boolean {
        val activity = ActivityHolder.currentActivity ?: return false
        return BiometricManager.from(activity)
            .canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS
    }

    override suspend fun authenticate(
        title: String,
        subtitle: String,
    ): DataResult<Unit> = withContext(Dispatchers.Main) {
        val activity = ActivityHolder.currentActivity
            ?: return@withContext DataResult.Failure(
                AppError.Auth("No active screen available for authentication"),
            )

        suspendCancellableCoroutine { cont ->
            val executor = ContextCompat.getMainExecutor(activity)
            val prompt = BiometricPrompt(
                activity,
                executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        if (cont.isActive) cont.resume(DataResult.Success(Unit))
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        if (cont.isActive) {
                            cont.resume(DataResult.Failure(AppError.Auth(errString.toString())))
                        }
                    }

                    override fun onAuthenticationFailed() {
                        // A single non-matching attempt; the prompt stays open. Do not resume.
                    }
                },
            )

            val info = BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                .setAllowedAuthenticators(authenticators)
                .build()

            prompt.authenticate(info)
            cont.invokeOnCancellation { prompt.cancelAuthentication() }
        }
    }
}
