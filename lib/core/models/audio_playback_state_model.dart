import 'package:just_audio/just_audio.dart';

/// Model representing the state of audio playback
class AudioPlaybackStateModel {
  final bool isPlaying;
  final bool isPaused;
  final bool isLoading;
  final Duration position;
  final Duration? duration;
  final double speed;
  final double volume;
  final String? currentAudioPath;
  final String? currentAudioUrl;
  final String? error;
  final ProcessingState processingState;

  const AudioPlaybackStateModel({
    required this.isPlaying,
    required this.isPaused,
    required this.isLoading,
    required this.position,
    this.duration,
    required this.speed,
    required this.volume,
    this.currentAudioPath,
    this.currentAudioUrl,
    this.error,
    required this.processingState,
  });

  /// Creates a stopped state
  factory AudioPlaybackStateModel.stopped() {
    return const AudioPlaybackStateModel(
      isPlaying: false,
      isPaused: false,
      isLoading: false,
      position: Duration.zero,
      speed: 1.0,
      volume: 1.0,
      processingState: ProcessingState.idle,
    );
  }

  /// Creates a loading state
  factory AudioPlaybackStateModel.loading({
    String? audioPath,
    String? audioUrl,
  }) {
    return AudioPlaybackStateModel(
      isPlaying: false,
      isPaused: false,
      isLoading: true,
      position: Duration.zero,
      speed: 1.0,
      volume: 1.0,
      currentAudioPath: audioPath,
      currentAudioUrl: audioUrl,
      processingState: ProcessingState.loading,
    );
  }

  /// Creates a playing state
  factory AudioPlaybackStateModel.playing({
    required Duration position,
    Duration? duration,
    double speed = 1.0,
    double volume = 1.0,
    String? audioPath,
    String? audioUrl,
  }) {
    return AudioPlaybackStateModel(
      isPlaying: true,
      isPaused: false,
      isLoading: false,
      position: position,
      duration: duration,
      speed: speed,
      volume: volume,
      currentAudioPath: audioPath,
      currentAudioUrl: audioUrl,
      processingState: ProcessingState.ready,
    );
  }

  /// Creates a paused state
  factory AudioPlaybackStateModel.paused({
    required Duration position,
    Duration? duration,
    double speed = 1.0,
    double volume = 1.0,
    String? audioPath,
    String? audioUrl,
  }) {
    return AudioPlaybackStateModel(
      isPlaying: false,
      isPaused: true,
      isLoading: false,
      position: position,
      duration: duration,
      speed: speed,
      volume: volume,
      currentAudioPath: audioPath,
      currentAudioUrl: audioUrl,
      processingState: ProcessingState.ready,
    );
  }

  /// Creates an error state
  factory AudioPlaybackStateModel.error(String errorMessage) {
    return AudioPlaybackStateModel(
      isPlaying: false,
      isPaused: false,
      isLoading: false,
      position: Duration.zero,
      speed: 1.0,
      volume: 1.0,
      error: errorMessage,
      processingState: ProcessingState.idle,
    );
  }

  /// Gets the current audio source (path or URL)
  String? get currentAudioSource => currentAudioPath ?? currentAudioUrl;

  /// Checks if there's currently loaded audio
  bool get hasAudioSource => currentAudioSource != null;

  /// Checks if the player is ready to play
  bool get isReady => processingState == ProcessingState.ready;

  /// Checks if the player has completed playback
  bool get isCompleted => processingState == ProcessingState.completed;

  /// Gets the progress as a percentage (0.0 to 1.0)
  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Creates a copy with updated fields
  AudioPlaybackStateModel copyWith({
    bool? isPlaying,
    bool? isPaused,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    double? speed,
    double? volume,
    String? currentAudioPath,
    String? currentAudioUrl,
    String? error,
    ProcessingState? processingState,
    bool clearError = false,
    bool clearAudioSource = false,
  }) {
    return AudioPlaybackStateModel(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      currentAudioPath: clearAudioSource ? null : (currentAudioPath ?? this.currentAudioPath),
      currentAudioUrl: clearAudioSource ? null : (currentAudioUrl ?? this.currentAudioUrl),
      error: clearError ? null : (error ?? this.error),
      processingState: processingState ?? this.processingState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AudioPlaybackStateModel &&
        other.isPlaying == isPlaying &&
        other.isPaused == isPaused &&
        other.isLoading == isLoading &&
        other.position == position &&
        other.duration == duration &&
        other.speed == speed &&
        other.volume == volume &&
        other.currentAudioPath == currentAudioPath &&
        other.currentAudioUrl == currentAudioUrl &&
        other.error == error &&
        other.processingState == processingState;
  }

  @override
  int get hashCode {
    return Object.hash(
      isPlaying,
      isPaused,
      isLoading,
      position,
      duration,
      speed,
      volume,
      currentAudioPath,
      currentAudioUrl,
      error,
      processingState,
    );
  }

  @override
  String toString() {
    return 'AudioPlaybackStateModel('
        'isPlaying: $isPlaying, '
        'isPaused: $isPaused, '
        'isLoading: $isLoading, '
        'position: $position, '
        'duration: $duration, '
        'speed: $speed, '
        'volume: $volume, '
        'currentAudioSource: $currentAudioSource, '
        'error: $error, '
        'processingState: $processingState'
        ')';
  }
}