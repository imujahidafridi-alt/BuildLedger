import 'package:flutter/material.dart';

/// Raw palette tokens for BuildLedger's industrial ShadCN design system.
///
/// Feature screens and UI components MUST NOT reference these directly.
/// Instead, access semantic tokens via [ShadTokens] or `context.shad`.
abstract final class ShadPalette {
  // Deep Obsidian Dark Palette
  static const Color obsidianCanvas = Color(0xFF0B0F17);
  static const Color obsidianSurface = Color(0xFF131A26);
  static const Color obsidianSurfaceElevated = Color(0xFF182232);
  static const Color obsidianInput = Color(0xFF111827);
  static const Color obsidianInputSecondary = Color(0xFF182232);
  static const Color obsidianBorder = Color(0xFF1F2937);
  static const Color obsidianBorderMuted = Color(0xFF243042);

  // Precision Amber Accent (Primary Brand Action)
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberForeground = Color(0xFF0B0F17); // Strict dark-on-amber
  static const Color amberContainer = Color(0x26F59E0B); // 15% opacity container

  // Dark Neutrals & Typography
  static const Color darkForeground = Color(0xFFF9FAFB);
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkSubtle = Color(0xFF64748B);

  // Functional Semantic Accents (Consistent across themes)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldContainer = Color(0x2610B981);
  static const Color emeraldForeground = Color(0xFFFFFFFF);

  static const Color red = Color(0xFFEF4444);
  static const Color redContainer = Color(0x26EF4444);
  static const Color redForeground = Color(0xFFFFFFFF);

  static const Color sky = Color(0xFF38BDF8);
  static const Color skyContainer = Color(0x2638BDF8);
  static const Color skyForeground = Color(0xFF0B0F17);

  // Light Mode Palette
  static const Color lightCanvas = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInput = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF0F172A);
  static const Color lightMutedForeground = Color(0xFF64748B);
}
