package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.FileStorage
import com.docscanner.shared.domain.util.AppError
import com.docscanner.shared.domain.util.DataResult
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.NSUserDomainMask
import platform.Foundation.NSUUID
import platform.Foundation.stringByAppendingPathComponent
import platform.Foundation.writeToFile

/**
 * iOS [FileStorage] backed by [NSFileManager]. All app data lives under the app sandbox's
 * Documents directory in three subdirectories: originals/, processed/, exports/. Those
 * directories are created lazily on first access.
 */
@OptIn(ExperimentalForeignApi::class)
class IosFileStorage : FileStorage {

    private val fileManager = NSFileManager.defaultManager

    private val documentsPath: String by lazy {
        val paths = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory,
            NSUserDomainMask,
            true,
        )
        // First entry is the Documents directory path.
        (paths.firstOrNull() as? String) ?: NSHomeFallback()
    }

    private fun NSHomeFallback(): String = platform.Foundation.NSHomeDirectory() + "/Documents"

    private fun ensureDir(name: String): String {
        val dir = (documentsPath as NSString).stringByAppendingPathComponent(name)
        if (!fileManager.fileExistsAtPath(dir)) {
            fileManager.createDirectoryAtPath(
                path = dir,
                withIntermediateDirectories = true,
                attributes = null,
                error = null,
            )
        }
        return dir
    }

    override fun originalsDir(): String = ensureDir("originals")

    override fun processedDir(): String = ensureDir("processed")

    override fun exportsDir(): String = ensureDir("exports")

    override fun newFilePath(dir: String, extension: String): String {
        val fileName = NSUUID().UUIDString() + "." + extension.trimStart('.')
        return (dir as NSString).stringByAppendingPathComponent(fileName)
    }

    override suspend fun copy(sourcePath: String, destPath: String): DataResult<String> =
        withContext(Dispatchers.Default) {
            try {
                // Remove any existing destination first; NSFileManager.copy fails if dest exists.
                if (fileManager.fileExistsAtPath(destPath)) {
                    fileManager.removeItemAtPath(destPath, error = null)
                }
                val ok = fileManager.copyItemAtPath(sourcePath, toPath = destPath, error = null)
                if (ok) {
                    DataResult.Success(destPath)
                } else {
                    DataResult.Failure(AppError.Storage("Failed to copy $sourcePath -> $destPath"))
                }
            } catch (t: Throwable) {
                DataResult.Failure(AppError.Storage(t.message ?: "copy failed", t))
            }
        }

    override suspend fun writeText(path: String, content: String): DataResult<String> =
        withContext(Dispatchers.Default) {
            try {
                val ok = (content as NSString).writeToFile(
                    path = path,
                    atomically = true,
                    encoding = NSUTF8StringEncoding,
                    error = null,
                )
                if (ok) {
                    DataResult.Success(path)
                } else {
                    DataResult.Failure(AppError.Storage("Failed to write text to $path"))
                }
            } catch (t: Throwable) {
                DataResult.Failure(AppError.Storage(t.message ?: "writeText failed", t))
            }
        }

    override suspend fun delete(path: String): DataResult<Unit> =
        withContext(Dispatchers.Default) {
            try {
                if (fileManager.fileExistsAtPath(path)) {
                    val ok = fileManager.removeItemAtPath(path, error = null)
                    if (!ok) {
                        return@withContext DataResult.Failure(
                            AppError.Storage("Failed to delete $path"),
                        )
                    }
                }
                DataResult.Success(Unit)
            } catch (t: Throwable) {
                DataResult.Failure(AppError.Storage(t.message ?: "delete failed", t))
            }
        }

    override fun exists(path: String): Boolean = fileManager.fileExistsAtPath(path)
}
