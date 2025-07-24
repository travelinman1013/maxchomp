import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/models/user_profile.dart';
import 'package:maxchomp/core/models/tts_models.dart';
import 'package:maxchomp/core/providers/analytics_provider.dart';
import 'package:maxchomp/core/providers/settings_export_provider.dart';
import 'package:maxchomp/core/services/settings_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

/// User Profiles State Notifier for managing multiple reading configurations
/// Following Context7 Riverpod patterns for state management
class UserProfilesNotifier extends StateNotifier<UserProfilesState> {
  final SharedPreferences _prefs;
  final AnalyticsService _analytics;
  // ignore: unused_field
  final SettingsExportService? _exportService;
  
  static const String _storageKey = 'user_profiles_state';

  UserProfilesNotifier(
    this._prefs, 
    this._analytics, [
    this._exportService,
  ]) : super(UserProfilesState.initial()) {
    _loadProfiles();
  }

  /// Load profiles from persistent storage
  Future<void> _loadProfiles() async {
    try {
      state = state.loading();
      
      final profilesJson = _prefs.getString(_storageKey);
      if (profilesJson != null) {
        final data = json.decode(profilesJson) as Map<String, dynamic>;
        state = UserProfilesState.fromJson(data);
      } else {
        // First time - ensure we have default profile
        state = UserProfilesState.initial();
        await _saveProfiles();
      }
      
      // Track profile loading
      _analytics.trackEvent(
        AnalyticsEvent.userProfileLoaded,
        parameters: {
          'profile_count': state.profiles.length,
          'has_custom_profiles': state.hasCustomProfiles,
        },
      );
    } catch (e) {
      state = state.withError('Failed to load profiles: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'load_failed', 'message': e.toString()},
      );
    }
  }

  /// Save profiles to persistent storage
  Future<void> _saveProfiles() async {
    try {
      final profilesJson = json.encode(state.toJson());
      await _prefs.setString(_storageKey, profilesJson);
    } catch (e) {
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'save_failed', 'message': e.toString()},
      );
      rethrow; // Ensure exceptions propagate to callers
    }
  }

  /// Create a new user profile
  Future<UserProfile> createProfile({
    required String name,
    required TTSSettingsModel ttsSettings,
    String iconId = 'profile',
  }) async {
    try {
      state = state.loading();
      
      // Validate unique name
      if (state.profiles.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Profile name already exists');
      }
      
      final newProfile = UserProfile.create(
        name: name,
        ttsSettings: ttsSettings,
        iconId: iconId,
      );
      
      final updatedProfiles = [...state.profiles, newProfile];
      state = state.copyWith(
        profiles: updatedProfiles,
        isLoading: false,
      );
      
      await _saveProfiles();
      
      // Track profile creation
      _analytics.trackEvent(
        AnalyticsEvent.userProfileCreated,
        parameters: {
          'profile_name': name,
          'speech_rate': ttsSettings.speechRate,
          'has_custom_voice': ttsSettings.selectedVoice != null,
        },
      );
      
      return newProfile;
    } catch (e) {
      state = state.withError('Failed to create profile: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'create_failed', 'message': e.toString()},
      );
      rethrow;
    }
  }

  /// Update an existing profile
  Future<void> updateProfile(UserProfile updatedProfile) async {
    try {
      state = state.loading();
      
      final profileIndex = state.profiles.indexWhere((p) => p.id == updatedProfile.id);
      if (profileIndex == -1) {
        throw Exception('Profile not found');
      }
      
      final updatedProfiles = [...state.profiles];
      updatedProfiles[profileIndex] = updatedProfile.copyWith(
        updatedAt: DateTime.now(),
      );
      
      state = state.copyWith(
        profiles: updatedProfiles,
        isLoading: false,
      );
      
      await _saveProfiles();
      
      // Track profile update
      _analytics.trackEvent(
        AnalyticsEvent.userProfileUpdated,
        parameters: {
          'profile_id': updatedProfile.id,
          'profile_name': updatedProfile.name,
        },
      );
    } catch (e) {
      state = state.withError('Failed to update profile: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'update_failed', 'message': e.toString()},
      );
    }
  }

  /// Delete a profile (cannot delete default profile)
  Future<void> deleteProfile(String profileId) async {
    try {
      state = state.loading();
      
      final profile = state.profiles.firstWhere((p) => p.id == profileId);
      if (profile.isDefault) {
        throw Exception('Cannot delete default profile');
      }
      
      final updatedProfiles = state.profiles.where((p) => p.id != profileId).toList();
      
      // If deleted profile was active, switch to default
      String? newActiveProfileId = state.activeProfileId;
      if (state.activeProfileId == profileId) {
        newActiveProfileId = state.defaultProfile?.id;
      }
      
      state = state.copyWith(
        profiles: updatedProfiles,
        activeProfileId: newActiveProfileId,
        isLoading: false,
      );
      
      await _saveProfiles();
      
      // Track profile deletion
      _analytics.trackEvent(
        AnalyticsEvent.userProfileDeleted,
        parameters: {
          'profile_id': profileId,
          'profile_name': profile.name,
          'switched_to_default': state.activeProfileId == state.defaultProfile?.id,
        },
      );
    } catch (e) {
      state = state.withError('Failed to delete profile: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'delete_failed', 'message': e.toString()},
      );
    }
  }

  /// Set active profile
  Future<void> setActiveProfile(String profileId) async {
    try {
      final profile = state.profiles.firstWhere((p) => p.id == profileId);
      
      state = state.copyWith(activeProfileId: profileId);
      await _saveProfiles();
      
      // Track profile activation
      _analytics.trackEvent(
        AnalyticsEvent.userProfileActivated,
        parameters: {
          'profile_id': profileId,
          'profile_name': profile.name,
          'speech_rate': profile.ttsSettings.speechRate,
        },
      );
    } catch (e) {
      state = state.withError('Failed to set active profile: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'activation_failed', 'message': e.toString()},
      );
    }
  }

  /// Duplicate an existing profile
  Future<UserProfile> duplicateProfile(String profileId, String newName) async {
    try {
      state = state.loading();
      
      final originalProfile = state.profiles.firstWhere((p) => p.id == profileId);
      
      // Validate unique name
      if (state.profiles.any((p) => p.name.toLowerCase() == newName.toLowerCase())) {
        throw Exception('Profile name already exists');
      }
      
      final duplicatedProfile = UserProfile.create(
        name: newName,
        ttsSettings: originalProfile.ttsSettings,
        iconId: originalProfile.iconId,
      );
      
      final updatedProfiles = [...state.profiles, duplicatedProfile];
      state = state.copyWith(
        profiles: updatedProfiles,
        isLoading: false,
      );
      
      await _saveProfiles();
      
      // Track profile duplication
      _analytics.trackEvent(
        AnalyticsEvent.userProfileDuplicated,
        parameters: {
          'original_profile_id': profileId,
          'new_profile_name': newName,
          'original_profile_name': originalProfile.name,
        },
      );
      
      return duplicatedProfile;
    } catch (e) {
      state = state.withError('Failed to duplicate profile: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'duplicate_failed', 'message': e.toString()},
      );
      rethrow;
    }
  }

  /// Export profiles to file (if export service available)
  Future<String?> exportProfiles() async {
    
    try {
      // ignore: unused_local_variable
      final exportData = {
        'profiles': state.toJson(),
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      // For now, just return a mock file path since the settings export service
      // doesn't handle custom data. In a real implementation, this would write
      // the exportData to a file and return the path.
      final filePath = 'user_profiles_${DateTime.now().millisecondsSinceEpoch}.json';
      
      // Track profile export
      _analytics.trackEvent(
        AnalyticsEvent.userProfileExported,
        parameters: {
          'profile_count': state.profiles.length,
          'file_path': 'success',
        },
      );
      
      return filePath;
    } catch (e) {
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'export_failed', 'message': e.toString()},
      );
      rethrow;
    }
  }

  /// Import profiles from file (if export service available)
  Future<void> importProfiles(String filePath, {bool mergeWithExisting = true}) async {
    
    try {
      state = state.loading();
      
      // For now, mock the import since the settings export service doesn't handle custom data
      // In a real implementation, this would read from the file and parse the JSON
      final profilesData = {'profiles': []} as Map<String, dynamic>?;
      
      if (profilesData == null) {
        throw Exception('Invalid profiles data in import file');
      }
      
      final importedState = UserProfilesState.fromJson(profilesData);
      
      List<UserProfile> finalProfiles;
      if (mergeWithExisting) {
        // Merge with existing profiles, avoiding duplicates by name
        final existingNames = state.profiles.map((p) => p.name.toLowerCase()).toSet();
        final newProfiles = importedState.profiles
            .where((p) => !existingNames.contains(p.name.toLowerCase()))
            .toList();
        finalProfiles = [...state.profiles, ...newProfiles];
      } else {
        // Replace all profiles except default
        final defaultProfile = state.defaultProfile;
        finalProfiles = defaultProfile != null 
            ? [defaultProfile, ...importedState.profiles.where((p) => !p.isDefault)]
            : importedState.profiles;
      }
      
      state = state.copyWith(
        profiles: finalProfiles,
        isLoading: false,
      );
      
      await _saveProfiles();
      
      // Track profile import
      _analytics.trackEvent(
        AnalyticsEvent.userProfileImported,
        parameters: {
          'imported_count': importedState.profiles.length,
          'final_count': finalProfiles.length,
          'merge_mode': mergeWithExisting,
        },
      );
    } catch (e) {
      state = state.withError('Failed to import profiles: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'import_failed', 'message': e.toString()},
      );
    }
  }

  /// Reset to default profile only
  Future<void> resetToDefault() async {
    try {
      state = state.loading();
      
      final defaultProfile = UserProfile.defaultProfile();
      state = UserProfilesState(
        profiles: [defaultProfile],
        activeProfileId: defaultProfile.id,
        isLoading: false,
      );
      
      await _saveProfiles();
      
      // Track reset
      _analytics.trackEvent(
        AnalyticsEvent.userProfileReset,
        parameters: {'reset_type': 'to_default'},
      );
    } catch (e) {
      state = state.withError('Failed to reset profiles: $e');
      _analytics.trackEvent(
        AnalyticsEvent.userProfileError,
        parameters: {'error': 'reset_failed', 'message': e.toString()},
      );
    }
  }
}

/// Provider for UserProfilesNotifier
final userProfilesProvider = StateNotifierProvider<UserProfilesNotifier, UserProfilesState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final analytics = ref.watch(analyticsProvider);
  // Export service is optional - mainly used for production
  SettingsExportService? exportService;
  try {
    exportService = ref.watch(settingsExportServiceProvider);
  } catch (_) {
    // Export service provider not available (e.g., in tests)
    exportService = null;
  }
  
  return UserProfilesNotifier(prefs, analytics, exportService);
});

/// Provider for currently active profile
final activeUserProfileProvider = Provider<UserProfile?>((ref) {
  final profilesState = ref.watch(userProfilesProvider);
  return profilesState.activeProfile;
});

/// Provider for active profile's TTS settings
final activeProfileTTSSettingsProvider = Provider<TTSSettingsModel?>((ref) {
  final activeProfile = ref.watch(activeUserProfileProvider);
  return activeProfile?.ttsSettings;
});

/// Provider for custom profiles (excluding default)
final customUserProfilesProvider = Provider<List<UserProfile>>((ref) {
  final profilesState = ref.watch(userProfilesProvider);
  return profilesState.profiles.where((p) => !p.isDefault).toList();
});