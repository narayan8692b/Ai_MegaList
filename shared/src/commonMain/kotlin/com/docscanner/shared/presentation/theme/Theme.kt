package com.docscanner.shared.presentation.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = DocColors.IndigoLight,
    onPrimary = DocColors.White,
    secondary = DocColors.TealLight,
    onSecondary = DocColors.White,
    tertiary = DocColors.AmberLight,
    onTertiary = DocColors.White,
    error = DocColors.ErrorLight,
    onError = DocColors.White,
    background = DocColors.LightBackground,
    onBackground = DocColors.LightOnSurface,
    surface = DocColors.LightSurface,
    onSurface = DocColors.LightOnSurface,
    surfaceVariant = DocColors.LightSurfaceVariant,
    outline = DocColors.LightOutline,
)

private val DarkColors = darkColorScheme(
    primary = DocColors.IndigoDark,
    onPrimary = DocColors.Black,
    secondary = DocColors.TealDark,
    onSecondary = DocColors.Black,
    tertiary = DocColors.AmberDark,
    onTertiary = DocColors.Black,
    error = DocColors.ErrorDark,
    onError = DocColors.Black,
    background = DocColors.DarkBackground,
    onBackground = DocColors.DarkOnSurface,
    surface = DocColors.DarkSurface,
    onSurface = DocColors.DarkOnSurface,
    surfaceVariant = DocColors.DarkSurfaceVariant,
    outline = DocColors.DarkOutline,
)

/** Material 3 typography. Uses platform default font family with tuned sizes/weights. */
private val DocTypography = Typography()

/**
 * Root Material 3 theme for the app.
 *
 * @param darkTheme whether to use the dark color scheme. Defaults to the system setting;
 *   callers resolve [com.docscanner.shared.domain.model.ThemeMode] to a concrete boolean.
 */
@Composable
fun DocScannerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = DocTypography,
        content = content,
    )
}
