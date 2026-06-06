package com.docscanner.shared.presentation.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.ThemeMode
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.FilterChipRow
import com.docscanner.shared.presentation.documents.TextInputDialog
import org.koin.compose.viewmodel.koinViewModel

/**
 * Settings screen: theme, security (biometric + PIN), scanning defaults, cloud sync and
 * about/version info. All toggles persist immediately via the [SettingsViewModel].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    appVersion: String,
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()
    val settings = state.settings
    var showPinDialog by remember { mutableStateOf(false) }

    Scaffold(
        modifier = modifier,
        topBar = { TopAppBar(title = { Text("Settings") }) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            SectionTitle("Appearance")
            Text("Theme", style = MaterialTheme.typography.bodyLarge)
            FilterChipRow(
                items = ThemeMode.entries.toList(),
                selected = settings.themeMode,
                label = { it.name.lowercase().replaceFirstChar { c -> c.uppercase() } },
                onSelected = viewModel::setThemeMode,
                modifier = Modifier.fillMaxWidth(),
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            SectionTitle("Security")
            SwitchRow(
                label = "Biometric lock",
                checked = settings.biometricLockEnabled,
                enabled = state.biometricAvailable,
                onChange = viewModel::setBiometricLock,
                subtitle = if (state.biometricAvailable) null else "Not available on this device",
            )
            SwitchRow(
                label = "PIN lock",
                checked = settings.pinLockEnabled,
                onChange = { if (it) showPinDialog = true },
                subtitle = if (settings.pinLockEnabled) "Enabled" else "Set a numeric PIN",
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            SectionTitle("Scanning")
            Text("Default filter", style = MaterialTheme.typography.bodyLarge)
            FilterChipRow(
                items = ScanFilter.entries.toList(),
                selected = settings.defaultFilter,
                label = { it.displayName },
                onSelected = viewModel::setDefaultFilter,
                modifier = Modifier.fillMaxWidth(),
            )
            SwitchRow(
                label = "Auto edge detection",
                checked = settings.autoEdgeDetection,
                onChange = viewModel::setAutoEdgeDetection,
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            SectionTitle("Cloud sync")
            SwitchRow(
                label = "Enable cloud sync",
                checked = settings.cloudSyncEnabled,
                onChange = viewModel::setCloudSync,
                subtitle = "Provider: ${settings.cloudProvider.name}",
            )
            val sync = state.syncState
            Text(
                text = when {
                    sync.isSyncing -> "Syncing..."
                    sync.errorMessage != null -> "Error: ${sync.errorMessage}"
                    sync.lastSyncedAt != null -> "${sync.pendingCount} pending"
                    else -> "Not synced yet"
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Button(
                onClick = viewModel::syncNow,
                enabled = settings.cloudSyncEnabled && !sync.isSyncing,
            ) {
                Text("Sync now")
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            SectionTitle("About")
            Text("Platform: ${state.platformName}", style = MaterialTheme.typography.bodyMedium)
            Text("Version: $appVersion", style = MaterialTheme.typography.bodyMedium)
        }
    }

    if (showPinDialog) {
        TextInputDialog(
            title = "Set PIN",
            label = "PIN (min 4 digits)",
            confirmLabel = "Save",
            onConfirm = {
                viewModel.setPin(it)
                showPinDialog = false
            },
            onDismiss = { showPinDialog = false },
        )
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 4.dp),
    )
}

@Composable
private fun SwitchRow(
    label: String,
    checked: Boolean,
    onChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    subtitle: String? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth().padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(label, style = MaterialTheme.typography.bodyLarge)
            if (subtitle != null) {
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        Switch(checked = checked, onCheckedChange = onChange, enabled = enabled)
    }
}
