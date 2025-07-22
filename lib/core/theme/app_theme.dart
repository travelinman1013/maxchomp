import 'package:flutter/material.dart';

class AppTheme {
  // MaxChomp brand color
  static const Color _primarySeedColor = Color(0xFF6750A4);

  static ThemeData lightTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: Brightness.light,
    );

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }

  static ThemeData darkTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: Brightness.dark,
    );

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }

  // Spacing constants
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
}