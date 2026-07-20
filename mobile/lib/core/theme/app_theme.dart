import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color and typography tokens from docs/09_Design_System.md §4–5, §7.
/// Primary/Secondary/Tertiary hues are an explicit placeholder in that
/// document pending brand identity work — structure and roles stay the
/// same when the hue is swapped.
class AppTheme {
  AppTheme._();

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5B5BD6),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE4E3FB),
    onPrimaryContainer: Color(0xFF14134A),
    secondary: Color(0xFF5B5D6E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE1E2EC),
    onSecondaryContainer: Color(0xFF0B0B0B),
    tertiary: Color(0xFF8B5A00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDDB0),
    onTertiaryContainer: Color(0xFF0B0B0B),
    error: Color(0xFFD03B3B),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFCFCFB),
    onSurface: Color(0xFF0B0B0B),
    onSurfaceVariant: Color(0xFF52514E),
    surfaceContainerLowest: Color(0xFFF9F9F7),
    surfaceContainerLow: Color(0xFFF5F4F1),
    surfaceContainer: Color(0xFFEFEEEA),
    surfaceContainerHigh: Color(0xFFE9E7E2),
    surfaceContainerHighest: Color(0xFFE2E0DA),
    outline: Color(0x1A0B0B0B),
    outlineVariant: Color(0xFFE1E0D9),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFC4C2FF),
    onPrimary: Color(0xFF24237A),
    primaryContainer: Color(0xFF3B3A91),
    onPrimaryContainer: Color(0xFFE4E3FB),
    secondary: Color(0xFFC4C6D9),
    onSecondary: Color(0xFF0B0B0B),
    secondaryContainer: Color(0xFF434659),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFFFFB74D),
    onTertiary: Color(0xFF0B0B0B),
    tertiaryContainer: Color(0xFF6B4400),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xFFD03B3B),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFF1A1A19),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFC3C2B7),
    surfaceContainerLowest: Color(0xFF0D0D0D),
    surfaceContainerLow: Color(0xFF201F1E),
    surfaceContainer: Color(0xFF262524),
    surfaceContainerHigh: Color(0xFF2C2B29),
    surfaceContainerHighest: Color(0xFF333230),
    outline: Color(0x1AFFFFFF),
    outlineVariant: Color(0xFF2C2C2A),
  );

  /// Shape scale, docs/09_Design_System.md §7 (radius-*).
  static const radiusXs = 8.0;
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
  static const radiusFull = 9999.0;

  static ThemeData get light => _buildTheme(_lightColorScheme);
  static ThemeData get dark => _buildTheme(_darkColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
      ),
    );
  }
}
