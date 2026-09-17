import 'package:flutter/material.dart';

/// Centralized semantic color tokens for BuildLedger adhering to
/// Construction + Finance + Reliability principles.
class AppColors {
  // Brand / Deep Obsidian Canvas
  static const Color obsidianCanvas = Color(0xFF0B0F17);
  static const Color surfaceObsidian = Color(0xFF131A26);
  static const Color surfaceElevatedObsidian = Color(0xFF182232);
  static const Color surfaceInputObsidian = Color(0xFF151E2B);
  static const Color borderObsidian = Color(0xFF232F3E);
  static const Color borderFocusedObsidian = Color(0xFFF59E0B);

  // Precision Amber Accent (Primary Action)
  static const Color precisionAmber = Color(0xFFF59E0B);
  static const Color onAmber = Color(0xFF0B0F17); // Standardized dark text on amber
  static const Color amberContainer = Color(0x26F59E0B); // 15% opacity

  // Semantic Meaning-Driven Functional Colors
  static const Color successEmerald = Color(0xFF10B981);
  static const Color successContainer = Color(0x2610B981);

  static const Color infoBlue = Color(0xFF38BDF8);
  static const Color infoContainer = Color(0x2638BDF8);

  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorContainer = Color(0x26DC2626);

  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0x26F59E0B);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Aliases for backwards compatibility with existing component references
  static const Color primary = Color(0xFF1E2F40);
  static const Color primaryLight = surfaceElevatedObsidian;
  static const Color primaryDark = obsidianCanvas;
  static const Color accent = precisionAmber;
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);
  static const Color profit = successEmerald;
  static const Color profitLight = successContainer;
  static const Color alert = errorRed;
  static const Color alertLight = errorContainer;
  static const Color warning = warningAmber;
  static const Color warningLight = warningContainer;

  static const Color backgroundDark = obsidianCanvas;
  static const Color surfaceDark = surfaceObsidian;
  static const Color surfaceElevatedDark = surfaceElevatedObsidian;
  static const Color borderDark = borderObsidian;
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;

  // Light Mode Surfaces
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF1F3F5);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
}

/// Custom ThemeExtension providing extended semantic tokens not covered by standard ColorScheme.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color surfaceElevated;
  final Color surfaceInput;
  final Color border;
  final Color borderFocused;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successContainer;
  final Color info;
  final Color infoContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;

  const AppThemeExtension({
    required this.surfaceElevated,
    required this.surfaceInput,
    required this.border,
    required this.borderFocused,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successContainer,
    required this.info,
    required this.infoContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
  });

  static const dark = AppThemeExtension(
    surfaceElevated: AppColors.surfaceElevatedObsidian,
    surfaceInput: AppColors.surfaceInputObsidian,
    border: AppColors.borderObsidian,
    borderFocused: AppColors.borderFocusedObsidian,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    success: AppColors.successEmerald,
    successContainer: AppColors.successContainer,
    info: AppColors.infoBlue,
    infoContainer: AppColors.infoContainer,
    warning: AppColors.warningAmber,
    warningContainer: AppColors.warningContainer,
    error: AppColors.errorRed,
    errorContainer: AppColors.errorContainer,
  );

  static const light = AppThemeExtension(
    surfaceElevated: Color(0xFFF1F3F5),
    surfaceInput: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    borderFocused: AppColors.precisionAmber,
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    success: Color(0xFF059669),
    successContainer: Color(0x1A059669),
    info: Color(0xFF0284C7),
    infoContainer: Color(0x1A0284C7),
    warning: Color(0xFFD97706),
    warningContainer: Color(0x1AD97706),
    error: Color(0xFFDC2626),
    errorContainer: Color(0x1ADC2626),
  );

  @override
  AppThemeExtension copyWith({
    Color? surfaceElevated,
    Color? surfaceInput,
    Color? border,
    Color? borderFocused,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? successContainer,
    Color? info,
    Color? infoContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
  }) {
    return AppThemeExtension(
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceInput: surfaceInput ?? this.surfaceInput,
      border: border ?? this.border,
      borderFocused: borderFocused ?? this.borderFocused,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceInput: Color.lerp(surfaceInput, other.surfaceInput, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
    );
  }
}

/// Convenience extension on BuildContext for quick access to semantic tokens
extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  AppThemeExtension get appTokens =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.dark;
}
