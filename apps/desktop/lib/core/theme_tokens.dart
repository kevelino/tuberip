import 'package:flutter/material.dart';

import 'constants.dart';
import 'download_status.dart';

/// Centralized design tokens for TubeRip. Cyan is the single accent color
/// (see [TubeRipTheme.primary]); status colors are green/amber/red. The
/// `*Text` variants are darker, readable shades of the same hues used for
/// text/icons on light backgrounds where the bright base color would fail
/// WCAG AA contrast.
class TubeRipTheme extends ThemeExtension<TubeRipTheme> {
  const TubeRipTheme({
    required this.primary,
    required this.primaryAlt,
    required this.primaryText,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successText,
    required this.warning,
    required this.warningText,
    required this.error,
    required this.errorText,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
  });

  final Color primary;
  final Color primaryAlt;
  final Color primaryText;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successText;
  final Color warning;
  final Color warningText;
  final Color error;
  final Color errorText;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;

  static const TubeRipTheme dark = TubeRipTheme(
    primary: AppColors.cyan,
    primaryAlt: AppColors.cyanAlt,
    primaryText: AppColors.cyan,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    success: AppColors.green,
    successText: AppColors.green,
    warning: AppColors.yellow,
    warningText: AppColors.yellow,
    error: AppColors.red,
    errorText: AppColors.red,
    radiusSm: 8.0,
    radiusMd: 10.0,
    radiusLg: 12.0,
    radiusXl: 20.0,
    spaceXs: 4.0,
    spaceSm: 8.0,
    spaceMd: 12.0,
    spaceLg: 16.0,
    spaceXl: 20.0,
  );

  static const TubeRipTheme light = TubeRipTheme(
    primary: AppColors.cyan,
    primaryAlt: AppColors.cyanAlt,
    // Darker, AA-compliant shades for text/icons on light surfaces.
    primaryText: Color(0xFF0E7490),
    background: Color(0xFFECECEE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF4F4F5),
    border: Color(0xFFD4D4D8),
    textPrimary: Color(0xFF18181B),
    textSecondary: Color(0xFF3F3F46),
    textMuted: Color(0xFF52525B),
    success: AppColors.green,
    successText: Color(0xFF15803D),
    warning: AppColors.yellow,
    warningText: Color(0xFF92600A),
    error: AppColors.red,
    errorText: Color(0xFFB91C1C),
    radiusSm: 8.0,
    radiusMd: 10.0,
    radiusLg: 12.0,
    radiusXl: 20.0,
    spaceXs: 4.0,
    spaceSm: 8.0,
    spaceMd: 12.0,
    spaceLg: 16.0,
    spaceXl: 20.0,
  );

  /// Status color for text/icons, using the AA-compliant shade on light
  /// themes.
  Color statusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return successText;
      case DownloadStatus.queued:
      case DownloadStatus.paused:
        return warningText;
      case DownloadStatus.error:
      case DownloadStatus.cancelled:
        return errorText;
      case DownloadStatus.downloading:
        return primaryText;
    }
  }

  static TubeRipTheme of(BuildContext context) {
    return Theme.of(context).extension<TubeRipTheme>() ?? dark;
  }

  @override
  ThemeExtension<TubeRipTheme> copyWith({
    Color? primary,
    Color? primaryAlt,
    Color? primaryText,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? successText,
    Color? warning,
    Color? warningText,
    Color? error,
    Color? errorText,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
  }) {
    return TubeRipTheme(
      primary: primary ?? this.primary,
      primaryAlt: primaryAlt ?? this.primaryAlt,
      primaryText: primaryText ?? this.primaryText,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      error: error ?? this.error,
      errorText: errorText ?? this.errorText,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
    );
  }

  @override
  ThemeExtension<TubeRipTheme> lerp(
    covariant ThemeExtension<TubeRipTheme>? other,
    double t,
  ) {
    if (other is! TubeRipTheme) return this;
    return TubeRipTheme(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryAlt: Color.lerp(primaryAlt, other.primaryAlt, t) ?? primaryAlt,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t) ?? surfaceAlt,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      success: Color.lerp(success, other.success, t) ?? success,
      successText: Color.lerp(successText, other.successText, t) ?? successText,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningText: Color.lerp(warningText, other.warningText, t) ?? warningText,
      error: Color.lerp(error, other.error, t) ?? error,
      errorText: Color.lerp(errorText, other.errorText, t) ?? errorText,
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusLg: radiusLg,
      radiusXl: radiusXl,
      spaceXs: spaceXs,
      spaceSm: spaceSm,
      spaceMd: spaceMd,
      spaceLg: spaceLg,
      spaceXl: spaceXl,
    );
  }
}
