package com.docscanner.shared.presentation.scan

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.PlatformImage
import org.koin.compose.viewmodel.koinViewModel

/**
 * Filter-selection screen. Shows a large preview of the perspective-corrected page and a
 * horizontal selector of all [ScanFilter] options. "Add another page" commits the page and
 * returns to capture; "Done" commits and finalizes the whole scan.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FilterScreen(
    onAddAnotherPage: () -> Unit,
    onDone: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: FilterViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()

    LaunchedEffect(state.addAnother) {
        if (state.addAnother) {
            viewModel.onAddAnotherConsumed()
            onAddAnotherPage()
        }
    }

    Scaffold(
        modifier = modifier,
        topBar = { TopAppBar(title = { Text("Enhance") }) },
        bottomBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(
                    onClick = viewModel::savePageAndAddAnother,
                    enabled = !state.isProcessing,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.Add, contentDescription = null)
                    Text("Add page", modifier = Modifier.padding(start = 4.dp))
                }
                Button(
                    onClick = {
                        viewModel.savePageForFinish()
                        onDone()
                    },
                    enabled = !state.isProcessing,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.Check, contentDescription = null)
                    Text("Done", modifier = Modifier.padding(start = 4.dp))
                }
            }
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .background(Color.Black),
                contentAlignment = Alignment.Center,
            ) {
                val preview = state.previewPath
                if (preview != null) {
                    PlatformImage(
                        path = preview,
                        contentDescription = "Filtered preview",
                        modifier = Modifier.fillMaxSize(),
                    )
                } else {
                    Text("No preview", color = Color.White)
                }
                if (state.isProcessing) {
                    CircularProgressIndicator(color = Color.White)
                }
            }

            state.errorMessage?.let {
                Text(
                    it,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                )
            }

            Text(
                "Filters",
                style = MaterialTheme.typography.titleSmall,
                modifier = Modifier.padding(start = 16.dp, top = 8.dp),
            )
            LazyRow(
                modifier = Modifier.fillMaxWidth().padding(8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(state.availableFilters, key = { it.name }) { filter ->
                    FilterThumb(
                        filter = filter,
                        previewPath = state.previewPath,
                        selected = filter == state.selected,
                        onClick = { viewModel.selectFilter(filter) },
                    )
                }
            }
        }
    }
}

/**
 * A single filter option. Shows the current preview image as a representative thumbnail with
 * the filter's display name; the selected one is outlined. (A true per-filter thumbnail would
 * require pre-rendering each filter, which is deferred for performance.)
 */
@Composable
private fun FilterThumb(
    filter: ScanFilter,
    previewPath: String?,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier.width(80.dp).clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .then(
                    if (selected) {
                        Modifier.border(
                            width = 3.dp,
                            color = MaterialTheme.colorScheme.primary,
                            shape = RoundedCornerShape(8.dp),
                        )
                    } else {
                        Modifier
                    },
                ),
            contentAlignment = Alignment.Center,
        ) {
            if (previewPath != null) {
                PlatformImage(
                    path = previewPath,
                    contentDescription = filter.displayName,
                    modifier = Modifier.fillMaxSize(),
                )
            }
        }
        Text(
            text = filter.displayName,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center,
            maxLines = 2,
            modifier = Modifier.padding(top = 4.dp),
        )
    }
}
