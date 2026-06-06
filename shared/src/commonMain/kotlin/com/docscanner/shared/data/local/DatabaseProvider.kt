package com.docscanner.shared.data.local

import com.docscanner.shared.database.DocScannerDatabase

/**
 * Builds the [DocScannerDatabase] from a platform-supplied [DatabaseDriverFactory].
 *
 * The schema (CREATE TABLE statements) lives in the `.sq` files and is applied by
 * SQLDelight when the driver is created. Foreign-key enforcement (used for the
 * `ON DELETE CASCADE` / `ON DELETE SET NULL` constraints) is enabled by the platform
 * driver factory itself (e.g. via the Android `AndroidSqliteDriver` callback or a
 * `PRAGMA foreign_keys=ON`), so no extra wiring is required here.
 */
fun createDatabase(driverFactory: DatabaseDriverFactory): DocScannerDatabase =
    DocScannerDatabase(driverFactory.createDriver())
