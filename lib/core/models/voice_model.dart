/// Represents a Text-to-Speech voice with its properties
class VoiceModel {
  /// The name of the voice (e.g., 'Karen', 'Alex', 'Marie')
  final String name;
  
  /// The locale/language code for the voice (e.g., 'en-US', 'en-AU', 'fr-FR')
  final String locale;
  
  /// Optional identifier used by the TTS engine (iOS/macOS specific)
  final String? identifier;
  
  /// Optional gender of the voice
  final String? gender;
  
  /// Optional quality rating of the voice
  final String? quality;
  
  /// Creates a new VoiceModel instance
  const VoiceModel({
    required this.name,
    required this.locale,
    this.identifier,
    this.gender,
    this.quality,
  });
  
  /// Creates a VoiceModel from a Map (typically from flutter_tts getVoices response)
  factory VoiceModel.fromMap(Map<String, dynamic> map) {
    return VoiceModel(
      name: map['name'] as String,
      locale: map['locale'] as String,
      identifier: map['identifier'] as String?,
      gender: map['gender'] as String?,
      quality: map['quality'] as String?,
    );
  }
  
  /// Converts the VoiceModel to a Map (for TTS engine usage)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'locale': locale,
    };
    
    if (identifier != null) {
      map['identifier'] = identifier;
    }
    if (gender != null) {
      map['gender'] = gender;
    }
    if (quality != null) {
      map['quality'] = quality;
    }
    
    return map;
  }
  
  /// Returns a user-friendly display name for the voice
  String get displayName => '$name ($locale)';
  
  /// Returns the language code from the locale (e.g., 'en' from 'en-US')
  String get languageCode {
    final parts = locale.split('-');
    return parts.isNotEmpty ? parts[0] : locale;
  }
  
  /// Returns the country code from the locale (e.g., 'US' from 'en-US')
  String? get countryCode {
    final parts = locale.split('-');
    return parts.length > 1 ? parts[1] : null;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VoiceModel &&
        other.name == name &&
        other.locale == locale &&
        other.identifier == identifier &&
        other.gender == gender &&
        other.quality == quality;
  }
  
  @override
  int get hashCode {
    return name.hashCode ^
        locale.hashCode ^
        identifier.hashCode ^
        gender.hashCode ^
        quality.hashCode;
  }
  
  @override
  String toString() {
    return 'VoiceModel(name: $name, locale: $locale, identifier: $identifier, gender: $gender, quality: $quality)';
  }
  
  /// Creates a copy of this VoiceModel with optionally updated fields
  VoiceModel copyWith({
    String? name,
    String? locale,
    String? identifier,
    String? gender,
    String? quality,
  }) {
    return VoiceModel(
      name: name ?? this.name,
      locale: locale ?? this.locale,
      identifier: identifier ?? this.identifier,
      gender: gender ?? this.gender,
      quality: quality ?? this.quality,
    );
  }
}