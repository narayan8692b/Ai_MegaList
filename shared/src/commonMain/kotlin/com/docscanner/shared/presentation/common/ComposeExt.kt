package com.docscanner.shared.presentation.common

import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.collectAsState
import kotlinx.coroutines.flow.StateFlow

/**
 * Collects a [StateFlow] as Compose [State]. Thin wrapper over [collectAsState] to keep a
 * single, KMP-safe collection point across all screens (we deliberately avoid
 * `collectAsStateWithLifecycle`, whose multiplatform availability we do not rely on).
 */
@Composable
fun <T> StateFlow<T>.collectAsStateCompat(): State<T> = collectAsState()
