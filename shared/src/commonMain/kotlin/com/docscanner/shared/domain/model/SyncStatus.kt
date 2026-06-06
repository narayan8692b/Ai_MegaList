package com.docscanner.shared.domain.model

/** Cloud synchronization state of a [Document]. */
enum class SyncStatus {
    LOCAL_ONLY,
    PENDING_UPLOAD,
    SYNCING,
    SYNCED,
    ERROR,
}
