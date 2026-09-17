import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typographic scale for BuildLedger's ShadCN design system.
/// Uses Inter with tight tracking and clear hierarchy for high-density fintech.
class ShadTypography {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle large;
  final TextStyle lead;
  final TextStyle p;
  final TextStyle small;
  final TextStyle muted;
  final TextStyle mono;

  const ShadTypography({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.large,
    required this.lead,
    required this.p,
    required this.small,
    required this.muted,
    required this.mono,
  });

  factory ShadTypography.generate({required Color foreground, required Color mutedColor}) {
    return ShadTypography(
      h1: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: foreground,
      ),
      h2: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: foreground,
      ),
      h3: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: foreground,
      ),
      h4: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      large: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      lead: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      p: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      small: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      muted: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mutedColor,
      ),
      mono: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: foreground,
      ),
    );
  }
}
