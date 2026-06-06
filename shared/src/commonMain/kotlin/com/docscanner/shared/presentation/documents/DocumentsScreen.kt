package com.docscanner.shared.presentation.documents

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CreateNewFolder
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Folder
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.DocumentCard
import com.docscanner.shared.presentation.components.EmptyState
import com.docscanner.shared.presentation.components.FilterChipRow
import org.koin.compose.viewmodel.koinViewModel

/**
 * Documents browser: search bar, tag filter, folders row and a responsive document grid
 * (columns scale with width for tablet layouts). A FAB creates folders. Cards expose
 * favourite toggle, delete (confirm dialog) and move-to-folder.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DocumentsScreen(
    onOpenDocument: (String) -> Unit,
    onOpenFolder: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: DocumentsViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()

    var showCreateFolder by remember { mutableStateOf(false) }
    var pendingDelete by remember { mutableStateOf<Document?>(null) }
    var moveTarget by remember { mutableStateOf<Document?>(null) }

    Scaffold(
        modifier = modifier,
        topBar = { TopAppBar(title = { Text("Documents") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { showCreateFolder = true }) {
                Icon(Icons.Filled.CreateNewFolder, contentDescription = "New folder")
            }
        },
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            OutlinedTextField(
                value = state.query,
                onValueChange = viewModel::onQueryChange,
                placeholder = { Text("Search documents") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            )

            if (state.tags.isNotEmpty()) {
                FilterChipRow(
                    items = state.tags,
                    selected = state.tags.firstOrNull { it.id == state.selectedTagId },
                    label = { it.name },
                    onSelected = { viewModel.onTagSelected(it.id) },
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                )
            }

            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
                val columns = when {
                    maxWidth >= 840.dp -> 4
                    maxWidth >= 600.dp -> 3
                    else -> 2
                }

                if (state.documents.isEmpty() && state.folders.isEmpty() && !state.isLoading) {
                    EmptyState(
                        icon = Icons.Filled.Folder,
                        title = if (state.query.isBlank()) "No documents" else "No matches",
                        subtitle = if (state.query.isBlank()) {
                            "Scanned documents will appear here."
                        } else {
                            "Try a different search."
                        },
                    )
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(columns),
                        modifier = Modifier.fillMaxSize().padding(horizontal = 12.dp),
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(8.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(state.folders, key = { "folder-${it.id}" }) { folder ->
                            FolderCard(folder = folder, onClick = { onOpenFolder(folder.id) })
                        }
                        items(state.documents, key = { it.id }) { doc ->
                            DocumentCard(
                                document = doc,
                                onClick = { onOpenDocument(doc.id) },
                                onToggleFavorite = { viewModel.onToggleFavorite(doc) },
                                onDelete = { pendingDelete = doc },
                                onMove = { moveTarget = doc },
                            )
                        }
                    }
                }
            }
        }
    }

    if (showCreateFolder) {
        TextInputDialog(
            title = "New folder",
            label = "Folder name",
            confirmLabel = "Create",
            onConfirm = {
                viewModel.onCreateFolder(it)
                showCreateFolder = false
            },
            onDismiss = { showCreateFolder = false },
        )
    }

    pendingDelete?.let { doc ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("Delete document?") },
            text = { Text("\"${doc.title}\" will be permanently removed.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.onDelete(doc.id)
                    pendingDelete = null
                }) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text("Cancel") }
            },
        )
    }

    moveTarget?.let { doc ->
        MoveToFolderDialog(
            folders = state.folders,
            onSelect = { folderId ->
                viewModel.onMove(doc.id, folderId)
                moveTarget = null
            },
            onDismiss = { moveTarget = null },
        )
    }
}

@Composable
private fun FolderCard(folder: Folder, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onClick)
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.Folder, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
            Column(modifier = Modifier.padding(start = 12.dp)) {
                Text(folder.name, style = MaterialTheme.typography.titleSmall)
                Text(
                    "${folder.documentCount} item${if (folder.documentCount == 1) "" else "s"}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun MoveToFolderDialog(
    folders: List<Folder>,
    onSelect: (String?) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Move to folder") },
        text = {
            Column {
                TextButton(onClick = { onSelect(null) }) { Text("No folder (root)") }
                folders.forEach { folder ->
                    TextButton(onClick = { onSelect(folder.id) }) { Text(folder.name) }
                }
            }
        },
        confirmButton = {},
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

/** Small reusable text-entry dialog used for folder creation, rename, etc. */
@Composable
fun TextInputDialog(
    title: String,
    label: String,
    confirmLabel: String,
    onConfirm: (String) -> Unit,
    onDismiss: () -> Unit,
    initialValue: String = "",
) {
    var text by remember { mutableStateOf(initialValue) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                label = { Text(label) },
                singleLine = true,
            )
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(text) }, enabled = text.isNotBlank()) {
                Text(confirmLabel)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
