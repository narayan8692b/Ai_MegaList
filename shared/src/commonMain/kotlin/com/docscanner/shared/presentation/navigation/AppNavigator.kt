package com.docscanner.shared.presentation.navigation

import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.snapshots.SnapshotStateList

/**
 * A minimal, dependency-free navigator backed by a Compose snapshot-state back stack.
 * Mutating the stack triggers recomposition of the host that renders [currentScreen].
 *
 * It deliberately avoids any external navigation library so it is fully shared across
 * Android and iOS. Provided as a Koin `single` and via composition for screens to reach.
 */
class AppNavigator(initial: Screen = Screen.Home) {

    /** The live back stack. The last element is the visible screen. */
    val backStack: SnapshotStateList<Screen> = mutableStateListOf(initial)

    /** The currently visible destination. */
    val currentScreen: Screen
        get() = backStack.last()

    /** True when there is somewhere to pop back to. */
    val canPop: Boolean
        get() = backStack.size > 1

    /** Push a new destination onto the stack. */
    fun push(screen: Screen) {
        backStack.add(screen)
    }

    /** Pop the top destination. No-op if only the root remains. */
    fun pop(): Boolean {
        if (!canPop) return false
        backStack.removeAt(backStack.lastIndex)
        return true
    }

    /** Pop back to (and including a fresh copy of) the given root tab. */
    fun switchRoot(root: Screen) {
        // Keep a single-entry stack rooted at the selected tab so back from a tab exits.
        backStack.clear()
        backStack.add(root)
    }

    /** Replace the entire stack with a single destination. */
    fun replaceRoot(screen: Screen) {
        backStack.clear()
        backStack.add(screen)
    }

    /** Pop everything above the first matching root, used by bottom-nav re-selection. */
    fun popToRoot() {
        while (backStack.size > 1) backStack.removeAt(backStack.lastIndex)
    }
}
