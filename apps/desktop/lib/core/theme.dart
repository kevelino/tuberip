import 'package:flutter/material.dart';

/// Brand tokens — primary cyan from `assets/icons/tuberip.svg` (`#0fe5f4`).
abstract final class AppColors {
  static const Color cyan = Color(0xFF0FE5F4);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFEF4444);

  static const Color gray100 = Color(0xFFF4F4F5);
  static const Color gray200 = Color(0xFFE4E4E7);
  static const Color gray300 = Color(0xFFD4D4D8);
  static const Color gray400 = Color(0xFFA1A1AA);
  static const Color gray500 = Color(0xFF71717A);
  static const Color gray600 = Color(0xFF52525B);
  static const Color gray700 = Color(0xFF3F3F46);
  static const Color gray800 = Color(0xFF27272A);
  static const Color gray900 = Color(0xFF18181B);
  static const Color gray950 = Color(0xFF0F0F11);
  static const Color gray1000 = Color(0xFF0C0C0E);
}

class TubeRipTheme extends ThemeExtension<TubeRipTheme> {
  const TubeRipTheme({
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.surfaceMuted,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusPill,
  });

  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color surfaceMuted;
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusPill;

  static const dark = TubeRipTheme(
    accent: AppColors.cyan,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    surfaceMuted: AppColors.gray900,
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 12,
    spacingLg: 16,
    spacingXl: 24,
    radiusSm: 5,
    radiusMd: 8,
    radiusLg: 12,
    radiusPill: 9999,
  );

  static const light = TubeRipTheme(
    accent: AppColors.cyan,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    surfaceMuted: AppColors.gray100,
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 12,
    spacingLg: 16,
    spacingXl: 24,
    radiusSm: 5,
    radiusMd: 8,
    radiusLg: 12,
    radiusPill: 9999,
  );

  @override
  TubeRipTheme copyWith({
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? surfaceMuted,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusPill,
  }) {
    return TubeRipTheme(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusPill: radiusPill ?? this.radiusPill,
    );
  }

  @override
  TubeRipTheme lerp(ThemeExtension<TubeRipTheme>? other, double t) {
    if (other is! TubeRipTheme) return this;
    return TubeRipTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      spacingXs: spacingXs,
      spacingSm: spacingSm,
      spacingMd: spacingMd,
      spacingLg: spacingLg,
      spacingXl: spacingXl,
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusLg: radiusLg,
      radiusPill: radiusPill,
    );
  }
}

ThemeData buildTubeRipTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final tokens = isDark ? TubeRipTheme.dark : TubeRipTheme.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.cyan,
    brightness: brightness,
    primary: AppColors.cyan,
    onPrimary: AppColors.gray1000,
    error: AppColors.error,
    surface: isDark ? AppColors.gray1000 : Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? AppColors.gray1000 : AppColors.gray100,
    extensions: [tokens],
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.gray900 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: isDark ? AppColors.gray700 : AppColors.gray300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.gray1000,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(side: BorderSide.none),
      ).copyWith(
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: const ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: const ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: const ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: const ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
  );
}
