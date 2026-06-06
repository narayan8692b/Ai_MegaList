package com.docscanner.shared.presentation.theme

import androidx.compose.ui.graphics.Color

/**
 * Brand color palette for DocScanner. A calm "ink on paper" identity: a deep indigo
 * primary suggesting scanned ink, a teal secondary for actions, and warm paper neutrals.
 */
internal object DocColors {
    // Primary (indigo)
    val IndigoLight = Color(0xFF3F51B5)
    val IndigoDark = Color(0xFFAEB6FF)

    // Secondary (teal)
    val TealLight = Color(0xFF00897B)
    val TealDark = Color(0xFF4DB6AC)

    // Tertiary (amber accent for favorites/highlights)
    val AmberLight = Color(0xFFB26A00)
    val AmberDark = Color(0xFFFFCC80)

    // Error
    val ErrorLight = Color(0xFFB3261E)
    val ErrorDark = Color(0xFFF2B8B5)

    // Light scheme surfaces ("paper")
    val LightBackground = Color(0xFFFBF8F4)
    val LightSurface = Color(0xFFFFFFFF)
    val LightSurfaceVariant = Color(0xFFE7E0EC)
    val LightOnSurface = Color(0xFF1C1B1F)
    val LightOutline = Color(0xFF79747E)

    // Dark scheme surfaces
    val DarkBackground = Color(0xFF121316)
    val DarkSurface = Color(0xFF1C1D21)
    val DarkSurfaceVariant = Color(0xFF49454F)
    val DarkOnSurface = Color(0xFFE6E1E5)
    val DarkOutline = Color(0xFF938F99)

    val White = Color(0xFFFFFFFF)
    val Black = Color(0xFF000000)
}
