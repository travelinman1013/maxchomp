import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:maxchomp/core/models/audio_playback_state_model.dart';

/// Service for managing audio file playback using just_audio
/// 
/// This service handles audio file playback, providing controls for
/// play, pause, stop, seek, speed, and volume. It works alongside
/// the existing TTS service to support both real-time TTS and 
/// pre-generated audio files.
class AudioPlayerService {
  final AudioPlayer _audioPlayer;
  
  // State management
  AudioPlaybackStateModel _currentState = AudioPlaybackStateModel.stopped();
  
  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  /// Creates a new AudioPlayerService with optional AudioPlayer for testing
  AudioPlayerService({AudioPlayer? audioPlayer}) 
      : _audioPlayer = audioPlayer ?? AudioPlayer();

  // Getters
  AudioPlaybackStateModel get playbackState => _currentState;
  
  // Stream getters that delegate to the underlying AudioPlayer
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Initializes the audio player and sets up state listeners
  void initialize() {
    // Listen to player state changes
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((playerState) {
        _updateStateFromPlayerState(playerState);
      }),
    );

    // Listen to position changes
    _subscriptions.add(
      _audioPlayer.positionStream.listen((position) {
        _currentState = _currentState.copyWith(position: position);
      }),
    );

    // Listen to duration changes
    _subscriptions.add(
      _audioPlayer.durationStream.listen((duration) {
        _currentState = _currentState.copyWith(duration: duration);
      }),
    );
  }

  /// Plays an audio file from the given path
  Future<void> playAudioFile(String audioPath) async {
    try {
      _currentState = AudioPlaybackStateModel.loading(audioPath: audioPath);
      
      final duration = await _audioPlayer.setFilePath(audioPath);
      _currentState = _currentState.copyWith(
        isLoading: false,
        duration: duration,
        currentAudioPath: audioPath,
        clearError: true,
      );
      
      await _audioPlayer.play();
    } catch (e) {
      _currentState = AudioPlaybackStateModel.error('Failed to play audio file: $e');
      rethrow;
    }
  }

  /// Plays audio from a URL
  Future<void> playFromUrl(String audioUrl) async {
    try {
      _currentState = AudioPlaybackStateModel.loading(audioUrl: audioUrl);
      
      final duration = await _audioPlayer.setUrl(audioUrl);
      _currentState = _currentState.copyWith(
        isLoading: false,
        duration: duration,
        currentAudioUrl: audioUrl,
        clearError: true,
      );
      
      await _audioPlayer.play();
    } catch (e) {
      _currentState = AudioPlaybackStateModel.error('Failed to play audio from URL: $e');
      rethrow;
    }
  }

  /// Pauses the current playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _currentState = _currentState.copyWith(error: 'Failed to pause: $e');
      rethrow;
    }
  }

  /// Resumes playback
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      _currentState = _currentState.copyWith(error: 'Failed to resume: $e');
      rethrow;
    }
  }

  /// Stops playback and resets position
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentState = _currentState.copyWith(
        isPlaying: false,
        isPaused: false,
        position: Duration.zero,
      );
    } catch (e) {
      _currentState = _currentState.copyWith(error: 'Failed to stop: $e');
      rethrow;
    }
  }

  /// Seeks to a specific position in the audio
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _currentState = _currentState.copyWith(error: 'Failed to seek: $e');
      rethrow;
    }
  }

  /// Sets the playback speed (0.25x to 2.0x)
  Future<void> setSpeed(double speed) async {
    try {
      // Clamp speed to valid range
      final clampedSpeed = speed.clamp(0.25, 2.0);
      await _audioPlayer.setSpeed(clampedSpeed);
      _currentState = _currentState.copyWith(speed: clampedSpeed);
    } catch (e) {
      _currentState = _currentState.copyWith(error: 'Failed to set speed: $e');
      rethrow;
    }
  }

  /// Sets the volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      // Clamp volume to valid range
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);
      _currentState = _currentState.copyWith(volume: clampedVolume);
    } catch (e) {
      _currentState = _currentState.copyWith(error: 'Failed to set volume: $e');
      rethrow;
    }
  }

  /// Updates the internal state based on PlayerState changes
  void _updateStateFromPlayerState(PlayerState playerState) {
    _currentState = _currentState.copyWith(
      isPlaying: playerState.playing,
      isPaused: !playerState.playing && 
                _currentState.hasAudioSource && 
                playerState.processingState != ProcessingState.completed,
      isLoading: playerState.processingState == ProcessingState.loading,
      processingState: playerState.processingState,
    );
  }

  /// Disposes of the audio player and cancels subscriptions
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Dispose of the audio player
    _audioPlayer.dispose();
    
    // Reset state
    _currentState = AudioPlaybackStateModel.stopped();
  }
}