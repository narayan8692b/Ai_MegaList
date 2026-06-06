package com.docscanner.shared.presentation.documents

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.DocumentCard
import com.docscanner.shared.presentation.components.EmptyState
import org.koin.compose.viewmodel.koinViewModel
import org.koin.core.parameter.parametersOf

/**
 * Shows the documents contained in a single folder. The folder id is passed to the
 * [FolderDetailViewModel] via Koin parameters.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FolderDetailScreen(
    folderId: String,
    title: String,
    onBack: () -> Unit,
    onOpenDocument: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: FolderDetailViewModel = koinViewModel { parametersOf(folderId) },
) {
    val state by viewModel.state.collectAsStateCompat()

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        if (state.documents.isEmpty() && !state.isLoading) {
            EmptyState(
                icon = Icons.Filled.Folder,
                title = "Empty folder",
                subtitle = "Move documents here to organize them.",
                modifier = Modifier.padding(padding),
            )
        } else {
            BoxWithConstraints(modifier = Modifier.fillMaxSize().padding(padding)) {
                val columns = if (maxWidth >= 600.dp) 3 else 2
                LazyVerticalGrid(
                    columns = GridCells.Fixed(columns),
                    modifier = Modifier.fillMaxSize().padding(horizontal = 12.dp),
                    contentPadding = PaddingValues(8.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    items(state.documents, key = { it.id }) { doc ->
                        DocumentCard(
                            document = doc,
                            onClick = { onOpenDocument(doc.id) },
                            onToggleFavorite = { viewModel.onToggleFavorite(doc) },
                            onDelete = { viewModel.onDelete(doc.id) },
                            onMove = { viewModel.onRemoveFromFolder(doc.id) },
                        )
                    }
                }
            }
        }
    }
}
