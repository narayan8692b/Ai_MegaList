package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.repository.SyncRepository
import com.docscanner.shared.domain.repository.SyncState
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow

class ObserveSyncStateUseCase(private val repository: SyncRepository) {
    operator fun invoke(): Flow<SyncState> = repository.observeSyncState()
}

class SyncNowUseCase(private val repository: SyncRepository) {
    suspend operator fun invoke(): DataResult<Unit> = repository.syncAll()
}
