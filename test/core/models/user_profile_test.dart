import 'package:flutter_test/flutter_test.dart';
import 'package:maxchomp/core/models/user_profile.dart';
import 'package:maxchomp/core/models/tts_models.dart';
import 'package:maxchomp/core/models/voice_model.dart';

void main() {
  group('UserProfile Tests', () {
    late TTSSettingsModel defaultTTSSettings;
    late TTSSettingsModel customTTSSettings;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 7, 23);
      defaultTTSSettings = TTSSettingsModel.defaultSettings;
      customTTSSettings = const TTSSettingsModel(
        speechRate: 1.5,
        volume: 0.8,
        pitch: 1.2,
        language: 'en-US',
        selectedVoice: VoiceModel(
          name: 'Test Voice',
          locale: 'en-US',
          quality: 'enhanced',
        ),
      );
    });

    group('UserProfile Creation', () {
      test('should create default profile correctly', () {
        // Act
        final profile = UserProfile.defaultProfile();

        // Assert
        expect(profile.id, 'default');
        expect(profile.name, 'Default Profile');
        expect(profile.isDefault, true);
        expect(profile.iconId, 'account_circle');
        expect(profile.ttsSettings, TTSSettingsModel.defaultSettings);
        expect(profile.createdAt, isA<DateTime>());
        expect(profile.updatedAt, isA<DateTime>());
      });

      test('should create custom profile correctly', () {
        // Act
        final profile = UserProfile.create(
          name: 'Reading Profile',
          ttsSettings: customTTSSettings,
          iconId: 'book',
        );

        // Assert
        expect(profile.name, 'Reading Profile');
        expect(profile.isDefault, false);
        expect(profile.iconId, 'book');
        expect(profile.ttsSettings, customTTSSettings);
        expect(profile.id, startsWith('profile_'));
        expect(profile.createdAt, isA<DateTime>());
        expect(profile.updatedAt, isA<DateTime>());
      });

      test('should create profile with constructor', () {
        // Act
        final profile = UserProfile(
          id: 'test-id',
          name: 'Test Profile',
          ttsSettings: defaultTTSSettings,
          isDefault: false,
          iconId: 'test-icon',
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Assert
        expect(profile.id, 'test-id');
        expect(profile.name, 'Test Profile');
        expect(profile.ttsSettings, defaultTTSSettings);
        expect(profile.isDefault, false);
        expect(profile.iconId, 'test-icon');
        expect(profile.createdAt, testDate);
        expect(profile.updatedAt, testDate);
      });
    });

    group('UserProfile copyWith', () {
      test('should copy profile with updated values', () {
        // Arrange
        final originalProfile = UserProfile.create(
          name: 'Original',
          ttsSettings: defaultTTSSettings,
        );
        final newDate = DateTime.now().add(const Duration(days: 1));

        // Act
        final updatedProfile = originalProfile.copyWith(
          name: 'Updated',
          ttsSettings: customTTSSettings,
          updatedAt: newDate,
        );

        // Assert
        expect(updatedProfile.id, originalProfile.id);
        expect(updatedProfile.name, 'Updated');
        expect(updatedProfile.ttsSettings, customTTSSettings);
        expect(updatedProfile.updatedAt, newDate);
        expect(updatedProfile.createdAt, originalProfile.createdAt);
        expect(updatedProfile.isDefault, originalProfile.isDefault);
      });

      test('should keep original values when not specified', () {
        // Arrange
        final originalProfile = UserProfile.create(
          name: 'Original',
          ttsSettings: customTTSSettings,
          iconId: 'original-icon',
        );

        // Act
        final copiedProfile = originalProfile.copyWith();

        // Assert
        expect(copiedProfile.id, originalProfile.id);
        expect(copiedProfile.name, originalProfile.name);
        expect(copiedProfile.ttsSettings, originalProfile.ttsSettings);
        expect(copiedProfile.iconId, originalProfile.iconId);
        expect(copiedProfile.isDefault, originalProfile.isDefault);
        expect(copiedProfile.createdAt, originalProfile.createdAt);
        expect(copiedProfile.updatedAt, originalProfile.updatedAt);
      });
    });

    group('UserProfile JSON Serialization', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final profile = UserProfile(
          id: 'test-id',
          name: 'Test Profile',
          ttsSettings: customTTSSettings,
          isDefault: false,
          iconId: 'test-icon',
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final json = profile.toJson();

        // Assert
        expect(json['id'], 'test-id');
        expect(json['name'], 'Test Profile');
        expect(json['isDefault'], false);
        expect(json['iconId'], 'test-icon');
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['updatedAt'], testDate.toIso8601String());
        expect(json['ttsSettings'], isA<Map<String, dynamic>>());
      });

      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'name': 'Test Profile',
          'ttsSettings': customTTSSettings.toJson(),
          'isDefault': false,
          'iconId': 'test-icon',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.id, 'test-id');
        expect(profile.name, 'Test Profile');
        expect(profile.ttsSettings.speechRate, customTTSSettings.speechRate);
        expect(profile.isDefault, false);
        expect(profile.iconId, 'test-icon');
        expect(profile.createdAt, testDate);
        expect(profile.updatedAt, testDate);
      });

      test('should handle optional fields in JSON', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'name': 'Test Profile',
          'ttsSettings': defaultTTSSettings.toJson(),
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        // Act
        final profile = UserProfile.fromJson(json);

        // Assert
        expect(profile.isDefault, false);
        expect(profile.iconId, 'profile');
      });
    });

    group('UserProfile Properties', () {
      test('should generate correct description', () {
        // Arrange
        final profile = UserProfile.create(
          name: 'Test',
          ttsSettings: customTTSSettings,
        );

        // Act
        final description = profile.description;

        // Assert
        expect(description, 'Voice: Test Voice, Speed: 1.5x');
      });

      test('should generate description with default voice', () {
        // Arrange
        final profile = UserProfile.create(
          name: 'Test',
          ttsSettings: defaultTTSSettings,
        );

        // Act
        final description = profile.description;

        // Assert
        expect(description, 'Voice: Default, Speed: 1.0x');
      });

      test('should detect custom settings correctly', () {
        // Arrange
        final defaultProfile = UserProfile.create(
          name: 'Default',
          ttsSettings: TTSSettingsModel.defaultSettings,
        );
        final customProfile = UserProfile.create(
          name: 'Custom',
          ttsSettings: customTTSSettings,
        );

        // Assert
        expect(defaultProfile.hasCustomSettings, false);
        expect(customProfile.hasCustomSettings, true);
      });
    });

    group('UserProfile Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final profile1 = UserProfile(
          id: 'test-id',
          name: 'Test',
          ttsSettings: defaultTTSSettings,
          isDefault: false,
          iconId: 'test',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final profile2 = UserProfile(
          id: 'test-id',
          name: 'Test',
          ttsSettings: defaultTTSSettings,
          isDefault: false,
          iconId: 'test',
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Assert
        expect(profile1, equals(profile2));
        expect(profile1.hashCode, equals(profile2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final profile1 = UserProfile.create(name: 'Test1', ttsSettings: defaultTTSSettings);
        final profile2 = UserProfile.create(name: 'Test2', ttsSettings: defaultTTSSettings);

        // Assert
        expect(profile1, isNot(equals(profile2)));
      });
    });
  });

  group('UserProfilesState Tests', () {
    late UserProfile defaultProfile;
    late UserProfile customProfile1;
    late UserProfile customProfile2;

    setUp(() {
      defaultProfile = UserProfile.defaultProfile();
      customProfile1 = UserProfile.create(
        name: 'Reading',
        ttsSettings: const TTSSettingsModel(speechRate: 1.2, volume: 1.0, pitch: 1.0, language: 'en-US'),
      );
      customProfile2 = UserProfile.create(
        name: 'Study',
        ttsSettings: const TTSSettingsModel(speechRate: 0.8, volume: 1.0, pitch: 1.0, language: 'en-US'),
      );
    });

    group('UserProfilesState Creation', () {
      test('should create initial state with default profile', () {
        // Act
        final state = UserProfilesState.initial();

        // Assert
        expect(state.profiles.length, 1);
        expect(state.profiles.first.isDefault, true);
        expect(state.activeProfileId, state.profiles.first.id);
        expect(state.isLoading, false);
        expect(state.error, null);
      });

      test('should create loading state', () {
        // Arrange
        final initialState = UserProfilesState.initial();

        // Act
        final loadingState = initialState.loading();

        // Assert
        expect(loadingState.isLoading, true);
        expect(loadingState.error, null);
        expect(loadingState.profiles, initialState.profiles);
      });

      test('should create error state', () {
        // Arrange
        final initialState = UserProfilesState.initial();
        const errorMessage = 'Test error';

        // Act
        final errorState = initialState.withError(errorMessage);

        // Assert
        expect(errorState.isLoading, false);
        expect(errorState.error, errorMessage);
        expect(errorState.profiles, initialState.profiles);
      });
    });

    group('UserProfilesState Properties', () {
      test('should get active profile correctly', () {
        // Arrange
        final state = UserProfilesState(
          profiles: [defaultProfile, customProfile1],
          activeProfileId: customProfile1.id,
        );

        // Act
        final activeProfile = state.activeProfile;

        // Assert
        expect(activeProfile, customProfile1);
      });

      test('should return null for invalid active profile ID', () {
        // Arrange
        final state = UserProfilesState(
          profiles: [defaultProfile],
          activeProfileId: 'invalid-id',
        );

        // Act
        final activeProfile = state.activeProfile;

        // Assert
        expect(activeProfile, null);
      });

      test('should get default profile correctly', () {
        // Arrange
        final state = UserProfilesState(
          profiles: [customProfile1, defaultProfile, customProfile2],
        );

        // Act
        final foundDefaultProfile = state.defaultProfile;

        // Assert
        expect(foundDefaultProfile, defaultProfile);
      });

      test('should detect custom profiles correctly', () {
        // Arrange
        final stateWithOnlyDefault = UserProfilesState(
          profiles: [defaultProfile],
        );
        final stateWithCustom = UserProfilesState(
          profiles: [defaultProfile, customProfile1],
        );

        // Assert
        expect(stateWithOnlyDefault.hasCustomProfiles, false);
        expect(stateWithCustom.hasCustomProfiles, true);
      });
    });

    group('UserProfilesState JSON Serialization', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final state = UserProfilesState(
          profiles: [defaultProfile, customProfile1],
          activeProfileId: customProfile1.id,
        );

        // Act
        final json = state.toJson();

        // Assert
        expect(json['profiles'], isA<List>());
        expect(json['profiles'].length, 2);
        expect(json['activeProfileId'], customProfile1.id);
      });

      test('should create from JSON correctly', () {
        // Arrange
        final originalState = UserProfilesState(
          profiles: [defaultProfile, customProfile1],
          activeProfileId: customProfile1.id,
        );
        final json = originalState.toJson();

        // Act
        final recreatedState = UserProfilesState.fromJson(json);

        // Assert
        expect(recreatedState.profiles.length, 2);
        expect(recreatedState.activeProfileId, customProfile1.id);
        expect(recreatedState.isLoading, false);
        expect(recreatedState.error, null);
      });
    });

    group('UserProfilesState copyWith', () {
      test('should copy state with updated values', () {
        // Arrange
        final originalState = UserProfilesState(
          profiles: [defaultProfile],
          activeProfileId: defaultProfile.id,
          isLoading: false,
          error: null,
        );

        // Act
        final updatedState = originalState.copyWith(
          profiles: [defaultProfile, customProfile1],
          activeProfileId: customProfile1.id,
          isLoading: true,
          error: 'Test error',
        );

        // Assert
        expect(updatedState.profiles.length, 2);
        expect(updatedState.activeProfileId, customProfile1.id);
        expect(updatedState.isLoading, true);
        expect(updatedState.error, 'Test error');
      });

      test('should keep original values when not specified', () {
        // Arrange
        final originalState = UserProfilesState(
          profiles: [defaultProfile, customProfile1],
          activeProfileId: customProfile1.id,
          isLoading: true,
          error: 'Original error',
        );

        // Act
        final copiedState = originalState.copyWith();

        // Assert
        expect(copiedState.profiles, originalState.profiles);
        expect(copiedState.activeProfileId, originalState.activeProfileId);
        expect(copiedState.isLoading, originalState.isLoading);
        expect(copiedState.error, originalState.error);
      });
    });

    group('UserProfilesState Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final state1 = UserProfilesState(
          profiles: [defaultProfile],
          activeProfileId: defaultProfile.id,
          isLoading: false,
          error: null,
        );
        final state2 = UserProfilesState(
          profiles: [defaultProfile],
          activeProfileId: defaultProfile.id,
          isLoading: false,
          error: null,
        );

        // Assert
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final state1 = UserProfilesState(profiles: [defaultProfile]);
        final state2 = UserProfilesState(profiles: [customProfile1]);

        // Assert
        expect(state1, isNot(equals(state2)));
      });
    });
  });
}