import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxchomp/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme should return Material 3 theme with correct brightness', () {
      final theme = AppTheme.lightTheme();
      
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('darkTheme should return Material 3 theme with correct brightness', () {
      final theme = AppTheme.darkTheme();
      
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('themes should use MaxChomp brand color scheme', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();
      
      // Both themes should have a color scheme generated from the seed color
      expect(lightTheme.colorScheme.primary, isNotNull);
      expect(darkTheme.colorScheme.primary, isNotNull);
      
      // The themes should have different primary colors due to brightness
      expect(lightTheme.colorScheme.primary, isNot(equals(darkTheme.colorScheme.primary)));
    });

    test('spacing constants should be properly defined', () {
      expect(AppTheme.spaceXS, 4.0);
      expect(AppTheme.spaceSM, 8.0);
      expect(AppTheme.spaceMD, 16.0);
      expect(AppTheme.spaceLG, 24.0);
      expect(AppTheme.spaceXL, 32.0);
    });
  });
}