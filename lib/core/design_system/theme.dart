import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';

/// Centralized theme generator that maps ShadCN design tokens to Flutter's ThemeData.
abstract final class ShadTheme {
  static ThemeData get darkTheme => _buildTheme(ShadTokens.dark);
  static ThemeData get lightTheme => _buildTheme(ShadTokens.light);

  static ThemeData _buildTheme(ShadTokens tokens) {
    final baseTextTheme = tokens.isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

    final colorScheme = ColorScheme(
      brightness: tokens.brightness,
      primary: tokens.primary,
      onPrimary: tokens.primaryForeground,
      secondary: tokens.secondary,
      onSecondary: tokens.secondaryForeground,
      error: tokens.destructive,
      onError: tokens.destructiveForeground,
      surface: tokens.card,
      onSurface: tokens.cardForeground,
      outline: tokens.border,
      outlineVariant: tokens.muted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      extensions: [tokens],
      textTheme: textTheme.copyWith(
        displayLarge: tokens.typography.h1,
        headlineMedium: tokens.typography.h2,
        titleLarge: tokens.typography.h3,
        titleMedium: tokens.typography.h4,
        bodyLarge: tokens.typography.p,
        bodyMedium: tokens.typography.small,
        bodySmall: tokens.typography.muted,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.foreground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: tokens.typography.h3,
        iconTheme: IconThemeData(color: tokens.foreground, size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ShadRadii.roundedLg,
          side: BorderSide(color: tokens.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.input,
        contentPadding: ShadSpacing.inputPadding,
        hintStyle: tokens.typography.muted,
        labelStyle: tokens.typography.small.copyWith(color: tokens.mutedForeground),
        border: OutlineInputBorder(
          borderRadius: ShadRadii.roundedMd,
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ShadRadii.roundedMd,
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ShadRadii.roundedMd,
          borderSide: BorderSide(color: tokens.ring, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ShadRadii.roundedMd,
          borderSide: BorderSide(color: tokens.destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: ShadRadii.roundedMd,
          borderSide: BorderSide(color: tokens.destructive, width: 1.5),
        ),
      ),
    );
  }
}
