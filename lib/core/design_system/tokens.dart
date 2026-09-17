import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/colors.dart';
import 'package:build_ledger/core/design_system/typography.dart';

/// Semantic token definitions for BuildLedger's ShadCN UI system.
/// Every screen and component queries these tokens rather than raw colors.
@immutable
class ShadTokens extends ThemeExtension<ShadTokens> {
  final Brightness brightness;

  // 22 Core Canonical Semantic Tokens
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color success;
  final Color warning;
  final Color info;

  // Containers and surface elevated
  final Color surfaceElevated;
  final Color successContainer;
  final Color destructiveContainer;
  final Color infoContainer;
  final Color warningContainer;

  // Typography scale attached to tokens
  final ShadTypography typography;

  const ShadTokens({
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.success,
    required this.warning,
    required this.info,
    required this.surfaceElevated,
    required this.successContainer,
    required this.destructiveContainer,
    required this.infoContainer,
    required this.warningContainer,
    required this.typography,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Deep Obsidian Dark Theme Tokens (Primary BuildLedger Identity)
  static final ShadTokens dark = ShadTokens(
    brightness: Brightness.dark,
    background: ShadPalette.obsidianCanvas,
    foreground: ShadPalette.darkForeground,
    card: ShadPalette.obsidianSurface,
    cardForeground: ShadPalette.darkForeground,
    popover: ShadPalette.obsidianSurfaceElevated,
    popoverForeground: ShadPalette.darkForeground,
    primary: ShadPalette.amber,
    primaryForeground: ShadPalette.amberForeground,
    secondary: ShadPalette.obsidianSurfaceElevated,
    secondaryForeground: ShadPalette.darkForeground,
    muted: ShadPalette.obsidianSurfaceElevated,
    mutedForeground: ShadPalette.darkMutedForeground,
    accent: ShadPalette.obsidianSurfaceElevated,
    accentForeground: ShadPalette.amber,
    destructive: ShadPalette.red,
    destructiveForeground: ShadPalette.redForeground,
    border: ShadPalette.obsidianBorder,
    input: ShadPalette.obsidianInput,
    ring: ShadPalette.amber,
    success: ShadPalette.emerald,
    warning: ShadPalette.amber,
    info: ShadPalette.sky,
    surfaceElevated: ShadPalette.obsidianSurfaceElevated,
    successContainer: ShadPalette.emeraldContainer,
    destructiveContainer: ShadPalette.redContainer,
    infoContainer: ShadPalette.skyContainer,
    warningContainer: ShadPalette.amberContainer,
    typography: ShadTypography.generate(
      foreground: ShadPalette.darkForeground,
      mutedColor: ShadPalette.darkMutedForeground,
    ),
  );

  /// Clean Industrial Light Theme Tokens
  static final ShadTokens light = ShadTokens(
    brightness: Brightness.light,
    background: ShadPalette.lightCanvas,
    foreground: ShadPalette.lightForeground,
    card: ShadPalette.lightSurface,
    cardForeground: ShadPalette.lightForeground,
    popover: ShadPalette.lightSurface,
    popoverForeground: ShadPalette.lightForeground,
    primary: ShadPalette.amber,
    primaryForeground: ShadPalette.amberForeground,
    secondary: ShadPalette.lightSurfaceElevated,
    secondaryForeground: ShadPalette.lightForeground,
    muted: ShadPalette.lightSurfaceElevated,
    mutedForeground: ShadPalette.lightMutedForeground,
    accent: ShadPalette.lightSurfaceElevated,
    accentForeground: const Color(0xFFD97706),
    destructive: ShadPalette.red,
    destructiveForeground: ShadPalette.redForeground,
    border: ShadPalette.lightBorder,
    input: ShadPalette.lightInput,
    ring: ShadPalette.amber,
    success: ShadPalette.emerald,
    warning: const Color(0xFFD97706),
    info: const Color(0xFF0284C7),
    surfaceElevated: ShadPalette.lightSurfaceElevated,
    successContainer: ShadPalette.emeraldContainer,
    destructiveContainer: ShadPalette.redContainer,
    infoContainer: ShadPalette.skyContainer,
    warningContainer: ShadPalette.amberContainer,
    typography: ShadTypography.generate(
      foreground: ShadPalette.lightForeground,
      mutedColor: ShadPalette.lightMutedForeground,
    ),
  );

  @override
  ThemeExtension<ShadTokens> copyWith({
    Brightness? brightness,
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? success,
    Color? warning,
    Color? info,
    Color? surfaceElevated,
    Color? successContainer,
    Color? destructiveContainer,
    Color? infoContainer,
    Color? warningContainer,
    ShadTypography? typography,
  }) {
    return ShadTokens(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground: destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      successContainer: successContainer ?? this.successContainer,
      destructiveContainer: destructiveContainer ?? this.destructiveContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      typography: typography ?? this.typography,
    );
  }

  @override
  ThemeExtension<ShadTokens> lerp(covariant ThemeExtension<ShadTokens>? other, double t) {
    if (other is! ShadTokens) return this;
    return ShadTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      popoverForeground: Color.lerp(popoverForeground, other.popoverForeground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground: Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      destructiveContainer: Color.lerp(destructiveContainer, other.destructiveContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      typography: t < 0.5 ? typography : other.typography,
    );
  }
}

/// Seamless context extension for accessing ShadCN tokens anywhere.
extension ShadContext on BuildContext {
  ShadTokens get shad {
    final tokens = Theme.of(this).extension<ShadTokens>();
    if (tokens != null) return tokens;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? ShadTokens.dark : ShadTokens.light;
  }
}
