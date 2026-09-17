import 'package:flutter/material.dart';

/// Restrained border radius tokens conforming to ShadCN's crisp geometry.
abstract final class ShadRadii {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double full = 9999.0;

  static const BorderRadius roundedNone = BorderRadius.zero;
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}
