import 'package:flutter/material.dart';

import 'theme_tokens.dart';

class AppTheme {
  /// Build a [ThemeData] for the given brightness using the provided tokens.
  static ThemeData _build(Brightness brightness, TubeRipTheme tokens) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      extensions: [tokens],
      dialogTheme: DialogThemeData(backgroundColor: tokens.background),
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: tokens.primary,
              secondary: tokens.primaryAlt,
              surface: tokens.surface,
              surfaceContainerHighest: tokens.surfaceAlt,
              onSurface: tokens.textPrimary,
              onPrimary: tokens.background,
              onError: tokens.textPrimary,
            )
          : ColorScheme.light(
              primary: tokens.primary,
              secondary: tokens.primaryAlt,
              surface: tokens.surface,
              surfaceContainerHighest: tokens.surfaceAlt,
              onSurface: tokens.textPrimary,
              onPrimary: tokens.background,
              onError: tokens.textPrimary,
            ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: tokens.textSecondary,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: tokens.textMuted,
          fontSize: 11,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
        titleMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: tokens.textSecondary,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: tokens.primary,
        selectionHandleColor: tokens.primary,
        cursorColor: tokens.primary,
      ),
    );
  }

  static ThemeData get light => _build(Brightness.light, TubeRipTheme.light);

  static ThemeData get dark => _build(Brightness.dark, TubeRipTheme.dark);
}
