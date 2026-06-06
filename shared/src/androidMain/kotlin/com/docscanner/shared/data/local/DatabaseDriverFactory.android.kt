package com.docscanner.shared.data.local

import android.content.Context
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import com.docscanner.shared.database.DocScannerDatabase

/**
 * Android [DatabaseDriverFactory] backed by [AndroidSqliteDriver]. The [Context] is
 * supplied by Koin via `androidContext()`.
 */
actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver(): SqlDriver =
        AndroidSqliteDriver(
            schema = DocScannerDatabase.Schema,
            context = context,
            name = "docscanner.db",
        )
}
