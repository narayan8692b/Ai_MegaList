package com.docscanner.shared.domain.platform

import com.docscanner.shared.domain.util.DataResult

/** Abstraction over the app's private file storage for images and exported documents. */
interface FileStorage {
    /** Root directory for original captures. */
    fun originalsDir(): String

    /** Root directory for processed page images. */
    fun processedDir(): String

    /** Root directory for generated PDFs / exports. */
    fun exportsDir(): String

    /** Build a unique file path inside [dir] with the given [extension]. */
    fun newFilePath(dir: String, extension: String): String

    suspend fun copy(sourcePath: String, destPath: String): DataResult<String>

    suspend fun writeText(path: String, content: String): DataResult<String>

    suspend fun delete(path: String): DataResult<Unit>

    fun exists(path: String): Boolean
}
