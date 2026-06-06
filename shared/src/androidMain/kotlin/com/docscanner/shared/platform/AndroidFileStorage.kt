package com.docscanner.shared.platform

import android.content.Context
import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.util.UUID

/**
 * Android [FileStorage] over the app-private `filesDir`, with sub-directories for
 * originals, processed page images and exports. All directories are created on demand.
 */
class AndroidFileStorage(private val context: Context) : FileStorage {

    private fun dir(name: String): File =
        File(context.filesDir, name).apply { mkdirs() }

    override fun originalsDir(): String = dir("originals").absolutePath

    override fun processedDir(): String = dir("processed").absolutePath

    override fun exportsDir(): String = dir("exports").absolutePath

    override fun newFilePath(dir: String, extension: String): String {
        File(dir).mkdirs()
        val ext = extension.removePrefix(".")
        return File(dir, "${UUID.randomUUID()}.$ext").absolutePath
    }

    override suspend fun copy(sourcePath: String, destPath: String): DataResult<String> =
        withContext(Dispatchers.IO) {
            try {
                val source = File(sourcePath)
                if (!source.exists()) {
                    return@withContext DataResult.Failure(
                        AppError.NotFound("Source file does not exist: $sourcePath"),
                    )
                }
                val dest = File(destPath)
                dest.parentFile?.mkdirs()
                source.inputStream().use { input ->
                    dest.outputStream().use { output -> input.copyTo(output) }
                }
                DataResult.Success(dest.absolutePath)
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("File copy failed", e))
            }
        }

    override suspend fun writeText(path: String, content: String): DataResult<String> =
        withContext(Dispatchers.IO) {
            try {
                val file = File(path)
                file.parentFile?.mkdirs()
                file.writeText(content, Charsets.UTF_8)
                DataResult.Success(file.absolutePath)
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("Write text failed", e))
            }
        }

    override suspend fun delete(path: String): DataResult<Unit> =
        withContext(Dispatchers.IO) {
            try {
                val file = File(path)
                if (file.exists() && !file.delete()) {
                    DataResult.Failure(AppError.Storage("Unable to delete file: $path"))
                } else {
                    DataResult.Success(Unit)
                }
            } catch (e: Throwable) {
                DataResult.Failure(AppError.Storage("Delete failed", e))
            }
        }

    override fun exists(path: String): Boolean = File(path).exists()
}
