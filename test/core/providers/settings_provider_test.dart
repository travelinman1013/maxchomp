import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/models/settings_model.dart';

import 'settings_provider_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('Settings Provider Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late ProviderContainer container;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('SettingsModel', () {
      test('should create default settings correctly', () {
        // Arrange & Act
        const settings = SettingsModel();
        
        // Assert
        expect(settings.isDarkMode, isFalse);
        expect(settings.defaultVoiceId, isNull);
        expect(settings.defaultSpeechRate, equals(1.0));
        expect(settings.defaultVolume, equals(1.0));
        expect(settings.defaultPitch, equals(1.0));
        expect(settings.enableBackgroundPlayback, isTrue);
        expect(settings.enableHapticFeedback, isTrue);
        expect(settings.enableVoicePreview, isTrue);
        expect(settings.defaultThemeMode, equals(ThemeMode.system));
      });

      test('should handle copyWith correctly with all fields', () {
        // Arrange
        const initialSettings = SettingsModel();
        
        // Act
        final newSettings = initialSettings.copyWith(
          isDarkMode: true,
          defaultVoiceId: 'en-US-voice-1',
          defaultSpeechRate: 1.5,
          defaultVolume: 0.8,
          defaultPitch: 1.2,
          enableBackgroundPlayback: false,
          enableHapticFeedback: false,
          enableVoicePreview: false,
          defaultThemeMode: ThemeMode.dark,
        );
        
        // Assert
        expect(newSettings.isDarkMode, isTrue);
        expect(newSettings.defaultVoiceId, equals('en-US-voice-1'));
        expect(newSettings.defaultSpeechRate, equals(1.5));
        expect(newSettings.defaultVolume, equals(0.8));
        expect(newSettings.defaultPitch, equals(1.2));
        expect(newSettings.enableBackgroundPlayback, isFalse);
        expect(newSettings.enableHapticFeedback, isFalse);
        expect(newSettings.enableVoicePreview, isFalse);
        expect(newSettings.defaultThemeMode, equals(ThemeMode.dark));
      });

      test('should handle JSON serialization correctly', () {
        // Arrange
        const settings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'en-US-voice-1',
          defaultSpeechRate: 1.5,
          defaultVolume: 0.8,
          defaultPitch: 1.2,
          enableBackgroundPlayback: false,
          enableHapticFeedback: false,
          enableVoicePreview: false,
        );
        
        // Act
        final json = settings.toJson();
        final deserializedSettings = SettingsModel.fromJson(json);
        
        // Assert
        expect(deserializedSettings.isDarkMode, equals(settings.isDarkMode));
        expect(deserializedSettings.defaultVoiceId, equals(settings.defaultVoiceId));
        expect(deserializedSettings.defaultSpeechRate, equals(settings.defaultSpeechRate));
        expect(deserializedSettings.defaultVolume, equals(settings.defaultVolume));
        expect(deserializedSettings.defaultPitch, equals(settings.defaultPitch));
        expect(deserializedSettings.enableBackgroundPlayback, equals(settings.enableBackgroundPlayback));
        expect(deserializedSettings.enableHapticFeedback, equals(settings.enableHapticFeedback));
        expect(deserializedSettings.enableVoicePreview, equals(settings.enableVoicePreview));
      });

      test('should handle JSON deserialization with missing fields', () {
        // Arrange
        final partialJson = {
          'isDarkMode': true,
          'defaultSpeechRate': 1.5,
          // Missing other fields
        };
        
        // Act
        final settings = SettingsModel.fromJson(partialJson);
        
        // Assert
        expect(settings.isDarkMode, isTrue);
        expect(settings.defaultSpeechRate, equals(1.5));
        // Should use default values for missing fields
        expect(settings.defaultVoiceId, isNull);
        expect(settings.defaultVolume, equals(1.0));
        expect(settings.enableBackgroundPlayback, isTrue);
      });
    });

    group('SettingsNotifier', () {
      test('should initialize with default settings when no stored settings exist', () async {
        // Arrange - Mock SharedPreferences to return null (no stored settings)
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        // Act
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        final settings = container.read(settingsNotifierProvider);
        
        // Assert
        expect(settings.isDarkMode, isFalse);
        expect(settings.defaultSpeechRate, equals(1.0));
        expect(settings.enableBackgroundPlayback, isTrue);
        verify(mockSharedPreferences.getString('settings')).called(1);
      });

      test('should initialize with stored settings when they exist', () async {
        // Arrange - Mock SharedPreferences to return stored settings
        const storedSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'en-US-voice-1',
          defaultSpeechRate: 1.5,
        );
        
        when(mockSharedPreferences.getString('settings'))
            .thenReturn(storedSettings.toJsonString());
        
        // Act
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        final settings = container.read(settingsNotifierProvider);
        
        // Assert
        expect(settings.isDarkMode, isTrue);
        expect(settings.defaultVoiceId, equals('en-US-voice-1'));
        expect(settings.defaultSpeechRate, equals(1.5));
        verify(mockSharedPreferences.getString('settings')).called(1);
      });

      test('should handle corrupted stored settings gracefully', () async {
        // Arrange - Mock SharedPreferences to return invalid JSON
        when(mockSharedPreferences.getString('settings'))
            .thenReturn('invalid-json-{malformed}');
        
        // Act
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        final settings = container.read(settingsNotifierProvider);
        
        // Assert - Should fall back to default settings
        expect(settings.isDarkMode, isFalse);
        expect(settings.defaultSpeechRate, equals(1.0));
        verify(mockSharedPreferences.getString('settings')).called(1);
      });

      test('should save settings to SharedPreferences when updated', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act - Update theme mode
        await notifier.updateThemeMode(ThemeMode.dark);
        
        // Assert
        verify(mockSharedPreferences.setString('settings', any)).called(1);
        
        final settings = container.read(settingsNotifierProvider);
        expect(settings.defaultThemeMode, equals(ThemeMode.dark));
      });

      test('should update voice settings correctly', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act - Update voice settings with VoiceSettings object
        final voiceSettings = VoiceSettings(
          selectedVoiceId: 'en-US-voice-1',
          speechRate: 1.5,
          volume: 0.8,
          pitch: 1.2,
        );
        await notifier.updateVoiceSettings(voiceSettings);
        
        // Assert
        final settings = container.read(settingsNotifierProvider);
        expect(settings.defaultVoiceId, equals('en-US-voice-1'));
        expect(settings.defaultSpeechRate, equals(1.5));
        expect(settings.defaultVolume, equals(0.8));
        expect(settings.defaultPitch, equals(1.2));
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });

      test('should update playback preferences correctly', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act - Update playback preferences
        await notifier.updatePlaybackPreferences(
          enableBackgroundPlayback: false,
          enableHapticFeedback: false,
          enableVoicePreview: false,
        );
        
        // Assert
        final settings = container.read(settingsNotifierProvider);
        expect(settings.enableBackgroundPlayback, isFalse);
        expect(settings.enableHapticFeedback, isFalse);
        expect(settings.enableVoicePreview, isFalse);
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });

      test('should reset settings to defaults correctly', () async {
        // Arrange - Start with custom settings
        const initialSettings = SettingsModel(
          isDarkMode: true,
          defaultVoiceId: 'custom-voice',
          defaultSpeechRate: 2.0,
        );
        
        when(mockSharedPreferences.getString('settings'))
            .thenReturn(initialSettings.toJsonString());
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize(); // This doesn't save, only loads
        
        // Act - Reset to defaults
        await notifier.resetToDefaults();
        
        // Assert
        final settings = container.read(settingsNotifierProvider);
        expect(settings.isDarkMode, isFalse);
        expect(settings.defaultVoiceId, isNull);
        expect(settings.defaultSpeechRate, equals(1.0));
        
        verify(mockSharedPreferences.setString('settings', any)).called(1); // Only reset saves
      });

      test('should handle SharedPreferences save failure gracefully', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => false);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act & Assert - Should not throw exception
        expect(
          () => notifier.updateThemeMode(ThemeMode.dark),
          returnsNormally,
        );
        
        // State should still be updated locally
        final settings = container.read(settingsNotifierProvider);
        expect(settings.defaultThemeMode, equals(ThemeMode.dark));
      });
    });

    group('Derived Providers', () {
      test('currentThemeModeProvider should return correct theme mode', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act - Set theme mode
        notifier.state = notifier.state.copyWith(defaultThemeMode: ThemeMode.dark);
        
        final themeMode = container.read(currentThemeModeProvider);
        
        // Assert
        expect(themeMode, equals(ThemeMode.dark));
      });

      test('isDarkModeProvider should return correct dark mode state', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act - Set dark mode
        notifier.state = notifier.state.copyWith(isDarkMode: true);
        
        final isDarkMode = container.read(isDarkModeProvider);
        
        // Assert
        expect(isDarkMode, isTrue);
      });

      test('defaultVoiceSettingsProvider should return correct voice settings', () async {
        // Arrange
        when(mockSharedPreferences.getString('settings')).thenReturn(null);
        
        final notifier = container.read(settingsNotifierProvider.notifier);
        await notifier.initialize();
        
        // Act - Set voice settings
        notifier.state = notifier.state.copyWith(
          defaultVoiceId: 'en-US-voice-1',
          defaultSpeechRate: 1.5,
          defaultVolume: 0.8,
          defaultPitch: 1.2,
        );
        
        final voiceSettings = container.read(defaultVoiceSettingsProvider);
        
        // Assert
        expect(voiceSettings.selectedVoiceId, equals('en-US-voice-1'));
        expect(voiceSettings.speechRate, equals(1.5));
        expect(voiceSettings.volume, equals(0.8));
        expect(voiceSettings.pitch, equals(1.2));
      });
    });
  });
}