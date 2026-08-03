import 'package:flutter/material.dart';

/// Central design tokens for the Glances client.
///
/// Hardcoded AMOLED-black theme: pure-black backgrounds so OLED pixels stay
/// off, cards raised a single step, a cyan/teal accent, and muted text tones.
abstract final class AppColors {
  // Backgrounds — pure AMOLED black.
  static const Color scaffoldBackground = Color(0xFF000000);
  static const Color surface = Color(0xFF000000);
  static const Color surfaceAlt = Color(0xFF0F0F0F);
  static const Color border = Color(0xFF1F1F1F);

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
