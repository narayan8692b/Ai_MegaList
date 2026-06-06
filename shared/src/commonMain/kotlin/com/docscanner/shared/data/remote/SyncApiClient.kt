package com.docscanner.shared.data.remote

import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.serialization.Serializable

/**
 * Thin Ktor transport for syncing document metadata against a REST backend. The
 * [HttpClient] (with content-negotiation/JSON installed) is supplied by the platform DI
 * module. Binary page/PDF files are transferred by the platform [com.docscanner.shared.domain.platform.CloudStorageClient];
 * this client only moves the lightweight metadata.
 */
class SyncApiClient(
    private val client: HttpClient,
    private val baseUrl: String = DEFAULT_BASE_URL,
) {
    /** Uploads metadata for a single document. */
    suspend fun uploadDocument(metadata: DocumentMetadataDto): DataResult<Unit> = request {
        val response = client.post("$baseUrl/documents") {
            contentType(ContentType.Application.Json)
            setBody(metadata)
        }
        if (response.status.isSuccess()) {
            DataResult.Success(Unit)
        } else {
            DataResult.Failure(AppError.Network("Upload failed: ${response.status}"))
        }
    }

    /** Lists remote document ids/metadata, optionally newer than [sinceMillis]. */
    suspend fun listDocuments(sinceMillis: Long? = null): DataResult<List<DocumentMetadataDto>> = request {
        val response = client.get("$baseUrl/documents") {
            if (sinceMillis != null) {
                parameter("since", sinceMillis)
            }
        }
        if (response.status.isSuccess()) {
            DataResult.Success(response.body<List<DocumentMetadataDto>>())
        } else {
            DataResult.Failure(AppError.Network("List failed: ${response.status}"))
        }
    }

    /** Downloads metadata for a single document by id. */
    suspend fun downloadDocument(id: String): DataResult<DocumentMetadataDto> = request {
        val response = client.get("$baseUrl/documents/$id")
        if (response.status.isSuccess()) {
            DataResult.Success(response.body<DocumentMetadataDto>())
        } else {
            DataResult.Failure(AppError.Network("Download failed: ${response.status}"))
        }
    }

    private suspend inline fun <T> request(block: () -> DataResult<T>): DataResult<T> =
        try {
            block()
        } catch (t: Throwable) {
            DataResult.Failure(AppError.Network(t.message ?: "Network error", t))
        }

    private companion object {
        const val DEFAULT_BASE_URL = "https://api.docscanner.example.com/v1"
    }
}

/** Wire representation of a document's metadata exchanged with the sync backend. */
@Serializable
data class DocumentMetadataDto(
    val id: String,
    val title: String,
    val folderId: String? = null,
    val ocrText: String = "",
    val createdAt: Long,
    val updatedAt: Long,
    val pageRemotePaths: List<String> = emptyList(),
    val tagIds: List<String> = emptyList(),
)
