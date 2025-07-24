import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:maxchomp/core/models/user_profile.dart';
import 'package:maxchomp/core/models/tts_models.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/providers/user_profiles_provider.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/core/providers/analytics_provider.dart';
import '../test_helpers/test_helpers.dart';

void main() {
  group('Profile TTS Integration Tests', () {
    // Use a helper function to create fresh containers for each test
    ProviderContainer createFreshContainer() {
      final mockPrefs = setupMockPreferences();
      final mockAnalytics = setupMockAnalytics();

      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          createUserProfilesProviderOverride(
            mockPrefs: mockPrefs,
            mockAnalytics: mockAnalytics,
          ),
        ],
      );
    }

    test('Profile switching updates TTS settings in real-time', () async {
      final container = createFreshContainer();
      addTearDown(container.dispose);
      
      // Initialize providers
      final userProfilesNotifier = container.read(userProfilesProvider.notifier);

      // Create custom profiles with different TTS settings
      final profile1Settings = TTSSettingsModel(
        speechRate: 1.0,
        volume: 0.8,
        pitch: 1.0,
        language: 'en-US',
        selectedVoice: VoiceModel(name: 'Voice1', locale: 'en-US', quality: 'high'),
      );

      final profile2Settings = TTSSettingsModel(
        speechRate: 1.5,
        volume: 0.6,
        pitch: 1.2,
        language: 'en-GB',
        selectedVoice: VoiceModel(name: 'Voice2', locale: 'en-GB', quality: 'medium'),
      );

      // Create profiles
      final profile1 = await userProfilesNotifier.createProfile(
        name: 'Reading Profile',
        ttsSettings: profile1Settings,
        iconId: 'reading',
      );

      final profile2 = await userProfilesNotifier.createProfile(
        name: 'Speed Profile',
        ttsSettings: profile2Settings,
        iconId: 'speed',
      );

      // Verify profiles are created
      final userProfilesState = container.read(userProfilesProvider);
      expect(userProfilesState.profiles.length, 3); // Default + 2 custom
      expect(userProfilesState.profiles.map((p) => p.name), contains('Reading Profile'));
      expect(userProfilesState.profiles.map((p) => p.name), contains('Speed Profile'));

      // Test switching to profile1
      await userProfilesNotifier.setActiveProfile(profile1.id);

      // Verify active profile changed
      final activeProfile1 = container.read(activeUserProfileProvider);
      expect(activeProfile1?.id, profile1.id);
      expect(activeProfile1?.name, 'Reading Profile');

      // Verify TTS settings from active profile
      final activeTTSSettings1 = container.read(activeProfileTTSSettingsProvider);
      expect(activeTTSSettings1?.speechRate, 1.0);
      expect(activeTTSSettings1?.volume, 0.8);
      expect(activeTTSSettings1?.pitch, 1.0);
      expect(activeTTSSettings1?.language, 'en-US');
      expect(activeTTSSettings1?.selectedVoice?.name, 'Voice1');

      // Test switching to profile2
      await userProfilesNotifier.setActiveProfile(profile2.id);

      // Verify active profile changed
      final activeProfile2 = container.read(activeUserProfileProvider);
      expect(activeProfile2?.id, profile2.id);
      expect(activeProfile2?.name, 'Speed Profile');

      // Verify TTS settings updated
      final activeTTSSettings2 = container.read(activeProfileTTSSettingsProvider);
      expect(activeTTSSettings2?.speechRate, 1.5);
      expect(activeTTSSettings2?.volume, 0.6);
      expect(activeTTSSettings2?.pitch, 1.2);
      expect(activeTTSSettings2?.language, 'en-GB');
      expect(activeTTSSettings2?.selectedVoice?.name, 'Voice2');

      // Analytics tracking would be verified here, but we'd need access to the mock
      // which is encapsulated in the test container setup
    });

    test('TTS settings provider reflects active profile changes', () async {
      final container = createFreshContainer();
      addTearDown(container.dispose);
      
      // Initialize providers
      final userProfilesNotifier = container.read(userProfilesProvider.notifier);

      // Create a profile with specific TTS settings
      final customSettings = TTSSettingsModel(
        speechRate: 1.3,
        volume: 0.9,
        pitch: 0.8,
        language: 'en-AU',
        selectedVoice: VoiceModel(name: 'TestVoice', locale: 'en-AU', quality: 'high'),
      );

      final customProfile = await userProfilesNotifier.createProfile(
        name: 'Test Profile',
        ttsSettings: customSettings,
        iconId: 'test',
      );

      // Switch to the custom profile
      await userProfilesNotifier.setActiveProfile(customProfile.id);

      // Verify the TTS settings provider reflects the active profile
      final activeTTSSettings = container.read(activeProfileTTSSettingsProvider);
      expect(activeTTSSettings, isNotNull);
      expect(activeTTSSettings?.speechRate, 1.3);
      expect(activeTTSSettings?.volume, 0.9);
      expect(activeTTSSettings?.pitch, 0.8);
      expect(activeTTSSettings?.language, 'en-AU');
      expect(activeTTSSettings?.selectedVoice?.name, 'TestVoice');
    });

    test('Profile switching maintains data consistency', () async {
      final container = createFreshContainer();
      addTearDown(container.dispose);
      
      // Initialize providers
      final userProfilesNotifier = container.read(userProfilesProvider.notifier);

      // Create multiple profiles
      final profile1 = await userProfilesNotifier.createProfile(
        name: 'Profile A',
        ttsSettings: TTSSettingsModel(
          speechRate: 0.8,
          volume: 1.0,
          pitch: 0.9,
          language: 'en-US',
        ),
      );

      final profile2 = await userProfilesNotifier.createProfile(
        name: 'Profile B',
        ttsSettings: TTSSettingsModel(
          speechRate: 1.7,
          volume: 0.5,
          pitch: 1.3,
          language: 'fr-FR',
        ),
      );
      
      // Switch between profiles multiple times
      await userProfilesNotifier.setActiveProfile(profile1.id);
      final settings1 = container.read(activeProfileTTSSettingsProvider);
      expect(settings1?.speechRate, 0.8);
      expect(settings1?.language, 'en-US');

      await userProfilesNotifier.setActiveProfile(profile2.id);
      final settings2 = container.read(activeProfileTTSSettingsProvider);
      expect(settings2?.speechRate, 1.7);
      expect(settings2?.language, 'fr-FR');

      // Switch back to profile1
      await userProfilesNotifier.setActiveProfile(profile1.id);
      final settings1Again = container.read(activeProfileTTSSettingsProvider);
      expect(settings1Again?.speechRate, 0.8);
      expect(settings1Again?.language, 'en-US');

      // Verify consistency
      expect(settings1?.speechRate, settings1Again?.speechRate);
      expect(settings1?.language, settings1Again?.language);
    });

    test('Default profile has valid TTS settings', () async {
      final container = createFreshContainer();
      addTearDown(container.dispose);
      
      // Get the default profile
      final userProfilesState = container.read(userProfilesProvider);
      final defaultProfile = userProfilesState.defaultProfile;
      
      expect(defaultProfile, isNotNull);
      expect(defaultProfile?.isDefault, true);
      expect(defaultProfile?.ttsSettings, isNotNull);

      // Verify default TTS settings are valid
      final defaultTTSSettings = defaultProfile?.ttsSettings;
      expect(defaultTTSSettings?.speechRate, greaterThan(0.0));
      expect(defaultTTSSettings?.speechRate, lessThanOrEqualTo(3.0));
      expect(defaultTTSSettings?.volume, greaterThanOrEqualTo(0.0));
      expect(defaultTTSSettings?.volume, lessThanOrEqualTo(1.0));
      expect(defaultTTSSettings?.pitch, greaterThan(0.0));
      expect(defaultTTSSettings?.pitch, lessThanOrEqualTo(2.0));
      expect(defaultTTSSettings?.language, isNotEmpty);
    });

    test('Profile deletion switches to default with correct settings', () async {
      final container = createFreshContainer();
      addTearDown(container.dispose);
      
      // Initialize providers
      final userProfilesNotifier = container.read(userProfilesProvider.notifier);

      // Create a custom profile
      final customProfile = await userProfilesNotifier.createProfile(
        name: 'Temporary Profile',
        ttsSettings: TTSSettingsModel(
          speechRate: 2.0,
          volume: 0.3,
          pitch: 1.5,
          language: 'es-ES',
        ),
      );

      // Switch to the custom profile
      await userProfilesNotifier.setActiveProfile(customProfile.id);
      
      // Verify we're using the custom profile
      final activeProfile = container.read(activeUserProfileProvider);
      expect(activeProfile?.id, customProfile.id);
      
      final customTTSSettings = container.read(activeProfileTTSSettingsProvider);
      expect(customTTSSettings?.speechRate, 2.0);
      expect(customTTSSettings?.language, 'es-ES');

      // Delete the custom profile
      await userProfilesNotifier.deleteProfile(customProfile.id);

      // Verify we switched back to default
      final newActiveProfile = container.read(activeUserProfileProvider);
      expect(newActiveProfile?.isDefault, true);
      
      // Verify TTS settings switched to default
      final defaultTTSSettings = container.read(activeProfileTTSSettingsProvider);
      expect(defaultTTSSettings?.speechRate, isNot(equals(2.0)));
      expect(defaultTTSSettings?.language, isNot(equals('es-ES')));
    });
  });
}