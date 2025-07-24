import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

import 'package:maxchomp/core/models/settings_model.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/providers/settings_export_provider.dart';
import 'package:maxchomp/core/services/settings_export_service.dart';

import '../test_helpers/test_helpers.dart';
import '../core/services/settings_export_service_test.mocks.dart' as SettingsMocks;

/// Integration tests for export/import functionality with profile data integrity
/// Following Context7 Flutter testing patterns and Riverpod isolation best practices
void main() {
  group('Export/Import Integration Tests', () {
    late ProviderContainer container;
    late SettingsMocks.MockSharedPreferences mockPrefs;
    late Directory tempDir;
    
    setUp(() async {
      // Create fresh container for each test using Context7 pattern
      mockPrefs = SettingsMocks.MockSharedPreferences();
      tempDir = await Directory.systemTemp.createTemp('maxchomp_test_');
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Basic Export/Import Data Integrity', () {
      test('export and import maintains complete settings integrity', () async {
        // Arrange: Set up initial settings
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        // Create test settings with specific values
        const originalSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'test-voice-id',
          defaultSpeechRate: 1.75,
          defaultVolume: 0.85,
          defaultPitch: 1.3,
          enableBackgroundPlayback: false,
          enableHapticFeedback: true,
          enableVoicePreview: false,
        );
        
        await settingsNotifier.importSettings(originalSettings);
        
        // Act: Export settings
        final exportService = container.read(settingsExportServiceProvider);
        final exportResult = await exportService.exportSettings();
        
        expect(exportResult.isSuccess, isTrue);
        
        // Reset settings to different values
        await settingsNotifier.resetToDefaults();
        final resetSettings = container.read(settingsProvider);
        expect(resetSettings, isNot(equals(originalSettings)));
        
        // Import back from export data
        final importResult = await exportService.importSettings(
          exportResult.data!.toJsonString(),
        );
        
        // Assert: Verify complete data integrity
        expect(importResult.isSuccess, isTrue);
        final restoredSettings = container.read(settingsProvider);
        expect(restoredSettings, equals(originalSettings));
        
        // Verify all specific fields
        expect(restoredSettings.isDarkMode, equals(originalSettings.isDarkMode));
        expect(restoredSettings.defaultVoiceId, equals(originalSettings.defaultVoiceId));
        expect(restoredSettings.defaultSpeechRate, equals(originalSettings.defaultSpeechRate));
        expect(restoredSettings.defaultVolume, equals(originalSettings.defaultVolume));
        expect(restoredSettings.defaultPitch, equals(originalSettings.defaultPitch));
        expect(restoredSettings.enableBackgroundPlayback, equals(originalSettings.enableBackgroundPlayback));
        expect(restoredSettings.enableHapticFeedback, equals(originalSettings.enableHapticFeedback));
        expect(restoredSettings.enableVoicePreview, equals(originalSettings.enableVoicePreview));
      });

      test('export and import with file operations maintains data integrity', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        const testSettings = SettingsModel(
          isDarkMode: false,
          defaultVoiceId: 'file-test-voice',
          defaultSpeechRate: 0.5,
          defaultVolume: 1.0,
          defaultPitch: 2.0,
          enableBackgroundPlayback: true,
          enableHapticFeedback: false,
          enableVoicePreview: true,
        );
        
        await settingsNotifier.importSettings(testSettings);
        
        // Act: Export to file
        final exportFilePath = '${tempDir.path}/test_export.json';
        final exportService = container.read(settingsExportServiceProvider);
        final exportResult = await exportService.exportSettingsToFile(exportFilePath);
        
        expect(exportResult.isSuccess, isTrue);
        expect(await File(exportFilePath).exists(), isTrue);
        
        // Reset settings
        await settingsNotifier.resetToDefaults();
        
        // Import from file
        final importResult = await exportService.importSettingsFromFile(exportFilePath);
        
        // Assert
        expect(importResult.isSuccess, isTrue);
        final restoredSettings = container.read(settingsProvider);
        expect(restoredSettings, equals(testSettings));
      });

      test('multiple export/import cycles maintain data integrity', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        final exportService = container.read(settingsExportServiceProvider);
        
        // Test multiple different configurations
        final testConfigurations = [
          const SettingsModel(
            isDarkMode: true,
            defaultVoiceId: 'config1-voice',
            defaultSpeechRate: 0.75,
            defaultVolume: 0.5,
            defaultPitch: 1.25,
          ),
          const SettingsModel(
            isDarkMode: false,
            defaultVoiceId: 'config2-voice',
            defaultSpeechRate: 1.5,
            defaultVolume: 0.9,
            defaultPitch: 0.8,
          ),
          const SettingsModel(
            isDarkMode: true,
            defaultVoiceId: 'config3-voice',
            defaultSpeechRate: 2.0,
            defaultVolume: 0.3,
            defaultPitch: 1.8,
          ),
        ];
        
        // Act & Assert: Test each configuration through export/import cycle
        for (int i = 0; i < testConfigurations.length; i++) {
          final config = testConfigurations[i];
          
          // Set the configuration
          await settingsNotifier.importSettings(config);
          
          // Export and verify
          final exportResult = await exportService.exportSettings();
          expect(exportResult.isSuccess, isTrue, reason: 'Export failed for config $i');
          
          // Reset to defaults
          await settingsNotifier.resetToDefaults();
          
          // Import back and verify
          final importResult = await exportService.importSettings(
            exportResult.data!.toJsonString(),
          );
          expect(importResult.isSuccess, isTrue, reason: 'Import failed for config $i');
          
          final restoredSettings = container.read(settingsProvider);
          expect(restoredSettings, equals(config), reason: 'Config $i not restored correctly');
        }
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles corrupted export data gracefully', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        final originalSettings = container.read(settingsProvider);
        
        const corruptedJson = '''
        {
          "appName": "MaxChomp",
          "version": "1.0.0",
          "exportDate": "2025-01-15T10:00:00.000Z",
          "settings": {
            "isDarkMode": "not_a_boolean",
            "defaultSpeechRate": "invalid_number",
            "defaultVolume": null
          }
        }
        ''';
        
        // Act
        final exportService = container.read(settingsExportServiceProvider);
        final importResult = await exportService.importSettings(corruptedJson);
        
        // Assert: Should fail gracefully without crashing
        expect(importResult.isSuccess, isFalse);
        expect(importResult.error, isNotNull);
        
        // Verify original settings are preserved
        final settingsAfterFailedImport = container.read(settingsProvider);
        expect(settingsAfterFailedImport, equals(originalSettings));
      });

      test('handles file permission errors during export', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        // Act: Try to export to invalid path
        final exportService = container.read(settingsExportServiceProvider);
        final result = await exportService.exportSettingsToFile('/invalid/permission/path.json');
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Failed to write file'));
      });

      test('validates settings boundaries and provides warnings', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        // Create export data with invalid values
        const invalidJson = '''
        {
          "appName": "MaxChomp",
          "version": "1.0.0",
          "exportDate": "2025-01-15T10:00:00.000Z",
          "settings": {
            "isDarkMode": false,
            "defaultVoiceId": "valid-voice",
            "defaultSpeechRate": 5.0,
            "defaultVolume": 2.0,
            "defaultPitch": 0.1,
            "enableBackgroundPlayback": true,
            "enableHapticFeedback": false,
            "enableVoicePreview": true
          }
        }
        ''';
        
        // Act
        final exportService = container.read(settingsExportServiceProvider);
        final importResult = await exportService.importSettings(invalidJson);
        
        // Assert: Should succeed but with warnings
        expect(importResult.isSuccess, isTrue);
        expect(importResult.warnings, isNotEmpty);
        expect(importResult.warnings!.length, equals(3)); // 3 invalid values
        
        // Verify values are clamped to valid ranges
        final restoredSettings = container.read(settingsProvider);
        expect(restoredSettings.defaultSpeechRate, lessThanOrEqualTo(2.0));
        expect(restoredSettings.defaultVolume, lessThanOrEqualTo(1.0));
        expect(restoredSettings.defaultPitch, greaterThanOrEqualTo(0.5));
      });

      test('handles empty export file gracefully', () async {
        // Arrange
        final emptyFilePath = '${tempDir.path}/empty_file.json';
        await File(emptyFilePath).writeAsString('');
        
        // Act
        final exportService = container.read(settingsExportServiceProvider);
        final result = await exportService.importSettingsFromFile(emptyFilePath);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid JSON'));
      });

      test('handles large export/import operations efficiently', () async {
        // Arrange: Create settings that would result in larger JSON
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        // Create settings with long voice ID to test larger payloads
        final largeSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'very-long-voice-id-' * 100, // Large voice ID
          defaultSpeechRate: 1.5,
          defaultVolume: 0.75,
          defaultPitch: 1.25,
          enableBackgroundPlayback: true,
          enableHapticFeedback: true,
          enableVoicePreview: true,
        );
        
        await settingsNotifier.importSettings(largeSettings);
        
        // Act: Export and import with timing
        final exportService = container.read(settingsExportServiceProvider);
        
        final exportStopwatch = Stopwatch()..start();
        final exportResult = await exportService.exportSettings();
        exportStopwatch.stop();
        
        expect(exportResult.isSuccess, isTrue);
        expect(exportStopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
        
        await settingsNotifier.resetToDefaults();
        
        final importStopwatch = Stopwatch()..start();
        final importResult = await exportService.importSettings(
          exportResult.data!.toJsonString(),
        );
        importStopwatch.stop();
        
        // Assert
        expect(importResult.isSuccess, isTrue);
        expect(importStopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
        
        final restoredSettings = container.read(settingsProvider);
        expect(restoredSettings, equals(largeSettings));
      });

      test('handles malformed JSON with missing required fields', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        final originalSettings = container.read(settingsProvider);
        
        // JSON missing required fields
        const malformedJson = '''
        {
          "appName": "MaxChomp",
          "version": "1.0.0"
        }
        ''';
        
        // Act
        final exportService = container.read(settingsExportServiceProvider);
        final importResult = await exportService.importSettings(malformedJson);
        
        // Assert
        expect(importResult.isSuccess, isFalse);
        expect(importResult.error, isNotNull);
        
        // Verify settings remain unchanged
        final settingsAfterFailedImport = container.read(settingsProvider);
        expect(settingsAfterFailedImport, equals(originalSettings));
      });

      test('validates app name compatibility', () async {
        // Arrange
        const wrongAppJson = '''
        {
          "appName": "DifferentApp",
          "version": "1.0.0",
          "exportDate": "2025-01-15T10:00:00.000Z",
          "settings": {
            "isDarkMode": false,
            "defaultVoiceId": "test-voice",
            "defaultSpeechRate": 1.0,
            "defaultVolume": 1.0,
            "defaultPitch": 1.0,
            "enableBackgroundPlayback": true,
            "enableHapticFeedback": true,
            "enableVoicePreview": true
          }
        }
        ''';
        
        // Act
        final exportService = container.read(settingsExportServiceProvider);
        final importResult = await exportService.importSettings(wrongAppJson);
        
        // Assert
        expect(importResult.isSuccess, isFalse);
        expect(importResult.error, contains('Invalid export file'));
        expect(importResult.error, contains('DifferentApp'));
      });
    });

    group('Concurrent Operations', () {
      test('handles concurrent export operations safely', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        final exportService = container.read(settingsExportServiceProvider);
        
        // Act: Perform multiple exports concurrently
        final futures = List.generate(5, (index) => exportService.exportSettings());
        final results = await Future.wait(futures);
        
        // Assert: All should succeed
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.data, isNotNull);
          expect(result.data!.appName, equals('MaxChomp'));
        }
      });

      test('handles concurrent import operations safely', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        final exportService = container.read(settingsExportServiceProvider);
        
        // Create valid export data
        final exportResult = await exportService.exportSettings();
        expect(exportResult.isSuccess, isTrue);
        final jsonString = exportResult.data!.toJsonString();
        
        // Act: Perform multiple imports concurrently
        final futures = List.generate(3, (index) => 
          exportService.importSettings(jsonString)
        );
        
        final results = await Future.wait(futures);
        
        // Assert: All should succeed (last one wins)
        for (final result in results) {
          expect(result.isSuccess, isTrue);
        }
        
        // Verify final state is consistent
        final finalSettings = container.read(settingsProvider);
        expect(finalSettings, isNotNull);
      });

      test('export/import operations are atomic', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        const testSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'atomic-test-voice',
          defaultSpeechRate: 1.25,
          defaultVolume: 0.75,
          defaultPitch: 1.1,
        );
        
        await settingsNotifier.importSettings(testSettings);
        
        final exportService = container.read(settingsExportServiceProvider);
        
        // Act: Concurrent export and import operations
        final exportFuture = exportService.exportSettings();
        final importFuture = exportService.importSettings(
          (await exportService.exportSettings()).data!.toJsonString(),
        );
        
        final results = await Future.wait([exportFuture, importFuture]);
        
        // Assert: Both operations should succeed
        expect(results[0].isSuccess, isTrue); // export
        expect(results[1].isSuccess, isTrue); // import
        
        // Verify final state is consistent
        final finalSettings = container.read(settingsProvider);
        expect(finalSettings, equals(testSettings));
      });
    });

    group('Metadata Validation', () {
      test('preserves export metadata correctly', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        final exportService = container.read(settingsExportServiceProvider);
        
        // Act
        final beforeExport = DateTime.now();
        final exportResult = await exportService.exportSettings();
        final afterExport = DateTime.now();
        
        // Assert
        expect(exportResult.isSuccess, isTrue);
        final exportData = exportResult.data!;
        
        expect(exportData.appName, equals('MaxChomp'));
        expect(exportData.version, equals('1.0.0'));
        expect(exportData.exportDate.isAfter(beforeExport.subtract(const Duration(seconds: 1))), isTrue);
        expect(exportData.exportDate.isBefore(afterExport.add(const Duration(seconds: 1))), isTrue);
        
        // Verify JSON serialization/deserialization preserves metadata
        final jsonString = exportData.toJsonString();
        final reconstructed = SettingsExportData.fromJsonString(jsonString);
        
        expect(reconstructed.appName, equals(exportData.appName));
        expect(reconstructed.version, equals(exportData.version));
        expect(reconstructed.exportDate, equals(exportData.exportDate));
        expect(reconstructed.settings, equals(exportData.settings));
      });

      test('handles version compatibility warnings', () async {
        // Arrange
        when(mockPrefs.getString('settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final settingsNotifier = container.read(settingsProvider.notifier);
        await settingsNotifier.initialize();
        
        const versionMismatchJson = '''
        {
          "appName": "MaxChomp",
          "version": "0.5.0",
          "exportDate": "2025-01-15T10:00:00.000Z",
          "settings": {
            "isDarkMode": true,
            "defaultVoiceId": "version-test-voice",
            "defaultSpeechRate": 1.0,
            "defaultVolume": 1.0,
            "defaultPitch": 1.0,
            "enableBackgroundPlayback": true,
            "enableHapticFeedback": true,
            "enableVoicePreview": true
          }
        }
        ''';
        
        // Act
        final exportService = container.read(settingsExportServiceProvider);
        final importResult = await exportService.importSettings(versionMismatchJson);
        
        // Assert
        expect(importResult.isSuccess, isTrue);
        expect(importResult.warnings, isNotEmpty);
        expect(importResult.warnings!.first, contains('Version mismatch'));
        expect(importResult.warnings!.first, contains('0.5.0'));
        expect(importResult.warnings!.first, contains('1.0.0'));
        
        // Verify settings were still imported
        final restoredSettings = container.read(settingsProvider);
        expect(restoredSettings.defaultVoiceId, equals('version-test-voice'));
      });
    });
  });
}