package com.docscanner.shared.domain.usecase

import com.docscanner.shared.domain.model.Folder
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.platform.TimeProvider
import com.docscanner.shared.domain.repository.FolderRepository
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow

class GetFoldersUseCase(private val repository: FolderRepository) {
    operator fun invoke(parentId: String? = null): Flow<List<Folder>> =
        repository.observeFolders(parentId)
}

class CreateFolderUseCase(
    private val repository: FolderRepository,
    private val idGenerator: IdGenerator,
    private val timeProvider: TimeProvider,
) {
    suspend operator fun invoke(
        name: String,
        parentId: String? = null,
        color: Long? = null,
    ): DataResult<Unit> = repository.createFolder(
        Folder(
            id = idGenerator.newId(),
            name = name.trim(),
            parentId = parentId,
            color = color,
            createdAt = timeProvider.nowMillis(),
        ),
    )
}

class DeleteFolderUseCase(private val repository: FolderRepository) {
    suspend operator fun invoke(id: String): DataResult<Unit> = repository.deleteFolder(id)
}

class GetTagsUseCase(private val repository: FolderRepository) {
    operator fun invoke(): Flow<List<Tag>> = repository.observeTags()
}

class CreateTagUseCase(
    private val repository: FolderRepository,
    private val idGenerator: IdGenerator,
) {
    suspend operator fun invoke(name: String, color: Long? = null): DataResult<Unit> =
        repository.createTag(Tag(id = idGenerator.newId(), name = name.trim(), color = color))
}

class SetDocumentTagsUseCase(private val repository: FolderRepository) {
    suspend operator fun invoke(documentId: String, tagIds: List<String>): DataResult<Unit> =
        repository.setDocumentTags(documentId, tagIds)
}
