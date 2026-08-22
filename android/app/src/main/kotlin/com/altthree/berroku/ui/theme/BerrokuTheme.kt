package com.altthree.berroku.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object BerrokuColors {
    val BerryBlue = Color(0xFF3584E4)
    val BerryBlueDark = Color(0xFF5A9FE8)
    val Navy = Color(0xFF0B1628)
    val NavySurface = Color(0xFF14233A)
    val NavyRaised = Color(0xFF1B2D47)
    val Ink = Color(0xFF172033)
    val Paper = Color(0xFFF6F8FC)
    val PaperSurface = Color(0xFFEDF2F8)
    val Leaf = Color(0xFF7FA54B)
}

private val DarkColors = darkColorScheme(
    primary = BerrokuColors.BerryBlueDark,
    onPrimary = Color(0xFF07111F),
    primaryContainer = Color(0xFF173D6B),
    onPrimaryContainer = Color(0xFFD9E9FB),
    background = BerrokuColors.Navy,
    onBackground = Color(0xFFE8EEF7),
    surface = BerrokuColors.NavySurface,
    onSurface = Color(0xFFE8EEF7),
    surfaceVariant = BerrokuColors.NavyRaised,
    onSurfaceVariant = Color(0xFFB9C8DA),
    outline = Color(0xFF53657C),
    error = Color(0xFFFF72A8),
)

private val LightColors = lightColorScheme(
    primary = BerrokuColors.BerryBlue,
    onPrimary = Color(0xFFF8FBFF),
    primaryContainer = Color(0xFFDCEBFB),
    onPrimaryContainer = Color(0xFF173554),
    background = BerrokuColors.Paper,
    onBackground = BerrokuColors.Ink,
    surface = Color(0xFFFAFCFF),
    onSurface = BerrokuColors.Ink,
    surfaceVariant = BerrokuColors.PaperSurface,
    onSurfaceVariant = Color(0xFF506078),
    outline = Color(0xFF8190A5),
    error = Color(0xFFD32169),
)

private val BerrokuTypography = Typography(
    displayMedium = TextStyle(
        fontFamily = FontFamily.Serif,
        fontWeight = FontWeight.Bold,
        fontSize = 44.sp,
        lineHeight = 50.sp,
        letterSpacing = (-0.6).sp,
    ),
    headlineMedium = TextStyle(
        fontFamily = FontFamily.Serif,
        fontWeight = FontWeight.Bold,
        fontSize = 28.sp,
        lineHeight = 34.sp,
    ),
    titleLarge = TextStyle(
        fontFamily = FontFamily.Serif,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp,
        lineHeight = 28.sp,
    ),
    bodyLarge = TextStyle(fontSize = 17.sp, lineHeight = 26.sp),
    bodyMedium = TextStyle(fontSize = 15.sp, lineHeight = 22.sp),
    labelLarge = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.SemiBold),
)

private val BerrokuShapes = Shapes(
    small = androidx.compose.foundation.shape.RoundedCornerShape(10.dp),
    medium = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
    large = androidx.compose.foundation.shape.RoundedCornerShape(24.dp),
)

@Composable
fun BerrokuTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        typography = BerrokuTypography,
        shapes = BerrokuShapes,
        content = content,
    )
}
