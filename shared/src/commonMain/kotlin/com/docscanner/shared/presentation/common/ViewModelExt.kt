package com.docscanner.shared.presentation.common

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Launch a coroutine on this scope, swallowing cancellation but logging nothing for other
 * failures (use-cases already return [com.docscanner.shared.domain.util.DataResult], so most
 * call sites should inspect the result instead of relying on exceptions). This keeps
 * fire-and-forget UI actions from crashing the app.
 */
fun CoroutineScope.launchSafe(block: suspend CoroutineScope.() -> Unit): Job =
    launch {
        try {
            block()
        } catch (e: kotlinx.coroutines.CancellationException) {
            throw e
        } catch (_: Throwable) {
            // Intentionally ignored: user-facing errors flow through DataResult/UI state.
        }
    }
