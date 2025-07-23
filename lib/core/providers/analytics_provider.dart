import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for FirebaseAnalytics instance
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Analytics event types for MaxChomp
enum AnalyticsEvent {
  // PDF Management Events
  pdfImportStarted,
  pdfImportCompleted,
  pdfImportFailed,
  pdfOpened,
  pdfDeleted,
  
  // TTS & Audio Events
  ttsPlaybackStarted,
  ttsPlaybackPaused,
  ttsPlaybackResumed,
  ttsPlaybackStopped,
  ttsPlaybackCompleted,
  ttsSpeedChanged,
  ttsVoiceChanged,
  
  // Voice Selection Events
  voiceSelectionOpened,
  voicePreviewPlayed,
  voiceSelected,
  
  // Settings Events
  settingsOpened,
  themeChanged,
  backgroundPlaybackToggled,
  hapticFeedbackToggled,
  voicePreviewToggled,
  
  // User Profile Events
  userProfileLoaded,
  userProfileCreated,
  userProfileUpdated,
  userProfileDeleted,
  userProfileActivated,
  userProfileDuplicated,
  userProfileExported,
  userProfileImported,
  userProfileReset,
  userProfileError,
  
  // User Engagement Events
  sessionStarted,
  sessionEnded,
  featureDiscovered,
  helpOpened,
  feedbackSubmitted,
  
  // Performance Events
  appLaunched,
  appBackgrounded,
  appForegrounded,
  crashOccurred,
}

/// Analytics service for tracking user interactions and app performance
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  /// Initialize analytics with user properties
  Future<void> initialize() async {
    try {
      // Set default event parameters
      await _analytics.setDefaultEventParameters({
        'app_version': '1.0.0', // Should be dynamic in production
        'platform': defaultTargetPlatform.name,
      });

      if (kDebugMode) {
        debugPrint('Analytics initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing analytics: $e');
      }
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    bool? isDarkMode,
    String? preferredVoice,
    double? defaultSpeechRate,
    bool? backgroundPlaybackEnabled,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }

      if (isDarkMode != null) {
        await _analytics.setUserProperty(
          name: 'dark_mode_enabled',
          value: isDarkMode.toString(),
        );
      }

      if (preferredVoice != null) {
        await _analytics.setUserProperty(
          name: 'preferred_voice',
          value: preferredVoice,
        );
      }

      if (defaultSpeechRate != null) {
        await _analytics.setUserProperty(
          name: 'default_speech_rate',
          value: defaultSpeechRate.toString(),
        );
      }

      if (backgroundPlaybackEnabled != null) {
        await _analytics.setUserProperty(
          name: 'background_playback_enabled',
          value: backgroundPlaybackEnabled.toString(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting user properties: $e');
      }
    }
  }

  /// Track a custom event
  Future<void> trackEvent(
    AnalyticsEvent event, {
    Map<String, Object>? parameters,
  }) async {
    try {
      final eventName = _getEventName(event);
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );

      if (kDebugMode) {
        debugPrint('Analytics event tracked: $eventName with parameters: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error tracking event ${event.name}: $e');
      }
    }
  }

  /// Track PDF import events
  Future<void> trackPDFImport({
    required String status, // 'started', 'completed', 'failed'
    String? fileName,
    int? fileSizeBytes,
    int? pageCount,
    double? processingTimeSeconds,
    String? errorMessage,
  }) async {
    final parameters = <String, Object>{
      'status': status,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (pageCount != null) 'page_count': pageCount,
      if (processingTimeSeconds != null) 'processing_time_seconds': processingTimeSeconds,
      if (errorMessage != null) 'error_message': errorMessage,
    };

    switch (status) {
      case 'started':
        await trackEvent(AnalyticsEvent.pdfImportStarted, parameters: parameters);
        break;
      case 'completed':
        await trackEvent(AnalyticsEvent.pdfImportCompleted, parameters: parameters);
        break;
      case 'failed':
        await trackEvent(AnalyticsEvent.pdfImportFailed, parameters: parameters);
        break;
    }
  }

  /// Track TTS playback events
  Future<void> trackTTSPlayback({
    required String action, // 'started', 'paused', 'resumed', 'stopped', 'completed'
    String? documentId,
    String? voiceId,
    double? speechRate,
    double? volume,
    double? pitch,
    int? currentPosition,
    int? totalDuration,
  }) async {
    final parameters = <String, Object>{
      'action': action,
      if (documentId != null) 'document_id': documentId,
      if (voiceId != null) 'voice_id': voiceId,
      if (speechRate != null) 'speech_rate': speechRate,
      if (volume != null) 'volume': volume,
      if (pitch != null) 'pitch': pitch,
      if (currentPosition != null) 'current_position': currentPosition,
      if (totalDuration != null) 'total_duration': totalDuration,
    };

    switch (action) {
      case 'started':
        await trackEvent(AnalyticsEvent.ttsPlaybackStarted, parameters: parameters);
        break;
      case 'paused':
        await trackEvent(AnalyticsEvent.ttsPlaybackPaused, parameters: parameters);
        break;
      case 'resumed':
        await trackEvent(AnalyticsEvent.ttsPlaybackResumed, parameters: parameters);
        break;
      case 'stopped':
        await trackEvent(AnalyticsEvent.ttsPlaybackStopped, parameters: parameters);
        break;
      case 'completed':
        await trackEvent(AnalyticsEvent.ttsPlaybackCompleted, parameters: parameters);
        break;
    }
  }

  /// Track voice selection events
  Future<void> trackVoiceSelection({
    required String action, // 'opened', 'preview_played', 'selected'
    String? voiceId,
    String? voiceName,
    String? voiceLocale,
    bool? isPreview,
  }) async {
    final parameters = <String, Object>{
      'action': action,
      if (voiceId != null) 'voice_id': voiceId,
      if (voiceName != null) 'voice_name': voiceName,
      if (voiceLocale != null) 'voice_locale': voiceLocale,
      if (isPreview != null) 'is_preview': isPreview,
    };

    switch (action) {
      case 'opened':
        await trackEvent(AnalyticsEvent.voiceSelectionOpened, parameters: parameters);
        break;
      case 'preview_played':
        await trackEvent(AnalyticsEvent.voicePreviewPlayed, parameters: parameters);
        break;
      case 'selected':
        await trackEvent(AnalyticsEvent.voiceSelected, parameters: parameters);
        break;
    }
  }

  /// Track settings changes
  Future<void> trackSettingsChange({
    required String setting,
    required String action,
    Object? oldValue,
    Object? newValue,
  }) async {
    final parameters = <String, Object>{
      'setting': setting,
      'action': action,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
    };

    switch (setting) {
      case 'theme':
        await trackEvent(AnalyticsEvent.themeChanged, parameters: parameters);
        break;
      case 'background_playback':
        await trackEvent(AnalyticsEvent.backgroundPlaybackToggled, parameters: parameters);
        break;
      case 'haptic_feedback':
        await trackEvent(AnalyticsEvent.hapticFeedbackToggled, parameters: parameters);
        break;
      case 'voice_preview':
        await trackEvent(AnalyticsEvent.voicePreviewToggled, parameters: parameters);
        break;
      default:
        await trackEvent(AnalyticsEvent.settingsOpened, parameters: parameters);
    }
  }

  /// Track app lifecycle events
  Future<void> trackAppLifecycle({
    required String event, // 'launched', 'backgrounded', 'foregrounded'
    int? launchTimeMs,
    String? previousScreen,
    String? currentScreen,
  }) async {
    final parameters = <String, Object>{
      'event': event,
      if (launchTimeMs != null) 'launch_time_ms': launchTimeMs,
      if (previousScreen != null) 'previous_screen': previousScreen,
      if (currentScreen != null) 'current_screen': currentScreen,
    };

    switch (event) {
      case 'launched':
        await trackEvent(AnalyticsEvent.appLaunched, parameters: parameters);
        break;
      case 'backgrounded':
        await trackEvent(AnalyticsEvent.appBackgrounded, parameters: parameters);
        break;
      case 'foregrounded':
        await trackEvent(AnalyticsEvent.appForegrounded, parameters: parameters);
        break;
    }
  }

  /// Track user engagement events
  Future<void> trackEngagement({
    required String action, // 'session_started', 'session_ended', 'feature_discovered', 'help_opened', 'feedback_submitted'
    int? sessionDurationMs,
    String? featureName,
    String? helpTopic,
    int? feedbackRating,
    String? feedbackComment,
  }) async {
    final parameters = <String, Object>{
      'action': action,
      if (sessionDurationMs != null) 'session_duration_ms': sessionDurationMs,
      if (featureName != null) 'feature_name': featureName,
      if (helpTopic != null) 'help_topic': helpTopic,
      if (feedbackRating != null) 'feedback_rating': feedbackRating,
      if (feedbackComment != null) 'feedback_comment': feedbackComment,
    };

    switch (action) {
      case 'session_started':
        await trackEvent(AnalyticsEvent.sessionStarted, parameters: parameters);
        break;
      case 'session_ended':
        await trackEvent(AnalyticsEvent.sessionEnded, parameters: parameters);
        break;
      case 'feature_discovered':
        await trackEvent(AnalyticsEvent.featureDiscovered, parameters: parameters);
        break;
      case 'help_opened':
        await trackEvent(AnalyticsEvent.helpOpened, parameters: parameters);
        break;
      case 'feedback_submitted':
        await trackEvent(AnalyticsEvent.feedbackSubmitted, parameters: parameters);
        break;
    }
  }

  /// Track performance metrics
  Future<void> trackPerformance({
    required String metric,
    required double value,
    String? unit,
    Map<String, Object>? additionalData,
  }) async {
    final parameters = <String, Object>{
      'metric': metric,
      'value': value,
      if (unit != null) 'unit': unit,
      if (additionalData != null) ...additionalData,
    };

    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: parameters,
    );
  }

  /// Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );

      if (parameters != null) {
        await _analytics.logEvent(
          name: 'screen_view_detailed',
          parameters: {
            'screen_name': screenName,
            if (screenClass != null) 'screen_class': screenClass,
            ...parameters,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error tracking screen view: $e');
      }
    }
  }

  /// Get the analytics event name from enum
  String _getEventName(AnalyticsEvent event) {
    return event.name;
  }
}

/// State notifier for analytics service
class AnalyticsNotifier extends StateNotifier<AnalyticsService> {
  AnalyticsNotifier(FirebaseAnalytics analytics) : super(AnalyticsService(analytics)) {
    state.initialize();
  }
}

/// Provider for analytics service
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsService>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return AnalyticsNotifier(analytics);
});

/// Convenience provider for tracking events
final eventTrackerProvider = Provider<void Function(AnalyticsEvent, {Map<String, Object>? parameters})>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return (event, {parameters}) => analytics.trackEvent(event, parameters: parameters);
});

/// Provider for tracking PDF events
final pdfAnalyticsProvider = Provider<void Function({
  required String status,
  String? fileName,
  int? fileSizeBytes,
  int? pageCount,
  double? processingTimeSeconds,
  String? errorMessage,
})>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return ({
    required String status,
    String? fileName,
    int? fileSizeBytes,
    int? pageCount,
    double? processingTimeSeconds,
    String? errorMessage,
  }) => analytics.trackPDFImport(
    status: status,
    fileName: fileName,
    fileSizeBytes: fileSizeBytes,
    pageCount: pageCount,
    processingTimeSeconds: processingTimeSeconds,
    errorMessage: errorMessage,
  );
});

/// Provider for tracking TTS events
final ttsAnalyticsProvider = Provider<void Function({
  required String action,
  String? documentId,
  String? voiceId,
  double? speechRate,
  double? volume,
  double? pitch,
  int? currentPosition,
  int? totalDuration,
})>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return ({
    required String action,
    String? documentId,
    String? voiceId,
    double? speechRate,
    double? volume,
    double? pitch,
    int? currentPosition,
    int? totalDuration,
  }) => analytics.trackTTSPlayback(
    action: action,
    documentId: documentId,
    voiceId: voiceId,
    speechRate: speechRate,
    volume: volume,
    pitch: pitch,
    currentPosition: currentPosition,
    totalDuration: totalDuration,
  );
});

/// Provider for tracking screen views
final screenAnalyticsProvider = Provider<void Function({
  required String screenName,
  String? screenClass,
  Map<String, Object>? parameters,
})>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return ({
    required String screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) => analytics.trackScreenView(
    screenName: screenName,
    screenClass: screenClass,
    parameters: parameters,
  );
});