package com.docscanner.shared.domain.model

/** User-configurable application settings, persisted via the settings repository. */
data class AppSettings(
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val biometricLockEnabled: Boolean = false,
    val pinLockEnabled: Boolean = false,
    val defaultFilter: ScanFilter = ScanFilter.MAGIC_COLOR,
    val autoEdgeDetection: Boolean = true,
    val cloudSyncEnabled: Boolean = false,
    val cloudProvider: CloudProvider = CloudProvider.NONE,
    val pdfQuality: PdfQuality = PdfQuality.HIGH,
)

enum class ThemeMode { LIGHT, DARK, SYSTEM }

enum class CloudProvider { NONE, GOOGLE_DRIVE, ICLOUD }

enum class PdfQuality(val jpegQuality: Int) {
    LOW(50),
    MEDIUM(75),
    HIGH(90),
    ORIGINAL(100),
}
