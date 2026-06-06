package com.docscanner.shared.presentation

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DocumentScanner
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.docscanner.shared.domain.model.ThemeMode
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.documents.DocumentDetailScreen
import com.docscanner.shared.presentation.documents.DocumentsScreen
import com.docscanner.shared.presentation.documents.FolderDetailScreen
import com.docscanner.shared.presentation.documents.SearchScreen
import com.docscanner.shared.presentation.home.HomeScreen
import com.docscanner.shared.presentation.navigation.AppNavigator
import com.docscanner.shared.presentation.navigation.Screen
import com.docscanner.shared.presentation.scan.CornerAdjustmentScreen
import com.docscanner.shared.presentation.scan.FilterScreen
import com.docscanner.shared.presentation.scan.ScanScreen
import com.docscanner.shared.presentation.scan.ScanViewModel
import com.docscanner.shared.presentation.security.PinLockScreen
import com.docscanner.shared.presentation.settings.SettingsScreen
import com.docscanner.shared.presentation.theme.DocScannerTheme
import org.koin.compose.koinInject
import org.koin.compose.viewmodel.koinViewModel

/**
 * The shared application root. Referenced by the Android `MainActivity` and the iOS
 * `MainViewController`. Resolves the theme from settings, gates the app behind a PIN/biometric
 * lock when enabled, and hosts the lightweight [AppNavigator] back stack inside a Material 3
 * [Scaffold]. On wide screens it uses a [NavigationRail]; otherwise a [NavigationBar].
 *
 * Koin must already be started by the platform entry point (see `initKoin`).
 */
@Composable
fun App() {
    val appViewModel: AppViewModel = koinViewModel()
    val settings by appViewModel.settings.collectAsStateCompat()

    val systemDark = isSystemInDarkTheme()
    val darkTheme = when (settings.themeMode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> systemDark
    }

    // The navigator lives for the whole app session.
    val navigator = koinInject<AppNavigator>()

    // Lock gate: shown once at startup when a lock is enabled, until the user authenticates.
    val lockRequired = settings.pinLockEnabled || settings.biometricLockEnabled
    var unlocked by remember { mutableStateOf(false) }

    DocScannerTheme(darkTheme = darkTheme) {
        if (lockRequired && !unlocked) {
            PinLockScreen(onUnlocked = { unlocked = true })
        } else {
            AppContent(navigator = navigator)
        }
    }
}

private data class NavTab(val screen: Screen, val label: String, val icon: ImageVector)

private val tabs = listOf(
    NavTab(Screen.Home, "Home", Icons.Filled.Home),
    NavTab(Screen.Scan, "Scan", Icons.Filled.DocumentScanner),
    NavTab(Screen.Documents, "Documents", Icons.Filled.Folder),
    NavTab(Screen.Settings, "Settings", Icons.Filled.Settings),
)

@Composable
private fun AppContent(navigator: AppNavigator) {
    val current = navigator.currentScreen
    val showBottomBar = current.isRoot

    androidx.compose.foundation.layout.BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val wide = maxWidth >= 720.dp

        if (wide && showBottomBar) {
            // Tablet / landscape: navigation rail beside the content.
            Row(modifier = Modifier.fillMaxSize()) {
                NavigationRail {
                    tabs.forEach { tab ->
                        NavigationRailItem(
                            selected = current == tab.screen,
                            onClick = { navigator.switchRoot(tab.screen) },
                            icon = { Icon(tab.icon, contentDescription = tab.label) },
                            label = { Text(tab.label) },
                        )
                    }
                }
                Box(modifier = Modifier.fillMaxSize()) {
                    Destination(navigator)
                }
            }
        } else {
            Scaffold(
                bottomBar = {
                    if (showBottomBar) {
                        NavigationBar {
                            tabs.forEach { tab ->
                                NavigationBarItem(
                                    selected = current == tab.screen,
                                    onClick = { navigator.switchRoot(tab.screen) },
                                    icon = { Icon(tab.icon, contentDescription = tab.label) },
                                    label = { Text(tab.label) },
                                )
                            }
                        }
                    }
                },
            ) { padding ->
                Box(modifier = Modifier.fillMaxSize().padding(padding)) {
                    Destination(navigator)
                }
            }
        }
    }
}

/** Renders the current destination with a cross-fade transition between screens. */
@Composable
private fun Destination(navigator: AppNavigator) {
    val current = navigator.currentScreen
    AnimatedContent(
        targetState = current,
        transitionSpec = { fadeIn() togetherWith fadeOut() },
        label = "screen",
    ) { screen ->
        when (screen) {
            Screen.Home -> HomeScreen(
                onScan = { navigator.switchRoot(Screen.Scan) },
                onImport = { navigator.switchRoot(Screen.Scan) },
                onSearch = { navigator.push(Screen.Search) },
                onOpenDocument = { navigator.push(Screen.DocumentDetail(it)) },
            )

            Screen.Scan -> ScanFlowHost(navigator, Screen.Scan)

            Screen.Documents -> DocumentsScreen(
                onOpenDocument = { navigator.push(Screen.DocumentDetail(it)) },
                onOpenFolder = { navigator.push(Screen.FolderDetail(it)) },
            )

            Screen.Settings -> SettingsScreen(appVersion = APP_VERSION)

            Screen.CornerAdjustment -> CornerAdjustmentScreen(
                onConfirmed = { navigator.push(Screen.FilterEdit) },
                onBack = { navigator.pop() },
            )

            Screen.FilterEdit -> FilterFlowHost(navigator)

            Screen.Search -> SearchScreen(
                onBack = { navigator.pop() },
                onOpenDocument = { navigator.push(Screen.DocumentDetail(it)) },
            )

            Screen.PinLock -> PinLockScreen(onUnlocked = { navigator.replaceRoot(Screen.Home) })

            is Screen.DocumentDetail -> DocumentDetailScreen(
                onBack = { navigator.pop() },
                viewModel = koinViewModel { org.koin.core.parameter.parametersOf(screen.documentId) },
            )

            is Screen.FolderDetail -> FolderDetailScreen(
                folderId = screen.folderId,
                title = "Folder",
                onBack = { navigator.pop() },
                onOpenDocument = { navigator.push(Screen.DocumentDetail(it)) },
            )
        }
    }
}

/**
 * Hosts the capture entry screen. Owns the [ScanViewModel] so the same instance can be reached
 * by the filter step for finalization.
 */
@Composable
private fun ScanFlowHost(navigator: AppNavigator, @Suppress("UNUSED_PARAMETER") root: Screen) {
    val scanViewModel: ScanViewModel = koinViewModel()
    ScanScreen(
        onGoToCornerAdjustment = { navigator.push(Screen.CornerAdjustment) },
        onScanSaved = { id ->
            navigator.replaceRoot(Screen.Home)
            navigator.push(Screen.DocumentDetail(id))
        },
        viewModel = scanViewModel,
    )
}

/**
 * Hosts the filter step. "Add another page" returns to the Scan root; "Done" commits the page
 * (inside [FilterScreen]) and triggers finalization via a fresh [ScanViewModel] (which shares
 * the same [com.docscanner.shared.presentation.scan.ScanSessionStore] single).
 */
@Composable
private fun FilterFlowHost(navigator: AppNavigator) {
    val scanViewModel: ScanViewModel = koinViewModel()
    FilterScreen(
        onAddAnotherPage = { navigator.switchRoot(Screen.Scan) },
        onDone = { scanViewModel.finish() },
    )
    // Observe save completion to navigate to the new document.
    val state by scanViewModel.state.collectAsStateCompat()
    androidx.compose.runtime.LaunchedEffect(state.savedDocumentId) {
        state.savedDocumentId?.let { id ->
            scanViewModel.onSavedDocumentConsumed()
            navigator.replaceRoot(Screen.Home)
            navigator.push(Screen.DocumentDetail(id))
        }
    }
}

/** App version string surfaced in Settings/About. */
private const val APP_VERSION = "1.0.0"
