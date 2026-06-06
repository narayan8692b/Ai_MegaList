package com.docscanner.shared.platform

import androidx.fragment.app.FragmentActivity

/**
 * Holds a weak reference to the currently-resumed [FragmentActivity].
 *
 * Several platform integrations (BiometricPrompt, share sheet, activity-result launchers)
 * need an [android.app.Activity] that the shared module cannot otherwise obtain. The host
 * `MainActivity` sets this in `onCreate` and clears it in `onDestroy`.
 */
object ActivityHolder {
    var currentActivity: FragmentActivity? = null
}
