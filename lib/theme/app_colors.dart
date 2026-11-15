import 'package:flutter/material.dart';

/// Total-black (AMOLED) monochrome palette.
///
/// Color is reserved strictly for health status: [ok], [caution]/[warning],
/// [critical]. Everything else (surfaces, text, controls, chart context) is
/// black, white or grey.
class AppColors {
  // Surfaces — true black background, near-black cards.
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF0B0B0B);
  static const surfaceHigh = Color(0xFF161616);
  static const border = Color(0xFF242424);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8C8C8C);
  static const textDisabled = Color(0xFF4D4D4D);

  // Interactive accent — monochrome, never a status color.
  static const accent = Color(0xFFFFFFFF);
  static const accentDim = Color(0xFF3A3A3A);
  static const onAccent = Color(0xFF000000);

  // Status — the only colors in the app.
  static const ok = Color(0xFFA9DB7A);
  static const caution = Color(0xFFF6CB55);
  static const warning = caution;
  static const critical = Color(0xFFE5646E);
  static const info = Color(0xFFBDBDBD);

  /// Multi-field series (e.g. SYS/DIA) are distinguished by grey shades;
  /// the focused field is zone-colored by status in the chart itself.
  static const metricFields = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFBDBDBD),
    Color(0xFF8C8C8C),
    Color(0xFF5E5E5E),
  ];

  // Category tints — neutral in the monochrome theme.
  static const heartRate = Color(0xFFFFFFFF);
  static const spo2 = Color(0xFFFFFFFF);
  static const respiration = Color(0xFFFFFFFF);
  static const sleep = Color(0xFFBDBDBD);
  static const bodyTemp = Color(0xFFFFFFFF);
  static const radiation = Color(0xFFFFFFFF);
  static const workload = Color(0xFFFFFFFF);
}
