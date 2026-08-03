import 'package:flutter/material.dart';

/// Central design tokens for the Glances client.
///
/// AMOLED-first palette: pure-black backgrounds (so OLED pixels are off),
/// a cyan/teal accent, and muted text tones. Mirrors `AppTheme.amoled`.
abstract final class AppColors {
  // Backgrounds (pure black so OLED pixels are off).
  static const Color scaffoldBackground = Color(0xFF000000);
  static const Color surface = Color(0xFF000000);
  static const Color surfaceAlt = Color(0xFF11151A);
  static const Color border = Color(0xFF21262D);

  // Accent.
  static const Color accent = Color(0xFF2DD4BF);

  // Text.
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);

  // Status.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}
