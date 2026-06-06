package com.docscanner.shared.presentation.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DocumentScanner
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.DocumentCard
import com.docscanner.shared.presentation.components.EmptyState
import org.koin.compose.viewmodel.koinViewModel

/**
 * Home dashboard: quick scan/import actions, a search entry point, recent documents and
 * favourites. All data is observed offline-first from the repository.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onScan: () -> Unit,
    onImport: () -> Unit,
    onSearch: () -> Unit,
    onOpenDocument: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: HomeViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text("DocScanner") },
                actions = {
                    IconButton(onClick = onSearch) {
                        Icon(Icons.Filled.Search, contentDescription = "Search")
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            // Quick actions
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                QuickAction(
                    label = "Scan",
                    icon = Icons.Filled.DocumentScanner,
                    onClick = onScan,
                    modifier = Modifier.weight(1f),
                )
                QuickAction(
                    label = "Import",
                    icon = Icons.Filled.PhotoLibrary,
                    onClick = onImport,
                    modifier = Modifier.weight(1f),
                )
            }

            if (state.favorites.isNotEmpty()) {
                SectionHeader("Favorites")
                LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(state.favorites, key = { it.id }) { doc ->
                        DocumentCard(
                            document = doc,
                            onClick = { onOpenDocument(doc.id) },
                            onToggleFavorite = { viewModel.onToggleFavorite(doc) },
                            onDelete = {},
                            modifier = Modifier.width(160.dp),
                        )
                    }
                }
            }

            SectionHeader("Recent")
            if (state.recent.isEmpty() && !state.isLoading) {
                EmptyState(
                    icon = Icons.Filled.DocumentScanner,
                    title = "No documents yet",
                    subtitle = "Scan or import a page to get started.",
                    actionLabel = "Scan now",
                    onAction = onScan,
                    modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
                )
            } else {
                state.recent.forEach { doc ->
                    DocumentCard(
                        document = doc,
                        onClick = { onOpenDocument(doc.id) },
                        onToggleFavorite = { viewModel.onToggleFavorite(doc) },
                        onDelete = {},
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text = text, style = MaterialTheme.typography.titleMedium)
}

@Composable
private fun QuickAction(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(modifier = modifier) {
        OutlinedButton(
            onClick = onClick,
            modifier = Modifier.fillMaxWidth().padding(8.dp),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(icon, contentDescription = null)
                Text(label, modifier = Modifier.padding(top = 4.dp))
            }
        }
    }
}
