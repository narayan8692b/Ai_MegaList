package com.docscanner.shared.domain.repository

import com.docscanner.shared.domain.model.Folder
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow

interface FolderRepository {
    fun observeFolders(parentId: String? = null): Flow<List<Folder>>

    suspend fun createFolder(folder: Folder): DataResult<Unit>

    suspend fun renameFolder(id: String, name: String): DataResult<Unit>

    suspend fun deleteFolder(id: String): DataResult<Unit>

    fun observeTags(): Flow<List<Tag>>

    suspend fun createTag(tag: Tag): DataResult<Unit>

    suspend fun deleteTag(id: String): DataResult<Unit>

    suspend fun setDocumentTags(documentId: String, tagIds: List<String>): DataResult<Unit>
}
