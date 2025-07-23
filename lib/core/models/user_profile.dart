import 'package:equatable/equatable.dart';
import 'package:maxchomp/core/models/tts_models.dart';

/// User profile for managing multiple reading configurations
/// Following Context7 patterns for immutable state management
class UserProfile extends Equatable {
  /// Unique identifier for the profile
  final String id;
  
  /// Display name for the profile
  final String name;
  
  /// TTS settings specific to this profile
  final TTSSettingsModel ttsSettings;
  
  /// Whether this is the default/active profile
  final bool isDefault;
  
  /// Profile icon identifier (for UI display)
  final String iconId;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last modified timestamp
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.ttsSettings,
    this.isDefault = false,
    this.iconId = 'profile',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a default user profile with standard TTS settings
  factory UserProfile.defaultProfile() {
    final now = DateTime.now();
    return UserProfile(
      id: 'default',
      name: 'Default Profile',
      ttsSettings: TTSSettingsModel.defaultSettings,
      isDefault: true,
      iconId: 'account_circle',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a new user profile with custom settings
  factory UserProfile.create({
    required String name,
    required TTSSettingsModel ttsSettings,
    String iconId = 'profile',
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: 'profile_${now.millisecondsSinceEpoch}',
      name: name,
      ttsSettings: ttsSettings,
      isDefault: false,
      iconId: iconId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy profile with updated values
  UserProfile copyWith({
    String? id,
    String? name,
    TTSSettingsModel? ttsSettings,
    bool? isDefault,
    String? iconId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ttsSettings: ttsSettings ?? this.ttsSettings,
      isDefault: isDefault ?? this.isDefault,
      iconId: iconId ?? this.iconId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ttsSettings': ttsSettings.toJson(),
      'isDefault': isDefault,
      'iconId': iconId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      ttsSettings: TTSSettingsModel.fromJson(json['ttsSettings'] as Map<String, dynamic>),
      isDefault: json['isDefault'] as bool? ?? false,
      iconId: json['iconId'] as String? ?? 'profile',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get profile description for UI display
  String get description {
    final rate = ttsSettings.speechRate;
    final voice = ttsSettings.selectedVoice?.name ?? 'Default';
    return 'Voice: $voice, Speed: ${rate.toStringAsFixed(1)}x';
  }

  /// Check if profile has custom TTS settings
  bool get hasCustomSettings {
    return ttsSettings != TTSSettingsModel.defaultSettings;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ttsSettings,
    isDefault,
    iconId,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, isDefault: $isDefault, '
           'ttsSettings: $ttsSettings)';
  }
}

/// User profiles state for managing multiple profiles
class UserProfilesState extends Equatable {
  /// List of all user profiles
  final List<UserProfile> profiles;
  
  /// Currently active profile ID
  final String? activeProfileId;
  
  /// Whether profiles are loading
  final bool isLoading;
  
  /// Error message if any
  final String? error;

  const UserProfilesState({
    this.profiles = const [],
    this.activeProfileId,
    this.isLoading = false,
    this.error,
  });

  /// Create initial state with default profile
  factory UserProfilesState.initial() {
    final defaultProfile = UserProfile.defaultProfile();
    return UserProfilesState(
      profiles: [defaultProfile],
      activeProfileId: defaultProfile.id,
      isLoading: false,
    );
  }

  /// Create loading state
  UserProfilesState loading() {
    return copyWith(isLoading: true, error: null);
  }

  /// Create error state
  UserProfilesState withError(String error) {
    return copyWith(isLoading: false, error: error);
  }

  /// Get currently active profile
  UserProfile? get activeProfile {
    if (activeProfileId == null) return null;
    try {
      return profiles.firstWhere((p) => p.id == activeProfileId);
    } catch (e) {
      return null;
    }
  }

  /// Get default profile
  UserProfile? get defaultProfile {
    try {
      return profiles.firstWhere((p) => p.isDefault);
    } catch (e) {
      return null;
    }
  }

  /// Check if has custom profiles (beyond default)
  bool get hasCustomProfiles {
    return profiles.where((p) => !p.isDefault).isNotEmpty;
  }

  /// Copy state with updated values
  UserProfilesState copyWith({
    List<UserProfile>? profiles,
    String? activeProfileId,
    bool? isLoading,
    String? error,
  }) {
    return UserProfilesState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'activeProfileId': activeProfileId,
    };
  }

  /// Create from JSON
  factory UserProfilesState.fromJson(Map<String, dynamic> json) {
    final profilesJson = json['profiles'] as List<dynamic>? ?? [];
    final profiles = profilesJson
        .map((p) => UserProfile.fromJson(p as Map<String, dynamic>))
        .toList();
    
    return UserProfilesState(
      profiles: profiles,
      activeProfileId: json['activeProfileId'] as String?,
      isLoading: false,
    );
  }

  @override
  List<Object?> get props => [profiles, activeProfileId, isLoading, error];

  @override
  String toString() {
    return 'UserProfilesState(profiles: ${profiles.length}, '
           'activeProfileId: $activeProfileId, isLoading: $isLoading, '
           'error: $error)';
  }
}