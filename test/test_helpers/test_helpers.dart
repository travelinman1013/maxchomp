import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:maxchomp/core/providers/analytics_provider.dart';
import 'package:maxchomp/core/providers/user_profiles_provider.dart';
import '../core/providers/user_profiles_provider_test.mocks.dart';

/// Test helpers following Context7 patterns for consistent testing
/// 
/// Provides utilities for setting up ProviderScope overrides, Material 3 theming,
/// and realistic mock configurations for widget and integration testing.

/// Export mock classes for use in tests
export '../core/providers/user_profiles_provider_test.mocks.dart';
export 'firebase_test_setup.dart';

/// Build test app with proper Material 3 theme and ProviderScope
Widget buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(body: child),
    ),
  );
}

/// Create a test ProviderContainer with proper Context7 isolation
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  return ProviderContainer(overrides: overrides);
}

/// Setup mock analytics service with Context7 patterns
MockAnalyticsService setupMockAnalytics() {
  final mockAnalytics = MockAnalyticsService();
  
  // Setup default stubbing for all analytics methods
  when(mockAnalytics.initialize()).thenAnswer((_) async {});
  when(mockAnalytics.trackEvent(any, parameters: anyNamed('parameters')))
      .thenAnswer((_) async {});
  when(mockAnalytics.setUserProperties(
    userId: anyNamed('userId'),
    isDarkMode: anyNamed('isDarkMode'),
    preferredVoice: anyNamed('preferredVoice'),
    defaultSpeechRate: anyNamed('defaultSpeechRate'),
    backgroundPlaybackEnabled: anyNamed('backgroundPlaybackEnabled'),
  )).thenAnswer((_) async {});
  when(mockAnalytics.trackSettingsChange(
    setting: anyNamed('setting'),
    action: anyNamed('action'),
    oldValue: anyNamed('oldValue'),
    newValue: anyNamed('newValue'),
  )).thenAnswer((_) async {});

  return mockAnalytics;
}

/// Setup mock SharedPreferences with Context7 patterns
MockSharedPreferences setupMockPreferences() {
  final mockPrefs = MockSharedPreferences();
  
  // Setup default stubbing for common operations
  when(mockPrefs.getString(any)).thenReturn(null);
  when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
  when(mockPrefs.remove(any)).thenAnswer((_) async => true);
  when(mockPrefs.containsKey(any)).thenReturn(false);
  
  return mockPrefs;
}

/// Create user profiles provider override following Context7 patterns
Override createUserProfilesProviderOverride({
  MockSharedPreferences? mockPrefs,
  MockAnalyticsService? mockAnalytics,
}) {
  final prefs = mockPrefs ?? setupMockPreferences();
  final analytics = mockAnalytics ?? setupMockAnalytics();
  
  return userProfilesProvider.overrideWith((ref) => UserProfilesNotifier(
    prefs,
    analytics,
    null, // No export service for tests
  ));
}