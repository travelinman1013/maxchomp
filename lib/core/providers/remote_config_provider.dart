import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for FirebaseRemoteConfig instance
final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

/// Model for remote configuration values
class RemoteConfigData {
  final bool enableVoicePreview;
  final bool enableGoogleTTS;
  final bool enablePlatformTTS;
  final double defaultSpeechRate;
  final double minSpeechRate;
  final double maxSpeechRate;
  final bool enableBetaFeatures;
  final bool enableAnalytics;
  final String supportEmail;
  final int maxDocumentSizeMB;
  final bool enableOfflineMode;
  final bool enableDarkModeOverride;
  final String appVersionMinimum;

  const RemoteConfigData({
    required this.enableVoicePreview,
    required this.enableGoogleTTS,
    required this.enablePlatformTTS,
    required this.defaultSpeechRate,
    required this.minSpeechRate,
    required this.maxSpeechRate,
    required this.enableBetaFeatures,
    required this.enableAnalytics,
    required this.supportEmail,
    required this.maxDocumentSizeMB,
    required this.enableOfflineMode,
    required this.enableDarkModeOverride,
    required this.appVersionMinimum,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RemoteConfigData &&
        other.enableVoicePreview == enableVoicePreview &&
        other.enableGoogleTTS == enableGoogleTTS &&
        other.enablePlatformTTS == enablePlatformTTS &&
        other.defaultSpeechRate == defaultSpeechRate &&
        other.minSpeechRate == minSpeechRate &&
        other.maxSpeechRate == maxSpeechRate &&
        other.enableBetaFeatures == enableBetaFeatures &&
        other.enableAnalytics == enableAnalytics &&
        other.supportEmail == supportEmail &&
        other.maxDocumentSizeMB == maxDocumentSizeMB &&
        other.enableOfflineMode == enableOfflineMode &&
        other.enableDarkModeOverride == enableDarkModeOverride &&
        other.appVersionMinimum == appVersionMinimum;
  }

  @override
  int get hashCode {
    return Object.hash(
      enableVoicePreview,
      enableGoogleTTS,
      enablePlatformTTS,
      defaultSpeechRate,
      minSpeechRate,
      maxSpeechRate,
      enableBetaFeatures,
      enableAnalytics,
      supportEmail,
      maxDocumentSizeMB,
      enableOfflineMode,
      enableDarkModeOverride,
      appVersionMinimum,
    );
  }

  @override
  String toString() {
    return 'RemoteConfigData('
        'enableVoicePreview: $enableVoicePreview, '
        'enableGoogleTTS: $enableGoogleTTS, '
        'enablePlatformTTS: $enablePlatformTTS, '
        'defaultSpeechRate: $defaultSpeechRate, '
        'minSpeechRate: $minSpeechRate, '
        'maxSpeechRate: $maxSpeechRate, '
        'enableBetaFeatures: $enableBetaFeatures, '
        'enableAnalytics: $enableAnalytics, '
        'supportEmail: $supportEmail, '
        'maxDocumentSizeMB: $maxDocumentSizeMB, '
        'enableOfflineMode: $enableOfflineMode, '
        'enableDarkModeOverride: $enableDarkModeOverride, '
        'appVersionMinimum: $appVersionMinimum)';
  }
}

/// State notifier for managing remote configuration
class RemoteConfigNotifier extends StateNotifier<AsyncValue<RemoteConfigData>> {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigNotifier(this._remoteConfig) : super(const AsyncValue.loading()) {
    _initialize();
  }

  /// Initialize remote config with default values and fetch latest
  Future<void> _initialize() async {
    try {
      // Set configuration settings for development
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode 
            ? const Duration(minutes: 1)  // Fast refresh in debug
            : const Duration(hours: 1),   // Production interval
      ));

      // Set in-app default parameter values
      await _remoteConfig.setDefaults(const {
        'enable_voice_preview': true,
        'enable_google_tts': true,
        'enable_platform_tts': true,
        'default_speech_rate': 1.0,
        'min_speech_rate': 0.25,
        'max_speech_rate': 2.0,
        'enable_beta_features': false,
        'enable_analytics': true,
        'support_email': 'support@maxchomp.app',
        'max_document_size_mb': 50,
        'enable_offline_mode': true,
        'enable_dark_mode_override': false,
        'app_version_minimum': '1.0.0',
      });

      // Fetch and activate remote values
      await _remoteConfig.fetchAndActivate();

      // Listen for real-time config updates
      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.activate();
        _updateState();
      });

      _updateState();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Remote config initialization error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update state with current remote config values
  void _updateState() {
    try {
      final configData = RemoteConfigData(
        enableVoicePreview: _remoteConfig.getBool('enable_voice_preview'),
        enableGoogleTTS: _remoteConfig.getBool('enable_google_tts'),
        enablePlatformTTS: _remoteConfig.getBool('enable_platform_tts'),
        defaultSpeechRate: _remoteConfig.getDouble('default_speech_rate'),
        minSpeechRate: _remoteConfig.getDouble('min_speech_rate'),
        maxSpeechRate: _remoteConfig.getDouble('max_speech_rate'),
        enableBetaFeatures: _remoteConfig.getBool('enable_beta_features'),
        enableAnalytics: _remoteConfig.getBool('enable_analytics'),
        supportEmail: _remoteConfig.getString('support_email'),
        maxDocumentSizeMB: _remoteConfig.getInt('max_document_size_mb'),
        enableOfflineMode: _remoteConfig.getBool('enable_offline_mode'),
        enableDarkModeOverride: _remoteConfig.getBool('enable_dark_mode_override'),
        appVersionMinimum: _remoteConfig.getString('app_version_minimum'),
      );

      state = AsyncValue.data(configData);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error updating remote config state: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Manually fetch latest configuration
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      await _remoteConfig.fetchAndActivate();
      _updateState();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error refreshing remote config: $e');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Get a specific boolean parameter with fallback
  bool getBool(String key, {bool fallback = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting boolean parameter $key: $e');
      }
      return fallback;
    }
  }

  /// Get a specific string parameter with fallback
  String getString(String key, {String fallback = ''}) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting string parameter $key: $e');
      }
      return fallback;
    }
  }

  /// Get a specific double parameter with fallback
  double getDouble(String key, {double fallback = 0.0}) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting double parameter $key: $e');
      }
      return fallback;
    }
  }

  /// Get a specific int parameter with fallback
  int getInt(String key, {int fallback = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting integer parameter $key: $e');
      }
      return fallback;
    }
  }
}

/// Provider for remote configuration state management
final remoteConfigProvider = StateNotifierProvider<RemoteConfigNotifier, AsyncValue<RemoteConfigData>>((ref) {
  final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
  return RemoteConfigNotifier(remoteConfig);
});

/// Provider to check if voice preview is enabled via remote config
final isVoicePreviewEnabledRemoteProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.enableVoicePreview,
    loading: () => true, // Default to enabled while loading
    error: (_, __) => true, // Default to enabled on error
  );
});

/// Provider to check if Google TTS is enabled via remote config
final isGoogleTTSEnabledProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.enableGoogleTTS,
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Provider to check if platform TTS is enabled via remote config
final isPlatformTTSEnabledProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.enablePlatformTTS,
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Provider for default speech rate from remote config
final remoteSpeechRateProvider = Provider<double>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.defaultSpeechRate,
    loading: () => 1.0,
    error: (_, __) => 1.0,
  );
});

/// Provider for speech rate limits from remote config
final speechRateLimitsProvider = Provider<({double min, double max})>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => (min: config.minSpeechRate, max: config.maxSpeechRate),
    loading: () => (min: 0.25, max: 2.0),
    error: (_, __) => (min: 0.25, max: 2.0),
  );
});

/// Provider to check if beta features are enabled
final isBetaFeaturesEnabledProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.enableBetaFeatures,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to check if analytics are enabled via remote config
final isAnalyticsEnabledRemoteProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.enableAnalytics,
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Provider for support email from remote config
final supportEmailProvider = Provider<String>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.supportEmail,
    loading: () => 'support@maxchomp.app',
    error: (_, __) => 'support@maxchomp.app',
  );
});

/// Provider for maximum document size from remote config
final maxDocumentSizeProvider = Provider<int>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.maxDocumentSizeMB,
    loading: () => 50,
    error: (_, __) => 50,
  );
});

/// Provider to check if offline mode is enabled
final isOfflineModeEnabledProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(remoteConfigProvider);
  return configAsync.when(
    data: (config) => config.enableOfflineMode,
    loading: () => true,
    error: (_, __) => true,
  );
});