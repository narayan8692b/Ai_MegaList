package com.docscanner.shared.domain.util

/**
 * A lightweight result type used across the domain and data layers to model success
 * and failure without throwing across coroutine/platform boundaries.
 */
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    data class Failure(val error: AppError) : DataResult<Nothing>

    fun getOrNull(): T? = (this as? Success)?.data

    inline fun <R> map(transform: (T) -> R): DataResult<R> = when (this) {
        is Success -> Success(transform(data))
        is Failure -> this
    }

    inline fun onSuccess(action: (T) -> Unit): DataResult<T> {
        if (this is Success) action(data)
        return this
    }

    inline fun onFailure(action: (AppError) -> Unit): DataResult<T> {
        if (this is Failure) action(error)
        return this
    }
}

/** Domain-level error taxonomy. */
sealed class AppError(val message: String, val cause: Throwable? = null) {
    class Storage(message: String, cause: Throwable? = null) : AppError(message, cause)
    class Network(message: String, cause: Throwable? = null) : AppError(message, cause)
    class Ocr(message: String, cause: Throwable? = null) : AppError(message, cause)
    class PdfGeneration(message: String, cause: Throwable? = null) : AppError(message, cause)
    class Camera(message: String, cause: Throwable? = null) : AppError(message, cause)
    class Auth(message: String, cause: Throwable? = null) : AppError(message, cause)
    class NotFound(message: String) : AppError(message)
    class Unknown(message: String, cause: Throwable? = null) : AppError(message, cause)
}

inline fun <T> runCatchingResult(block: () -> T): DataResult<T> =
    try {
        DataResult.Success(block())
    } catch (t: Throwable) {
        DataResult.Failure(AppError.Unknown(t.message ?: "Unexpected error", t))
    }
