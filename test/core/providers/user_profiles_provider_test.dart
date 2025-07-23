import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/core/models/user_profile.dart';
import 'package:maxchomp/core/models/tts_models.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/providers/analytics_provider.dart';
import 'package:maxchomp/core/providers/settings_export_provider.dart';
import 'package:maxchomp/core/providers/user_profiles_provider.dart';
import 'package:maxchomp/core/services/settings_export_service.dart';

import 'user_profiles_provider_test.mocks.dart';


@GenerateMocks([SharedPreferences, AnalyticsService])
void main() {
  group('UserProfilesProvider Tests', () {
    late MockSharedPreferences mockPrefs;
    late MockAnalyticsService mockAnalytics;
    late ProviderContainer container;
    
    const String storageKey = 'user_profiles_state';

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockAnalytics = MockAnalyticsService();
      
      // Setup default mocks using Context7 patterns
      when(mockAnalytics.trackEvent(any, parameters: anyNamed('parameters')))
          .thenAnswer((_) async {});
      
      // Use ProviderContainer with Context7 isolation patterns
      container = ProviderContainer(
        overrides: [
          // Override dependencies that UserProfilesNotifier needs
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          // Override the entire provider with our test instance
          userProfilesProvider.overrideWith((ref) => UserProfilesNotifier(
            mockPrefs,
            mockAnalytics,
            null, // No export service for tests
          )),
        ],
      );
      
      // Context7 pattern for automatic cleanup
      addTearDown(() => container.dispose());
    });

    group('Initialization and Loading', () {
      test('should load profiles from SharedPreferences on initialization', () async {
        // Arrange
        final testState = UserProfilesState.initial();
        final stateJson = json.encode(testState.toJson());
        when(mockPrefs.getString(storageKey)).thenReturn(stateJson);
        
        // Act
        final notifier = container.read(userProfilesProvider.notifier);
        final state = container.read(userProfilesProvider);
        
        // Assert - Wait for loading to complete
        expect(state.profiles, isNotEmpty);
        expect(state.profiles.first.isDefault, true);
        
        verify(mockPrefs.getString(storageKey)).called(1);
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileLoaded,
          parameters: anyNamed('parameters'),
        )).called(1);
      });

      test('should create initial state when no stored data exists', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        // Act
        final notifier = container.read(userProfilesProvider.notifier);
        final state = container.read(userProfilesProvider);
        
        // Assert
        expect(state.profiles.length, 1);
        expect(state.profiles.first.isDefault, true);
        expect(state.activeProfileId, state.profiles.first.id);
        
        verify(mockPrefs.setString(storageKey, any)).called(1);
      });

      test('should handle loading errors gracefully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenThrow(Exception('Storage error'));
        
        // Act
        final notifier = container.read(userProfilesProvider.notifier);
        final state = container.read(userProfilesProvider);
        
        // Assert
        expect(state.error, contains('Failed to load profiles'));
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileError,
          parameters: argThat(contains('error'), named: 'parameters'),
        )).called(1);
      });
    });

    group('Profile Creation', () {
      test('should create new profile successfully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final ttsSettings = const TTSSettingsModel(
          speechRate: 1.2,
          volume: 0.8,
          pitch: 1.0,
          language: 'en-US',
          selectedVoice: VoiceModel(
            name: 'Test Voice',
            locale: 'en-US',
            gender: 'female',
          ),
        );
        
        // Act
        final newProfile = await notifier.createProfile(
          name: 'Work Profile',
          ttsSettings: ttsSettings,
          iconId: 'work',
        );
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.profiles.length, 2); // Default + new profile
        expect(newProfile.name, 'Work Profile');
        expect(newProfile.iconId, 'work');
        expect(newProfile.ttsSettings.speechRate, 1.2);
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileCreated,
          parameters: argThat(contains('profile_name'), named: 'parameters'),
        )).called(1);
      });

      test('should reject duplicate profile names', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        const ttsSettings = TTSSettingsModel(
          speechRate: 1.0,
          volume: 1.0,
          pitch: 1.0,
          language: 'en-US',
        );
        
        // Create first profile
        await notifier.createProfile(
          name: 'Test Profile',
          ttsSettings: ttsSettings,
        );
        
        // Act & Assert - Try to create duplicate
        expect(
          () => notifier.createProfile(
            name: 'test profile', // Different case
            ttsSettings: ttsSettings,
          ),
          throwsA(isA<Exception>()),
        );
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileError,
          parameters: argThat(contains('error'), named: 'parameters'),
        )).called(1);
      });

      test('should handle creation errors', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        const ttsSettings = TTSSettingsModel(
          speechRate: 1.0,
          volume: 1.0,
          pitch: 1.0,
          language: 'en-US',
        );
        
        // Act & Assert
        await expectLater(
          notifier.createProfile(
            name: 'Test Profile',
            ttsSettings: ttsSettings,
          ),
          throwsA(isA<Exception>()),
        );
        
        final state = container.read(userProfilesProvider);
        expect(state.error, contains('Failed to create profile'));
      });
    });

    group('Profile Updates', () {
      test('should update existing profile successfully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final originalState = container.read(userProfilesProvider);
        final profileToUpdate = originalState.profiles.first;
        final updatedProfile = profileToUpdate.copyWith(
          name: 'Updated Name',
          ttsSettings: profileToUpdate.ttsSettings.copyWith(speechRate: 1.5),
        );
        
        // Act
        await notifier.updateProfile(updatedProfile);
        
        // Assert
        final state = container.read(userProfilesProvider);
        final updated = state.profiles.firstWhere((p) => p.id == profileToUpdate.id);
        expect(updated.name, 'Updated Name');
        expect(updated.ttsSettings.speechRate, 1.5);
        expect(updated.updatedAt, isNot(profileToUpdate.updatedAt));
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileUpdated,
          parameters: argThat(contains('profile_id'), named: 'parameters'),
        )).called(1);
      });

      test('should handle update of non-existent profile', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final nonExistentProfile = UserProfile.create(
          name: 'Non-existent',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        // Act
        await notifier.updateProfile(nonExistentProfile);
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.error, contains('Profile not found'));
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileError,
          parameters: argThat(contains('error'), named: 'parameters'),
        )).called(1);
      });
    });

    group('Profile Deletion', () {
      test('should delete non-default profile successfully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Create a custom profile to delete
        final customProfile = await notifier.createProfile(
          name: 'Custom Profile',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        final beforeDeleteCount = container.read(userProfilesProvider).profiles.length;
        
        // Act
        await notifier.deleteProfile(customProfile.id);
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.profiles.length, beforeDeleteCount - 1);
        expect(state.profiles.any((p) => p.id == customProfile.id), false);
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileDeleted,
          parameters: argThat(contains('profile_id'), named: 'parameters'),
        )).called(1);
      });

      test('should prevent deletion of default profile', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final state = container.read(userProfilesProvider);
        final defaultProfile = state.profiles.firstWhere((p) => p.isDefault);
        
        // Act
        await notifier.deleteProfile(defaultProfile.id);
        
        // Assert
        final finalState = container.read(userProfilesProvider);
        expect(finalState.error, contains('Cannot delete default profile'));
        expect(finalState.profiles.any((p) => p.id == defaultProfile.id), true);
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileError,
          parameters: argThat(contains('error'), named: 'parameters'),
        )).called(1);
      });

      test('should switch to default when deleting active profile', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Create and activate custom profile
        final customProfile = await notifier.createProfile(
          name: 'Custom Profile',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        await notifier.setActiveProfile(customProfile.id);
        
        final defaultProfileId = container.read(userProfilesProvider).defaultProfile?.id;
        
        // Act
        await notifier.deleteProfile(customProfile.id);
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.activeProfileId, defaultProfileId);
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileDeleted,
          parameters: argThat(contains('switched_to_default'), named: 'parameters'),
        )).called(1);
      });
    });

    group('Profile Activation', () {
      test('should set active profile successfully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final newProfile = await notifier.createProfile(
          name: 'Test Profile',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        // Act
        await notifier.setActiveProfile(newProfile.id);
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.activeProfileId, newProfile.id);
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileActivated,
          parameters: argThat(contains('profile_id'), named: 'parameters'),
        )).called(1);
      });

      test('should handle activation of non-existent profile', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Act
        await notifier.setActiveProfile('non-existent-id');
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.error, contains('Failed to set active profile'));
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileError,
          parameters: argThat(contains('error'), named: 'parameters'),
        )).called(1);
      });
    });

    group('Profile Duplication', () {
      test('should duplicate profile successfully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final originalProfile = await notifier.createProfile(
          name: 'Original Profile',
          ttsSettings: const TTSSettingsModel(
            speechRate: 1.3,
            volume: 1.0,
            pitch: 1.0,
            language: 'en-US',
          ),
          iconId: 'work',
        );
        
        // Small delay to ensure different timestamps for ID generation
        await Future.delayed(const Duration(milliseconds: 2));
        
        // Act
        final duplicatedProfile = await notifier.duplicateProfile(
          originalProfile.id,
          'Duplicated Profile',
        );
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(duplicatedProfile.name, 'Duplicated Profile');
        expect(duplicatedProfile.ttsSettings.speechRate, 1.3);
        expect(duplicatedProfile.iconId, 'work');
        expect(duplicatedProfile.id, isNot(originalProfile.id));
        expect(state.profiles.length, 3); // Default + original + duplicated
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileDuplicated,
          parameters: argThat(contains('original_profile_id'), named: 'parameters'),
        )).called(1);
      });

      test('should reject duplicate names when duplicating', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final originalProfile = await notifier.createProfile(
          name: 'Original Profile',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        // Act & Assert
        expect(
          () => notifier.duplicateProfile(
            originalProfile.id,
            'original profile', // Different case
          ),
          throwsA(isA<Exception>()),
        );
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileError,
          parameters: argThat(contains('error'), named: 'parameters'),
        )).called(1);
      });
    });

    group('Export and Import', () {
      test('should export profiles successfully (mock implementation)', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Act
        final filePath = await notifier.exportProfiles();
        
        // Assert - With no export service, it returns a mock filename
        expect(filePath, contains('user_profiles_'));
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileExported,
          parameters: argThat(contains('profile_count'), named: 'parameters'),
        )).called(1);
      });

      test('should import profiles with merge successfully (mock implementation)', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final beforeImportCount = container.read(userProfilesProvider).profiles.length;
        
        // Act - With no export service, import uses mock data (empty profiles)
        await notifier.importProfiles('/path/to/import/file.json');
        
        // Assert - Since mock import data is empty, no new profiles are added
        final state = container.read(userProfilesProvider);
        expect(state.profiles.length, beforeImportCount); // No change expected with mock data
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileImported,
          parameters: argThat(contains('imported_count'), named: 'parameters'),
        )).called(1);
      });

      test('should handle export without service gracefully', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Act - Export should work even without export service (mock implementation)
        final filePath = await notifier.exportProfiles();
        
        // Assert - Should return a mock filename without throwing
        expect(filePath, contains('user_profiles_'));
      });
    });

    group('Reset Functionality', () {
      test('should reset to default profile only', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Create additional profiles
        await notifier.createProfile(
          name: 'Custom Profile 1',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        await notifier.createProfile(
          name: 'Custom Profile 2',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        expect(container.read(userProfilesProvider).profiles.length, 3);
        
        // Act
        await notifier.resetToDefault();
        
        // Assert
        final state = container.read(userProfilesProvider);
        expect(state.profiles.length, 1);
        expect(state.profiles.first.isDefault, true);
        expect(state.activeProfileId, state.profiles.first.id);
        
        verify(mockAnalytics.trackEvent(
          AnalyticsEvent.userProfileReset,
          parameters: argThat(contains('reset_type'), named: 'parameters'),
        )).called(1);
      });
    });

    group('Provider Dependencies', () {
      test('activeUserProfileProvider should return active profile', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        final newProfile = await notifier.createProfile(
          name: 'Test Profile',
          ttsSettings: const TTSSettingsModel(
            speechRate: 1.25,
            volume: 1.0,
            pitch: 1.0,
            language: 'en-US',
          ),
        );
        await notifier.setActiveProfile(newProfile.id);
        
        // Act
        final activeProfile = container.read(activeUserProfileProvider);
        
        // Assert
        expect(activeProfile, isNotNull);
        expect(activeProfile!.id, newProfile.id);
        expect(activeProfile.name, 'Test Profile');
      });

      test('activeProfileTTSSettingsProvider should return active profile TTS settings', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        const ttsSettings = TTSSettingsModel(
          speechRate: 1.75,
          volume: 0.9,
          pitch: 1.0,
          language: 'en-US',
        );
        final newProfile = await notifier.createProfile(
          name: 'Test Profile',
          ttsSettings: ttsSettings,
        );
        await notifier.setActiveProfile(newProfile.id);
        
        // Act
        final activeTTSSettings = container.read(activeProfileTTSSettingsProvider);
        
        // Assert
        expect(activeTTSSettings, isNotNull);
        expect(activeTTSSettings!.speechRate, 1.75);
        expect(activeTTSSettings.volume, 0.9);
      });

      test('customUserProfilesProvider should return non-default profiles', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        await notifier.createProfile(
          name: 'Custom Profile 1',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        await notifier.createProfile(
          name: 'Custom Profile 2',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        // Act
        final customProfiles = container.read(customUserProfilesProvider);
        
        // Assert
        expect(customProfiles.length, 2);
        expect(customProfiles.every((p) => !p.isDefault), true);
        expect(customProfiles.map((p) => p.name), containsAll(['Custom Profile 1', 'Custom Profile 2']));
      });
    });

    group('State Management', () {
      test('should handle loading states correctly', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Act - Create profile (which sets loading state)
        final createFuture = notifier.createProfile(
          name: 'Test Profile',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        
        await createFuture;
        
        // Assert - Loading should be false after completion
        expect(container.read(userProfilesProvider).isLoading, false);
      });

      test('should preserve error state until next operation', () async {
        // Arrange
        when(mockPrefs.getString(storageKey)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenThrow(Exception('Save failed'));
        
        final notifier = container.read(userProfilesProvider.notifier);
        
        // Act - Cause an error
        try {
          await notifier.createProfile(
            name: 'Test Profile',
            ttsSettings: TTSSettingsModel.defaultSettings,
          );
        } catch (_) {
          // Exception expected
        }
        
        // Small delay to ensure state propagation
        await Future.delayed(const Duration(milliseconds: 1));
        
        // Assert - Error should be preserved
        final stateWithError = container.read(userProfilesProvider);
        expect(stateWithError.error, isNotNull);
        
        // Reset mock for successful operation
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        // Act - Successful operation should clear error
        await notifier.setActiveProfile(stateWithError.profiles.first.id);
        
        // Assert - Error should be cleared
        final clearedState = container.read(userProfilesProvider);
        expect(clearedState.error, isNull);
      });
    });
  });
}