package com.docscanner.shared.presentation.scan

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.docscanner.shared.presentation.common.collectAsStateCompat
import org.koin.compose.viewmodel.koinViewModel

/**
 * Capture entry screen. Offers Camera and Import buttons; on success it routes to the
 * corner-adjustment screen. Shows the running page count so users can build multi-page
 * scans, and a "Done" button to finalize.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScanScreen(
    onGoToCornerAdjustment: () -> Unit,
    onScanSaved: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ScanViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()
    val pageCount by viewModel.sessionPageCount.collectAsStateCompat()

    LaunchedEffect(state.readyForCornerAdjustment) {
        if (state.readyForCornerAdjustment) {
            viewModel.onCornerAdjustmentConsumed()
            onGoToCornerAdjustment()
        }
    }
    LaunchedEffect(state.savedDocumentId) {
        state.savedDocumentId?.let { id ->
            viewModel.onSavedDocumentConsumed()
            onScanSaved(id)
        }
    }

    Scaffold(
        modifier = modifier,
        topBar = { TopAppBar(title = { Text("New Scan") }) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        ) {
            if (pageCount > 0) {
                Text(
                    text = "$pageCount page${if (pageCount == 1) "" else "s"} in this scan",
                    style = MaterialTheme.typography.titleMedium,
                )
            } else {
                Icon(
                    Icons.Filled.CameraAlt,
                    contentDescription = null,
                    modifier = Modifier.size(72.dp),
                    tint = MaterialTheme.colorScheme.primary,
                )
                Text(
                    "Capture or import a page to begin.",
                    style = MaterialTheme.typography.bodyLarge,
                )
            }

            if (state.isBusy) {
                CircularProgressIndicator()
            }

            state.errorMessage?.let {
                Text(it, color = MaterialTheme.colorScheme.error)
            }

            Button(
                onClick = viewModel::captureFromCamera,
                enabled = !state.isBusy,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Icon(Icons.Filled.CameraAlt, contentDescription = null)
                Text("Camera", modifier = Modifier.padding(start = 8.dp))
            }
            OutlinedButton(
                onClick = viewModel::importFromGallery,
                enabled = !state.isBusy,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Icon(Icons.Filled.PhotoLibrary, contentDescription = null)
                Text("Import from gallery", modifier = Modifier.padding(start = 8.dp))
            }

            if (pageCount > 0) {
                Button(
                    onClick = viewModel::finish,
                    enabled = !state.isBusy,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(Icons.Filled.Check, contentDescription = null)
                    Text("Done ($pageCount)", modifier = Modifier.padding(start = 8.dp))
                }
            }
        }
    }
}
