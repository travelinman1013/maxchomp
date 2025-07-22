/// Represents the current state of the Text-to-Speech service
enum TTSState {
  /// TTS service is stopped and not playing any audio
  stopped,
  
  /// TTS service is currently playing audio
  playing,
  
  /// TTS service is paused (audio was playing but is temporarily stopped)
  paused,
  
  /// TTS service is in the process of loading or preparing audio
  loading,
  
  /// TTS service encountered an error during operation
  error,
}

/// Extension methods for TTSState enum to provide additional functionality
extension TTSStateExtension on TTSState {
  /// Returns true if the TTS service is currently active (playing or loading)
  bool get isActive => this == TTSState.playing || this == TTSState.loading;
  
  /// Returns true if the TTS service can be played (stopped, paused, or error)
  bool get canPlay => this == TTSState.stopped || this == TTSState.paused || this == TTSState.error;
  
  /// Returns true if the TTS service can be paused (currently playing)
  bool get canPause => this == TTSState.playing;
  
  /// Returns true if the TTS service can be stopped (playing or paused)
  bool get canStop => this == TTSState.playing || this == TTSState.paused;
  
  /// Returns a user-friendly string representation of the TTS state
  String get displayName {
    switch (this) {
      case TTSState.stopped:
        return 'Stopped';
      case TTSState.playing:
        return 'Playing';
      case TTSState.paused:
        return 'Paused';
      case TTSState.loading:
        return 'Loading';
      case TTSState.error:
        return 'Error';
    }
  }
  
  /// Returns an icon name appropriate for the current TTS state (for UI use)
  String get iconName {
    switch (this) {
      case TTSState.stopped:
        return 'play_arrow';
      case TTSState.playing:
        return 'pause';
      case TTSState.paused:
        return 'play_arrow';
      case TTSState.loading:
        return 'hourglass_empty';
      case TTSState.error:
        return 'error';
    }
  }
}