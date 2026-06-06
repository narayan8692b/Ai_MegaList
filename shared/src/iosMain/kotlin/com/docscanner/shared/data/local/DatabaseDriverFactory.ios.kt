package com.docscanner.shared.data.local

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import com.docscanner.shared.database.DocScannerDatabase

/**
 * iOS [DatabaseDriverFactory] backed by SQLDelight's [NativeSqliteDriver]. The database
 * file `docscanner.db` is created in the app's Application Support directory managed by
 * the driver.
 */
actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver =
        NativeSqliteDriver(
            schema = DocScannerDatabase.Schema,
            name = "docscanner.db",
        )
}
