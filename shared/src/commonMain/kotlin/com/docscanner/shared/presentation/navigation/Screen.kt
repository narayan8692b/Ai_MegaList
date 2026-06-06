package com.docscanner.shared.presentation.navigation

/**
 * The set of navigable destinations. Modeled as a sealed interface so the back stack is
 * fully type-safe and screen arguments travel with the destination.
 *
 * The four [isRoot] destinations are the bottom-navigation tabs; everything else is a
 * pushed sub-screen.
 */
sealed interface Screen {
    /** True for the bottom-navigation root tabs (Home/Scan/Documents/Settings). */
    val isRoot: Boolean get() = false

    data object Home : Screen {
        override val isRoot: Boolean get() = true
    }

    data object Scan : Screen {
        override val isRoot: Boolean get() = true
    }

    data object Documents : Screen {
        override val isRoot: Boolean get() = true
    }

    data object Settings : Screen {
        override val isRoot: Boolean get() = true
    }

    /** Corner adjustment for the most recently captured page in the active scan session. */
    data object CornerAdjustment : Screen

    /** Filter selection for the active scan page. */
    data object FilterEdit : Screen

    /** Full-text / tag search over documents. */
    data object Search : Screen

    /** PIN / biometric gate shown at startup when a lock is enabled. */
    data object PinLock : Screen

    data class DocumentDetail(val documentId: String) : Screen

    data class FolderDetail(val folderId: String) : Screen
}
