import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents the application settings and user preferences
class SettingsModel {
  /// Whether dark mode is enabled
  final bool isDarkMode;
  
  /// Default TTS voice identifier
  final String? defaultVoiceId;
  
  /// Default speech rate for TTS (0.25 - 2.0)
  final double defaultSpeechRate;
  
  /// Default volume for TTS (0.0 - 1.0)
  final double defaultVolume;
  
  /// Default pitch for TTS (0.5 - 2.0)
  final double defaultPitch;
  
  /// Whether background playback is enabled
  final bool enableBackgroundPlayback;
  
  /// Whether haptic feedback is enabled
  final bool enableHapticFeedback;
  
  /// Whether voice preview is enabled in voice selection
  final bool enableVoicePreview;
  
  /// Default theme mode (system, light, dark)
  final ThemeMode defaultThemeMode;

  /// Creates a new SettingsModel with default values
  const SettingsModel({
    this.isDarkMode = false,
    this.defaultVoiceId,
    this.defaultSpeechRate = 1.0,
    this.defaultVolume = 1.0,
    this.defaultPitch = 1.0,
    this.enableBackgroundPlayback = true,
    this.enableHapticFeedback = true,
    this.enableVoicePreview = true,
    this.defaultThemeMode = ThemeMode.system,
  });

  /// Creates a copy of this SettingsModel with optionally updated fields
  SettingsModel copyWith({
    bool? isDarkMode,
    String? defaultVoiceId,
    double? defaultSpeechRate,
    double? defaultVolume,
    double? defaultPitch,
    bool? enableBackgroundPlayback,
    bool? enableHapticFeedback,
    bool? enableVoicePreview,
    ThemeMode? defaultThemeMode,
  }) {
    return SettingsModel(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultVoiceId: defaultVoiceId ?? this.defaultVoiceId,
      defaultSpeechRate: defaultSpeechRate ?? this.defaultSpeechRate,
      defaultVolume: defaultVolume ?? this.defaultVolume,
      defaultPitch: defaultPitch ?? this.defaultPitch,
      enableBackgroundPlayback: enableBackgroundPlayback ?? this.enableBackgroundPlayback,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableVoicePreview: enableVoicePreview ?? this.enableVoicePreview,
      defaultThemeMode: defaultThemeMode ?? this.defaultThemeMode,
    );
  }

  /// Converts this settings model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'defaultVoiceId': defaultVoiceId,
      'defaultSpeechRate': defaultSpeechRate,
      'defaultVolume': defaultVolume,
      'defaultPitch': defaultPitch,
      'enableBackgroundPlayback': enableBackgroundPlayback,
      'enableHapticFeedback': enableHapticFeedback,
      'enableVoicePreview': enableVoicePreview,
      'defaultThemeMode': defaultThemeMode.name,
    };
  }

  /// Creates a SettingsModel from a JSON map
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      defaultVoiceId: json['defaultVoiceId'] as String?,
      defaultSpeechRate: (json['defaultSpeechRate'] as num?)?.toDouble() ?? 1.0,
      defaultVolume: (json['defaultVolume'] as num?)?.toDouble() ?? 1.0,
      defaultPitch: (json['defaultPitch'] as num?)?.toDouble() ?? 1.0,
      enableBackgroundPlayback: json['enableBackgroundPlayback'] as bool? ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
      enableVoicePreview: json['enableVoicePreview'] as bool? ?? true,
      defaultThemeMode: _parseThemeMode(json['defaultThemeMode'] as String?),
    );
  }

  /// Converts this settings model to a JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Creates a SettingsModel from a JSON string
  factory SettingsModel.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SettingsModel.fromJson(json);
  }

  /// Parses a string to ThemeMode, defaults to ThemeMode.system
  static ThemeMode _parseThemeMode(String? themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SettingsModel &&
        other.isDarkMode == isDarkMode &&
        other.defaultVoiceId == defaultVoiceId &&
        other.defaultSpeechRate == defaultSpeechRate &&
        other.defaultVolume == defaultVolume &&
        other.defaultPitch == defaultPitch &&
        other.enableBackgroundPlayback == enableBackgroundPlayback &&
        other.enableHapticFeedback == enableHapticFeedback &&
        other.enableVoicePreview == enableVoicePreview &&
        other.defaultThemeMode == defaultThemeMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      isDarkMode,
      defaultVoiceId,
      defaultSpeechRate,
      defaultVolume,
      defaultPitch,
      enableBackgroundPlayback,
      enableHapticFeedback,
      enableVoicePreview,
      defaultThemeMode,
    );
  }

  @override
  String toString() {
    return 'SettingsModel('
        'isDarkMode: $isDarkMode, '
        'defaultVoiceId: $defaultVoiceId, '
        'defaultSpeechRate: $defaultSpeechRate, '
        'defaultVolume: $defaultVolume, '
        'defaultPitch: $defaultPitch, '
        'enableBackgroundPlayback: $enableBackgroundPlayback, '
        'enableHapticFeedback: $enableHapticFeedback, '
        'enableVoicePreview: $enableVoicePreview, '
        'defaultThemeMode: $defaultThemeMode)';
  }
}

/// Helper class for voice settings
class VoiceSettings {
  final String? voiceId;
  final double speechRate;
  final double volume;
  final double pitch;

  const VoiceSettings({
    this.voiceId,
    required this.speechRate,
    required this.volume,
    required this.pitch,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VoiceSettings &&
        other.voiceId == voiceId &&
        other.speechRate == speechRate &&
        other.volume == volume &&
        other.pitch == pitch;
  }

  @override
  int get hashCode {
    return Object.hash(voiceId, speechRate, volume, pitch);
  }

  @override
  String toString() {
    return 'VoiceSettings(voiceId: $voiceId, speechRate: $speechRate, volume: $volume, pitch: $pitch)';
  }
}