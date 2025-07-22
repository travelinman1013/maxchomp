import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings_model.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Settings storage key
const String _settingsKey = 'settings';

/// State notifier for managing application settings
class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SharedPreferences _sharedPreferences;

  SettingsNotifier(this._sharedPreferences) : super(const SettingsModel());

  /// Initialize settings by loading from SharedPreferences
  Future<void> initialize() async {
    try {
      final settingsJson = _sharedPreferences.getString(_settingsKey);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        state = SettingsModel.fromJsonString(settingsJson);
      }
    } catch (e) {
      // If there's an error loading settings, keep default values
      debugPrint('Error loading settings: $e');
    }
  }

  /// Save current settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final success = await _sharedPreferences.setString(_settingsKey, state.toJsonString());
      if (!success) {
        debugPrint('Failed to save settings to SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(
      defaultThemeMode: themeMode,
      isDarkMode: themeMode == ThemeMode.dark,
    );
    await _saveSettings();
  }

  /// Update voice settings
  Future<void> updateVoiceSettings({
    String? voiceId,
    double? speechRate,
    double? volume,
    double? pitch,
  }) async {
    state = state.copyWith(
      defaultVoiceId: voiceId,
      defaultSpeechRate: speechRate,
      defaultVolume: volume,
      defaultPitch: pitch,
    );
    await _saveSettings();
  }

  /// Update playback preferences
  Future<void> updatePlaybackPreferences({
    bool? enableBackgroundPlayback,
    bool? enableHapticFeedback,
    bool? enableVoicePreview,
  }) async {
    state = state.copyWith(
      enableBackgroundPlayback: enableBackgroundPlayback,
      enableHapticFeedback: enableHapticFeedback,
      enableVoicePreview: enableVoicePreview,
    );
    await _saveSettings();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    state = const SettingsModel();
    await _saveSettings();
  }

  /// Update specific speech rate
  Future<void> updateSpeechRate(double speechRate) async {
    state = state.copyWith(defaultSpeechRate: speechRate);
    await _saveSettings();
  }

  /// Update specific volume
  Future<void> updateVolume(double volume) async {
    state = state.copyWith(defaultVolume: volume);
    await _saveSettings();
  }

  /// Update specific pitch
  Future<void> updatePitch(double pitch) async {
    state = state.copyWith(defaultPitch: pitch);
    await _saveSettings();
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    final newThemeMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await updateThemeMode(newThemeMode);
  }

  /// Toggle background playback
  Future<void> toggleBackgroundPlayback() async {
    await updatePlaybackPreferences(
      enableBackgroundPlayback: !state.enableBackgroundPlayback,
    );
  }

  /// Toggle haptic feedback
  Future<void> toggleHapticFeedback() async {
    await updatePlaybackPreferences(
      enableHapticFeedback: !state.enableHapticFeedback,
    );
  }

  /// Toggle voice preview
  Future<void> toggleVoicePreview() async {
    await updatePlaybackPreferences(
      enableVoicePreview: !state.enableVoicePreview,
    );
  }
}

/// Provider for settings state management
final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final sharedPreferences = ref.read(sharedPreferencesProvider);
  return SettingsNotifier(sharedPreferences);
});

/// Provider to get the current theme mode
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.defaultThemeMode;
});

/// Provider to get the dark mode state
final isDarkModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.isDarkMode;
});

/// Provider to get default voice settings
final defaultVoiceSettingsProvider = Provider<VoiceSettings>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return VoiceSettings(
    voiceId: settings.defaultVoiceId,
    speechRate: settings.defaultSpeechRate,
    volume: settings.defaultVolume,
    pitch: settings.defaultPitch,
  );
});

/// Provider to check if background playback is enabled
final isBackgroundPlaybackEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.enableBackgroundPlayback;
});

/// Provider to check if haptic feedback is enabled
final isHapticFeedbackEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.enableHapticFeedback;
});

/// Provider to check if voice preview is enabled
final isVoicePreviewEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.enableVoicePreview;
});