import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

/// Result wrapper for service operations
class ServiceResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final List<String>? warnings;

  const ServiceResult.success(this.data, {this.warnings})
      : isSuccess = true,
        error = null;

  const ServiceResult.failure(this.error)
      : isSuccess = false,
        data = null,
        warnings = null;

  const ServiceResult.warning(this.data, this.warnings)
      : isSuccess = true,
        error = null;
}

/// Export data model containing settings and metadata
class SettingsExportData {
  final String appName;
  final String version;
  final DateTime exportDate;
  final SettingsModel settings;

  const SettingsExportData({
    required this.appName,
    required this.version,
    required this.exportDate,
    required this.settings,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'version': version,
      'exportDate': exportDate.toIso8601String(),
      'settings': settings.toJson(),
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON map
  factory SettingsExportData.fromJson(Map<String, dynamic> json) {
    return SettingsExportData(
      appName: json['appName'] as String,
      version: json['version'] as String,
      exportDate: DateTime.parse(json['exportDate'] as String),
      settings: SettingsModel.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  /// Create from JSON string
  factory SettingsExportData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SettingsExportData.fromJson(json);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SettingsExportData &&
        other.appName == appName &&
        other.version == version &&
        other.exportDate == exportDate &&
        other.settings == settings;
  }

  @override
  int get hashCode {
    return Object.hash(appName, version, exportDate, settings);
  }
}

/// Service for exporting and importing settings
class SettingsExportService {
  static const String _appName = 'MaxChomp';
  static const String _currentVersion = '1.0.0';
  
  // Settings validation ranges
  static const double _minSpeechRate = 0.25;
  static const double _maxSpeechRate = 2.0;
  static const double _minVolume = 0.0;
  static const double _maxVolume = 1.0;
  static const double _minPitch = 0.5;
  static const double _maxPitch = 2.0;

  final ProviderContainer _container;

  SettingsExportService(this._container);

  /// Export current settings to SettingsExportData
  Future<ServiceResult<SettingsExportData>> exportSettings() async {
    try {
      // Get current settings from the provider
      final currentSettings = _container.read(settingsProvider);
      
      final exportData = SettingsExportData(
        appName: _appName,
        version: _currentVersion,
        exportDate: DateTime.now(),
        settings: currentSettings,
      );

      return ServiceResult.success(exportData);
    } catch (e) {
      debugPrint('Error exporting settings: $e');
      return ServiceResult.failure('Failed to export settings: ${e.toString()}');
    }
  }

  /// Export settings to file
  Future<ServiceResult<String>> exportSettingsToFile(String filePath) async {
    try {
      final exportResult = await exportSettings();
      if (!exportResult.isSuccess) {
        return ServiceResult.failure(exportResult.error!);
      }

      final file = File(filePath);
      await file.writeAsString(exportResult.data!.toJsonString());

      return ServiceResult.success(filePath);
    } catch (e) {
      debugPrint('Error writing settings file: $e');
      return ServiceResult.failure('Failed to write file: ${e.toString()}');
    }
  }

  /// Import settings from JSON string
  Future<ServiceResult<SettingsModel>> importSettings(String jsonString) async {
    try {
      final exportData = SettingsExportData.fromJsonString(jsonString);
      
      // Validate app name
      if (exportData.appName != _appName) {
        return ServiceResult.failure(
          'Invalid export file: Expected $_appName, got ${exportData.appName}'
        );
      }

      // Check version compatibility
      final warnings = <String>[];
      if (exportData.version != _currentVersion) {
        warnings.add(
          'Version mismatch: Settings exported from version ${exportData.version}, '
          'current version is $_currentVersion. Some settings may not be compatible.'
        );
      }

      // Validate and sanitize settings
      final sanitizedSettings = _validateAndSanitizeSettings(exportData.settings);
      if (sanitizedSettings.warnings.isNotEmpty) {
        warnings.addAll(sanitizedSettings.warnings);
      }

      // Import the settings using the provider's import method
      await _container.read(settingsProvider.notifier).importSettings(sanitizedSettings.settings);

      if (warnings.isNotEmpty) {
        return ServiceResult.warning(sanitizedSettings.settings, warnings);
      }

      return ServiceResult.success(sanitizedSettings.settings);
    } on FormatException catch (e) {
      debugPrint('Invalid JSON format: $e');
      return ServiceResult.failure('Invalid JSON format: ${e.toString()}');
    } catch (e) {
      debugPrint('Error importing settings: $e');
      if (e.toString().contains('type') || e.toString().contains('null')) {
        return ServiceResult.failure('Invalid export data: Missing required fields');
      }
      return ServiceResult.failure('Failed to import settings: ${e.toString()}');
    }
  }

  /// Import settings from file
  Future<ServiceResult<SettingsModel>> importSettingsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return ServiceResult.failure('File not found: $filePath');
      }

      final jsonString = await file.readAsString();
      return await importSettings(jsonString);
    } catch (e) {
      debugPrint('Error reading settings file: $e');
      return ServiceResult.failure('Failed to read file: ${e.toString()}');
    }
  }

  /// Validate and sanitize settings values
  _ValidationResult _validateAndSanitizeSettings(SettingsModel settings) {
    final warnings = <String>[];
    
    // Clamp speech rate
    double speechRate = settings.defaultSpeechRate;
    if (speechRate < _minSpeechRate) {
      speechRate = _minSpeechRate;
      warnings.add('Speech rate was below minimum (${settings.defaultSpeechRate}), set to $_minSpeechRate');
    } else if (speechRate > _maxSpeechRate) {
      speechRate = _maxSpeechRate;
      warnings.add('Speech rate was above maximum (${settings.defaultSpeechRate}), set to $_maxSpeechRate');
    }

    // Clamp volume
    double volume = settings.defaultVolume;
    if (volume < _minVolume) {
      volume = _minVolume;
      warnings.add('Volume was below minimum (${settings.defaultVolume}), set to $_minVolume');
    } else if (volume > _maxVolume) {
      volume = _maxVolume;
      warnings.add('Volume was above maximum (${settings.defaultVolume}), set to $_maxVolume');
    }

    // Clamp pitch
    double pitch = settings.defaultPitch;
    if (pitch < _minPitch) {
      pitch = _minPitch;
      warnings.add('Pitch was below minimum (${settings.defaultPitch}), set to $_minPitch');
    } else if (pitch > _maxPitch) {
      pitch = _maxPitch;
      warnings.add('Pitch was above maximum (${settings.defaultPitch}), set to $_maxPitch');
    }

    final sanitizedSettings = settings.copyWith(
      defaultSpeechRate: speechRate,
      defaultVolume: volume,
      defaultPitch: pitch,
    );

    return _ValidationResult(sanitizedSettings, warnings);
  }
}

/// Internal class for validation results
class _ValidationResult {
  final SettingsModel settings;
  final List<String> warnings;

  _ValidationResult(this.settings, this.warnings);
}