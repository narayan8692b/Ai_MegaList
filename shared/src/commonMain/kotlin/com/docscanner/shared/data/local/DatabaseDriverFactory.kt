package com.docscanner.shared.data.local

import app.cash.sqldelight.db.SqlDriver

/** Creates the platform-specific SQLDelight [SqlDriver] (AndroidSqliteDriver / NativeSqliteDriver). */
expect class DatabaseDriverFactory {
    fun createDriver(): SqlDriver
}
