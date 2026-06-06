package com.docscanner.shared.fake

import com.docscanner.shared.domain.model.Document
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.Folder
import com.docscanner.shared.domain.model.OcrResult
import com.docscanner.shared.domain.model.Page
import com.docscanner.shared.domain.model.PdfQuality
import com.docscanner.shared.domain.model.ScanFilter
import com.docscanner.shared.domain.model.SyncStatus
import com.docscanner.shared.domain.model.Tag
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.platform.IdGenerator
import com.docscanner.shared.domain.platform.ImageProcessor
import com.docscanner.shared.domain.platform.OcrEngine
import com.docscanner.shared.domain.platform.PdfGenerator
import com.docscanner.shared.domain.platform.TimeProvider
import com.docscanner.shared.domain.repository.DocumentRepository
import com.docscanner.shared.domain.repository.FolderRepository
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map

/**
 * In-memory fakes implementing the platform/repository contracts. These are deliberately
 * deterministic so use-case tests can assert exact paths, ids and timestamps.
 */

/**
 * @param detectedCorners corners returned by [detectEdges].
 * @param perspectiveFailure when non-null, [perspectiveCorrect] returns this failure.
 * @param filterFailure when non-null, [applyFilter] returns this failure.
 */
class FakeImageProcessor(
    private val detectedCorners: DocumentCorners = DocumentCorners.FULL,
    private val perspectiveFailure: AppError? = null,
    private val filterFailure: AppError? = null,
) : ImageProcessor {

    val perspectiveCalls = mutableListOf<Pair<String, DocumentCorners>>()
    val filterCalls = mutableListOf<Pair<String, ScanFilter>>()

    override suspend fun detectEdges(imagePath: String): DataResult<DocumentCorners> =
        DataResult.Success(detectedCorners)

    override suspend fun perspectiveCorrect(
        imagePath: String,
        corners: DocumentCorners,
    ): DataResult<String> {
        perspectiveCalls += imagePath to corners
        perspectiveFailure?.let { return DataResult.Failure(it) }
        return DataResult.Success("$imagePath.corrected")
    }

    override suspend fun applyFilter(
        imagePath: String,
        filter: ScanFilter,
    ): DataResult<String> {
        filterCalls += imagePath to filter
        filterFailure?.let { return DataResult.Failure(it) }
        return DataResult.Success("$imagePath.${filter.name}")
    }

    override suspend fun createThumbnail(imagePath: String, maxSize: Int): DataResult<String> =
        DataResult.Success("$imagePath.thumb")

    override suspend fun imageDimensions(imagePath: String): DataResult<Pair<Int, Int>> =
        DataResult.Success(1000 to 1500)
}

class FakeOcrEngine(
    private val result: OcrResult = OcrResult("sample text", emptyList()),
) : OcrEngine {
    override suspend fun recognizeText(imagePath: String): DataResult<OcrResult> =
        DataResult.Success(result)
}

/**
 * @param failure when non-null, [generatePdf]/[exportJpg] return this failure.
 */
class FakePdfGenerator(
    private val failure: AppError? = null,
) : PdfGenerator {

    val generateCalls = mutableListOf<List<String>>()

    override suspend fun generatePdf(
        imagePaths: List<String>,
        outputPath: String,
        quality: PdfQuality,
        password: String?,
    ): DataResult<String> {
        generateCalls += imagePaths
        failure?.let { return DataResult.Failure(it) }
        return DataResult.Success(outputPath)
    }

    override suspend fun exportJpg(
        imagePath: String,
        outputPath: String,
        quality: PdfQuality,
    ): DataResult<String> {
        failure?.let { return DataResult.Failure(it) }
        return DataResult.Success(outputPath)
    }
}

/** Deterministic in-memory file storage. Files written via [writeText]/[copy] are tracked. */
class FakeFileStorage : FileStorage {
    val files = mutableMapOf<String, String>()
    private var counter = 0

    override fun originalsDir(): String = "/originals"
    override fun processedDir(): String = "/processed"
    override fun exportsDir(): String = "/exports"

    override fun newFilePath(dir: String, extension: String): String =
        "$dir/file${counter++}.$extension"

    override suspend fun copy(sourcePath: String, destPath: String): DataResult<String> {
        files[destPath] = files[sourcePath] ?: ""
        return DataResult.Success(destPath)
    }

    override suspend fun writeText(path: String, content: String): DataResult<String> {
        files[path] = content
        return DataResult.Success(path)
    }

    override suspend fun delete(path: String): DataResult<Unit> {
        files.remove(path)
        return DataResult.Success(Unit)
    }

    override fun exists(path: String): Boolean = files.containsKey(path)
}

/** Document repository backed by a [MutableStateFlow]. */
class FakeDocumentRepository(
    initial: List<Document> = emptyList(),
) : DocumentRepository {

    val documents = MutableStateFlow(initial)

    override fun observeDocuments(folderId: String?): Flow<List<Document>> =
        documents.map { list ->
            if (folderId == null) list else list.filter { it.folderId == folderId }
        }

    override fun observeDocument(id: String): Flow<Document?> =
        documents.map { list -> list.firstOrNull { it.id == id } }

    override fun searchDocuments(query: String): Flow<List<Document>> =
        documents.map { list ->
            if (query.isBlank()) {
                list
            } else {
                list.filter { doc ->
                    doc.title.contains(query, ignoreCase = true) ||
                        doc.ocrText.contains(query, ignoreCase = true)
                }
            }
        }

    override suspend fun getDocument(id: String): DataResult<Document> =
        documents.value.firstOrNull { it.id == id }
            ?.let { DataResult.Success(it) }
            ?: DataResult.Failure(AppError.NotFound("No document $id"))

    override suspend fun upsertDocument(document: Document): DataResult<Unit> {
        documents.value = documents.value.filterNot { it.id == document.id } + document
        return DataResult.Success(Unit)
    }

    override suspend fun deleteDocument(id: String): DataResult<Unit> {
        documents.value = documents.value.filterNot { it.id == id }
        return DataResult.Success(Unit)
    }

    override suspend fun setFavorite(id: String, favorite: Boolean): DataResult<Unit> {
        documents.value = documents.value.map {
            if (it.id == id) it.copy(isFavorite = favorite) else it
        }
        return DataResult.Success(Unit)
    }

    override suspend fun setLocked(id: String, locked: Boolean): DataResult<Unit> {
        documents.value = documents.value.map {
            if (it.id == id) it.copy(isLocked = locked) else it
        }
        return DataResult.Success(Unit)
    }

    override suspend fun moveToFolder(documentId: String, folderId: String?): DataResult<Unit> {
        documents.value = documents.value.map {
            if (it.id == documentId) it.copy(folderId = folderId) else it
        }
        return DataResult.Success(Unit)
    }

    override suspend fun addPage(documentId: String, page: Page): DataResult<Unit> {
        documents.value = documents.value.map {
            if (it.id == documentId) it.copy(pages = it.pages + page) else it
        }
        return DataResult.Success(Unit)
    }

    override suspend fun updateSyncStatus(id: String, status: SyncStatus): DataResult<Unit> {
        documents.value = documents.value.map {
            if (it.id == id) it.copy(syncStatus = status) else it
        }
        return DataResult.Success(Unit)
    }
}

/** Folder repository backed by a [MutableStateFlow]. */
class FakeFolderRepository(
    initial: List<Folder> = emptyList(),
) : FolderRepository {

    val folders = MutableStateFlow(initial)
    val tags = MutableStateFlow<List<Tag>>(emptyList())

    override fun observeFolders(parentId: String?): Flow<List<Folder>> =
        folders.map { list -> list.filter { it.parentId == parentId } }

    override suspend fun createFolder(folder: Folder): DataResult<Unit> {
        folders.value = folders.value + folder
        return DataResult.Success(Unit)
    }

    override suspend fun renameFolder(id: String, name: String): DataResult<Unit> {
        folders.value = folders.value.map { if (it.id == id) it.copy(name = name) else it }
        return DataResult.Success(Unit)
    }

    override suspend fun deleteFolder(id: String): DataResult<Unit> {
        folders.value = folders.value.filterNot { it.id == id }
        return DataResult.Success(Unit)
    }

    override fun observeTags(): Flow<List<Tag>> = tags

    override suspend fun createTag(tag: Tag): DataResult<Unit> {
        tags.value = tags.value + tag
        return DataResult.Success(Unit)
    }

    override suspend fun deleteTag(id: String): DataResult<Unit> {
        tags.value = tags.value.filterNot { it.id == id }
        return DataResult.Success(Unit)
    }

    override suspend fun setDocumentTags(
        documentId: String,
        tagIds: List<String>,
    ): DataResult<Unit> = DataResult.Success(Unit)
}

/** Deterministic id generator: "$prefix-0", "$prefix-1", ... */
class FixedIdGenerator(private val prefix: String = "id") : IdGenerator {
    private var counter = 0
    override fun newId(): String = "$prefix-${counter++}"
}

/** Time provider that always returns [fixed]. */
class FixedTimeProvider(private val fixed: Long = 1_000L) : TimeProvider {
    override fun nowMillis(): Long = fixed
}
