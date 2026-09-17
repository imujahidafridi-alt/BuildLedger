import 'package:flutter/material.dart';

/// Canonical component dimension standards for BuildLedger.
///
/// Guarantees that all interactive elements meet or exceed accessibility
/// touch targets (minimum 48x48dp) while presenting tight visual bounds.
abstract final class ShadDimensions {
  // Accessibility
  static const double minTouchTarget = 48.0;
  static const BoxConstraints minTouchConstraints = BoxConstraints(
    minWidth: minTouchTarget,
    minHeight: minTouchTarget,
  );

  // Buttons
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 50.0;

  // Inputs
  static const double inputHeight = 44.0;
  static const double inputHeightLarge = 52.0;

  // Icons
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;

  // Dialog & Sheet
  static const double maxDialogWidth = 480.0;
  static const double maxSheetWidth = 600.0;
}
