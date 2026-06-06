package com.docscanner.shared.domain.repository

import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow

/** Cloud synchronization across devices (Google Drive / iCloud). */
interface SyncRepository {
    fun observeSyncState(): Flow<SyncState>

    /** Push pending local changes to the cloud. */
    suspend fun syncUp(): DataResult<Unit>

    /** Pull remote changes into the local database. */
    suspend fun syncDown(): DataResult<Unit>

    /** Full bidirectional sync. */
    suspend fun syncAll(): DataResult<Unit>
}

data class SyncState(
    val isSyncing: Boolean = false,
    val lastSyncedAt: Long? = null,
    val pendingCount: Int = 0,
    val errorMessage: String? = null,
)
