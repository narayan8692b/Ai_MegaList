package com.docscanner.shared.presentation.documents

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TextSnippet
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.PlatformImage
import org.koin.compose.viewmodel.koinViewModel

/**
 * Document detail: a horizontal page pager, the extracted OCR text with copy + export-text,
 * export-as-PDF (with optional password) and export-as-JPG (both shared via the native sheet),
 * plus favourite, lock, rename and tag editing.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DocumentDetailScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: DocumentDetailViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()
    val clipboard = LocalClipboardManager.current
    val snackbarHost = remember { SnackbarHostState() }

    var showPasswordDialog by remember { mutableStateOf(false) }
    var showRenameDialog by remember { mutableStateOf(false) }
    var showTagDialog by remember { mutableStateOf(false) }

    LaunchedEffect(state.message) {
        state.message?.let {
            snackbarHost.showSnackbar(it.text)
            viewModel.consumeMessage()
        }
    }

    val doc = state.document

    Scaffold(
        modifier = modifier,
        snackbarHost = { SnackbarHost(snackbarHost) },
        topBar = {
            TopAppBar(
                title = { Text(doc?.title ?: "Document") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (doc != null) {
                        IconButton(onClick = viewModel::onToggleFavorite) {
                            Icon(
                                imageVector = if (doc.isFavorite) Icons.Filled.Star else Icons.Outlined.StarBorder,
                                contentDescription = "Favorite",
                            )
                        }
                        IconButton(onClick = viewModel::onToggleLock) {
                            Icon(
                                imageVector = if (doc.isLocked) Icons.Filled.Lock else Icons.Filled.LockOpen,
                                contentDescription = "Lock",
                            )
                        }
                        IconButton(onClick = { showRenameDialog = true }) {
                            Icon(Icons.Filled.Edit, contentDescription = "Rename")
                        }
                    }
                },
            )
        },
    ) { padding ->
        if (doc == null) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState()),
        ) {
            // Page pager
            val pagerState = rememberPagerState(pageCount = { doc.pages.size.coerceAtLeast(1) })
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(420.dp)
                    .background(Color.Black),
                contentAlignment = Alignment.Center,
            ) {
                if (doc.pages.isEmpty()) {
                    Text("No pages", color = Color.White)
                } else {
                    HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { index ->
                        PlatformImage(
                            path = doc.pages[index].processedImagePath,
                            contentDescription = "Page ${index + 1}",
                            modifier = Modifier.fillMaxSize(),
                        )
                    }
                    Text(
                        text = "${pagerState.currentPage + 1} / ${doc.pages.size}",
                        color = Color.White,
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier.align(Alignment.BottomCenter).padding(8.dp),
                    )
                }
            }

            // Tags row
            if (doc.tags.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    doc.tags.forEach { tag ->
                        AssistChip(onClick = { showTagDialog = true }, label = { Text(tag.name) })
                    }
                }
            }

            // Export actions
            Row(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(
                    onClick = { showPasswordDialog = true },
                    enabled = !state.isBusy,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.PictureAsPdf, contentDescription = null)
                    Text("PDF", modifier = Modifier.padding(start = 4.dp))
                }
                OutlinedButton(
                    onClick = viewModel::exportAndShareJpg,
                    enabled = !state.isBusy,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.Image, contentDescription = null)
                    Text("JPG", modifier = Modifier.padding(start = 4.dp))
                }
                OutlinedButton(
                    onClick = { showTagDialog = true },
                    enabled = !state.isBusy,
                    modifier = Modifier.weight(1f),
                ) {
                    Text("Tags")
                }
            }

            if (state.isBusy) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.CenterHorizontally).padding(8.dp))
            }

            // OCR text
            Card(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text("Recognized text", style = MaterialTheme.typography.titleMedium)
                        Row {
                            IconButton(
                                onClick = { clipboard.setText(AnnotatedString(doc.ocrText)) },
                                enabled = doc.ocrText.isNotBlank(),
                            ) {
                                Icon(Icons.Filled.ContentCopy, contentDescription = "Copy")
                            }
                            IconButton(
                                onClick = viewModel::exportAndShareText,
                                enabled = doc.ocrText.isNotBlank() && !state.isBusy,
                            ) {
                                Icon(Icons.Filled.TextSnippet, contentDescription = "Export text")
                            }
                        }
                    }
                    Text(
                        text = doc.ocrText.ifBlank { "No text recognized." },
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(top = 8.dp),
                    )
                }
            }
        }
    }

    if (showPasswordDialog) {
        PdfPasswordDialog(
            onConfirm = { password ->
                viewModel.exportAndSharePdf(password)
                showPasswordDialog = false
            },
            onDismiss = { showPasswordDialog = false },
        )
    }

    if (showRenameDialog && doc != null) {
        TextInputDialog(
            title = "Rename document",
            label = "Title",
            confirmLabel = "Save",
            initialValue = doc.title,
            onConfirm = {
                viewModel.onRename(it)
                showRenameDialog = false
            },
            onDismiss = { showRenameDialog = false },
        )
    }

    if (showTagDialog && doc != null) {
        TagSelectionDialog(
            document = doc,
            allTags = state.allTags,
            onConfirm = { ids ->
                viewModel.onSetTags(ids)
                showTagDialog = false
            },
            onDismiss = { showTagDialog = false },
        )
    }
}

/** Optional-password dialog for PDF export. Empty password generates an unprotected PDF. */
@Composable
private fun PdfPasswordDialog(
    onConfirm: (String?) -> Unit,
    onDismiss: () -> Unit,
) {
    var password by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Export PDF") },
        text = {
            Column {
                Text("Optionally protect the PDF with a password.")
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password (optional)") },
                    singleLine = true,
                    modifier = Modifier.padding(top = 8.dp),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(password.ifBlank { null }) }) { Text("Export") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

/** Multi-select tag chooser bound to the document's current tags. */
@Composable
private fun TagSelectionDialog(
    document: Document,
    allTags: List<Tag>,
    onConfirm: (List<String>) -> Unit,
    onDismiss: () -> Unit,
) {
    val selected = remember { mutableStateOf(document.tags.map { it.id }.toSet()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Tags") },
        text = {
            Column {
                if (allTags.isEmpty()) {
                    Text("No tags yet. Create tags from Documents.")
                }
                allTags.forEach { tag ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Checkbox(
                            checked = selected.value.contains(tag.id),
                            onCheckedChange = { checked ->
                                selected.value = if (checked) {
                                    selected.value + tag.id
                                } else {
                                    selected.value - tag.id
                                }
                            },
                        )
                        Text(tag.name)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(selected.value.toList()) }) { Text("Save") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
