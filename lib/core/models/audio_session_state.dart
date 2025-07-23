/// Enumeration of possible audio session states
enum AudioSessionState {
  /// Audio session is not active
  inactive,
  
  /// Audio session is active and ready for playback
  active,
  
  /// Audio session is interrupted (phone call, other app took audio focus)
  interrupted,
  
  /// Audio session is deactivating
  deactivating,
  
  /// Audio session encountered an error
  error,
}

/// Extension methods for AudioSessionState
extension AudioSessionStateExtension on AudioSessionState {
  /// Returns true if the audio session can play audio
  bool get canPlay => this == AudioSessionState.active;
  
  /// Returns true if the audio session is in a temporary state
  bool get isTemporary => this == AudioSessionState.interrupted || this == AudioSessionState.deactivating;
  
  /// Returns true if the audio session is in an error state
  bool get hasError => this == AudioSessionState.error;
  
  /// Returns a human-readable description of the state
  String get description {
    switch (this) {
      case AudioSessionState.inactive:
        return 'Audio session is inactive';
      case AudioSessionState.active:
        return 'Audio session is active';
      case AudioSessionState.interrupted:
        return 'Audio session is interrupted';
      case AudioSessionState.deactivating:
        return 'Audio session is deactivating';
      case AudioSessionState.error:
        return 'Audio session has an error';
    }
  }
  
  /// Returns the appropriate icon for the state
  String get iconName {
    switch (this) {
      case AudioSessionState.inactive:
        return 'audio_off';
      case AudioSessionState.active:
        return 'audio_on';
      case AudioSessionState.interrupted:
        return 'pause_circle_outline';
      case AudioSessionState.deactivating:
        return 'stop_circle_outline';
      case AudioSessionState.error:
        return 'error_outline';
    }
  }
}