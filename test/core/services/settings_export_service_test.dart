import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/core/models/settings_model.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/services/settings_export_service.dart';

import 'settings_export_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('SettingsExportService Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late ProviderContainer container;
    late SettingsExportService exportService;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
      );
      
      exportService = SettingsExportService(container);
    });

    tearDown(() {
      container.dispose();
    });

    group('Export Settings', () {
      test('should export current settings to JSON string', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        // Update settings to specific values
        final testSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'en-US-voice-1',
          defaultSpeechRate: 1.5,
          defaultVolume: 0.8,
          defaultPitch: 1.2,
          enableBackgroundPlayback: false,
          enableHapticFeedback: false,
          enableVoicePreview: true,
        );
        
        notifier.state = testSettings;
        
        // Act
        final exportResult = await exportService.exportSettings();
        
        // Assert
        expect(exportResult.isSuccess, isTrue);
        
        final exportedData = exportResult.data!;
        expect(exportedData.appName, equals('MaxChomp'));
        expect(exportedData.version, equals('1.0.0'));
        expect(exportedData.exportDate, isNotNull);
        expect(exportedData.settings, equals(testSettings));
        
        // Verify JSON serialization works
        final jsonString = exportedData.toJsonString();
        expect(jsonString, isNotEmpty);
        
        final parsedData = SettingsExportData.fromJsonString(jsonString);
        expect(parsedData.settings, equals(testSettings));
      });

      test('should include metadata in export', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        // Act
        final result = await exportService.exportSettings();
        
        // Assert
        expect(result.isSuccess, isTrue);
        
        final exportedData = result.data!;
        expect(exportedData.appName, equals('MaxChomp'));
        expect(exportedData.version, isNotEmpty);
        expect(exportedData.exportDate, isA<DateTime>());
        expect(exportedData.exportDate.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
        expect(exportedData.exportDate.isAfter(DateTime.now().subtract(Duration(seconds: 5))), isTrue);
      });
    });

    group('Import Settings', () {
      test('should import valid settings JSON string', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        final importSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'imported-voice',
          defaultSpeechRate: 2.0,
          defaultVolume: 0.5,
          defaultPitch: 1.5,
          enableBackgroundPlayback: false,
          enableHapticFeedback: true,
          enableVoicePreview: false,
        );
        
        final exportData = SettingsExportData(
          appName: 'MaxChomp',
          version: '1.0.0',
          exportDate: DateTime.now(),
          settings: importSettings,
        );
        
        final jsonString = exportData.toJsonString();
        
        // Act
        final result = await exportService.importSettings(jsonString);
        
        // Assert
        expect(result.isSuccess, isTrue);
        
        final currentSettings = container.read(settingsProvider);
        expect(currentSettings, equals(importSettings));
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });

      test('should validate app name during import', () async {
        // Arrange
        final invalidExportData = SettingsExportData(
          appName: 'DifferentApp', // Wrong app name
          version: '1.0.0',
          exportDate: DateTime.now(),
          settings: SettingsModel(),
        );
        
        final jsonString = invalidExportData.toJsonString();
        
        // Act
        final result = await exportService.importSettings(jsonString);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid export file'));
        expect(result.error, contains('DifferentApp'));
      });

      test('should handle malformed JSON gracefully', () async {
        // Arrange
        const malformedJson = '{"invalid": "json", "missing": fields}';
        
        // Act
        final result = await exportService.importSettings(malformedJson);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid JSON'));
      });

      test('should handle missing required fields', () async {
        // Arrange
        final incompleteJson = jsonEncode({
          'appName': 'MaxChomp',
          'version': '1.0.0',
          // Missing exportDate and settings
        });
        
        // Act
        final result = await exportService.importSettings(incompleteJson);
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid export data'));
      });

      test('should warn about version mismatch but still import', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        final exportData = SettingsExportData(
          appName: 'MaxChomp',
          version: '0.9.0', // Different version
          exportDate: DateTime.now(),
          settings: SettingsModel(isDarkMode: true),
        );
        
        final jsonString = exportData.toJsonString();
        
        // Act
        final result = await exportService.importSettings(jsonString);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.warnings!.first.toLowerCase(), contains('version mismatch'));
        
        final currentSettings = container.read(settingsProvider);
        expect(currentSettings.isDarkMode, isTrue);
      });
    });

    group('File Operations', () {
      test('should export settings to file', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        // Create a temporary file path
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_export.json');
        
        // Clean up any existing file
        if (await testFile.exists()) {
          await testFile.delete();
        }
        
        // Act
        final result = await exportService.exportSettingsToFile(testFile.path);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(await testFile.exists(), isTrue);
        
        final fileContent = await testFile.readAsString();
        expect(fileContent, isNotEmpty);
        
        // Verify file contains valid export data
        final importedData = SettingsExportData.fromJsonString(fileContent);
        expect(importedData.appName, equals('MaxChomp'));
        
        // Clean up
        await testFile.delete();
      });

      test('should import settings from file', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        // Create test file with export data
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_import.json');
        
        final exportData = SettingsExportData(
          appName: 'MaxChomp',
          version: '1.0.0',
          exportDate: DateTime.now(),
          settings: SettingsModel(
            isDarkMode: true,
            defaultSpeechRate: 1.8,
          ),
        );
        
        await testFile.writeAsString(exportData.toJsonString());
        
        // Act
        final result = await exportService.importSettingsFromFile(testFile.path);
        
        // Assert
        expect(result.isSuccess, isTrue);
        
        final currentSettings = container.read(settingsProvider);
        expect(currentSettings.isDarkMode, isTrue);
        expect(currentSettings.defaultSpeechRate, equals(1.8));
        
        // Clean up
        await testFile.delete();
      });

      test('should handle file not found error', () async {
        // Act
        final result = await exportService.importSettingsFromFile('/nonexistent/path/file.json');
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('File not found'));
      });

      test('should handle file permission errors', () async {
        // Act - Try to write to invalid directory
        final result = await exportService.exportSettingsToFile('/invalid/directory/file.json');
        
        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Failed to write file'));
      });
    });

    group('Settings Validation', () {
      test('should validate settings boundaries during import', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsProvider.notifier);
        await notifier.initialize();
        
        // Create settings with invalid values
        final exportData = SettingsExportData(
          appName: 'MaxChomp',
          version: '1.0.0',
          exportDate: DateTime.now(),
          settings: SettingsModel(
            defaultSpeechRate: 5.0, // Invalid: above max 2.0
            defaultVolume: 2.0,     // Invalid: above max 1.0
            defaultPitch: 0.1,      // Invalid: below min 0.5
          ),
        );
        
        final jsonString = exportData.toJsonString();
        
        // Act
        final result = await exportService.importSettings(jsonString);
        
        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.warnings, isNotEmpty);
        
        final currentSettings = container.read(settingsProvider);
        // Values should be clamped to valid ranges
        expect(currentSettings.defaultSpeechRate, lessThanOrEqualTo(2.0));
        expect(currentSettings.defaultVolume, lessThanOrEqualTo(1.0));
        expect(currentSettings.defaultPitch, greaterThanOrEqualTo(0.5));
      });
    });
  });
}