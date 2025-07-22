import 'package:maxchomp/core/services/audio_player_service.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/models/tts_state.dart';

/// Enum representing the current playback mode
enum PlaybackMode {
  none,     // No playback active
  tts,      // TTS-based playback (real-time speech synthesis)
  audioFile // Audio file playback (pre-generated audio)
}

/// Enhanced audio playback service that integrates both TTS and audio file playback
/// 
/// This service provides a unified interface for playing audio content using either:
/// - Real-time TTS synthesis (flutter_tts)
/// - Pre-generated audio files (just_audio)
/// 
/// It manages the playback mode and delegates operations to the appropriate service.
class EnhancedAudioPlaybackService {
  final AudioPlayerService audioPlayerService;
  final TTSService ttsService;
  final PDFTextExtractionService pdfTextExtractionService;
  
  // Current playback state
  PlaybackMode _currentPlaybackMode = PlaybackMode.none;
  String? _currentText;
  PDFDocument? _currentDocument;
  
  EnhancedAudioPlaybackService({
    required this.audioPlayerService,
    required this.ttsService,
    required this.pdfTextExtractionService,
  });
  
  // Getters
  PlaybackMode get currentPlaybackMode => _currentPlaybackMode;
  String? get currentText => _currentText;
  PDFDocument? get currentDocument => _currentDocument;
  
  /// Checks if any audio is currently playing
  bool get isPlaying {
    switch (_currentPlaybackMode) {
      case PlaybackMode.tts:
        return ttsService.currentState == TTSState.playing;
      case PlaybackMode.audioFile:
        return audioPlayerService.playbackState.isPlaying;
      case PlaybackMode.none:
        return false;
    }
  }
  
  /// Checks if any audio is currently paused
  bool get isPaused {
    switch (_currentPlaybackMode) {
      case PlaybackMode.tts:
        return ttsService.currentState == TTSState.paused;
      case PlaybackMode.audioFile:
        return audioPlayerService.playbackState.isPaused;
      case PlaybackMode.none:
        return false;
    }
  }
  
  /// Plays a PDF document using TTS
  Future<bool> playPDFWithTTS(PDFDocument document) async {
    if (!ttsService.isInitialized) {
      return false;
    }
    
    try {
      // Extract text from PDF
      final extractionResult = await pdfTextExtractionService.extractTextFromPDF(document, document.file);
      
      if (!extractionResult.isSuccess || !extractionResult.hasText) {
        return false;
      }
      
      // Update state
      _currentDocument = document;
      _currentText = extractionResult.text;
      _currentPlaybackMode = PlaybackMode.tts;
      
      // Start TTS playback
      final result = await ttsService.speak(extractionResult.text);
      
      if (!result) {
        _currentPlaybackMode = PlaybackMode.none;
        _currentDocument = null;
        _currentText = null;
      }
      
      return result;
    } catch (e) {
      _currentPlaybackMode = PlaybackMode.none;
      _currentDocument = null;
      _currentText = null;
      return false;
    }
  }
  
  /// Plays raw text using TTS
  Future<bool> playTextWithTTS(String text) async {
    if (!ttsService.isInitialized) {
      return false;
    }
    
    try {
      // Update state
      _currentText = text;
      _currentDocument = null;
      _currentPlaybackMode = PlaybackMode.tts;
      
      // Start TTS playback
      final result = await ttsService.speak(text);
      
      if (!result) {
        _currentPlaybackMode = PlaybackMode.none;
        _currentText = null;
      }
      
      return result;
    } catch (e) {
      _currentPlaybackMode = PlaybackMode.none;
      _currentText = null;
      return false;
    }
  }
  
  /// Plays an audio file
  Future<void> playAudioFile(String audioPath) async {
    try {
      // Update mode before starting playback
      _currentPlaybackMode = PlaybackMode.audioFile;
      _currentDocument = null;
      _currentText = null;
      
      await audioPlayerService.playAudioFile(audioPath);
    } catch (e) {
      _currentPlaybackMode = PlaybackMode.none;
      rethrow;
    }
  }
  
  /// Plays audio from a URL
  Future<void> playAudioFromUrl(String audioUrl) async {
    try {
      // Update mode before starting playback
      _currentPlaybackMode = PlaybackMode.audioFile;
      _currentDocument = null;
      _currentText = null;
      
      await audioPlayerService.playFromUrl(audioUrl);
    } catch (e) {
      _currentPlaybackMode = PlaybackMode.none;
      rethrow;
    }
  }
  
  /// Pauses the current playback
  Future<bool> pause() async {
    switch (_currentPlaybackMode) {
      case PlaybackMode.tts:
        return await ttsService.pause();
      case PlaybackMode.audioFile:
        try {
          await audioPlayerService.pause();
          return true;
        } catch (e) {
          return false;
        }
      case PlaybackMode.none:
        return false;
    }
  }
  
  /// Resumes the current playback
  Future<bool> resume() async {
    switch (_currentPlaybackMode) {
      case PlaybackMode.tts:
        // For TTS, resume means re-speaking the current text
        if (_currentText != null) {
          return await ttsService.speak(_currentText!);
        }
        return false;
      case PlaybackMode.audioFile:
        try {
          await audioPlayerService.resume();
          return true;
        } catch (e) {
          return false;
        }
      case PlaybackMode.none:
        return false;
    }
  }
  
  /// Stops the current playback
  Future<bool> stop() async {
    final result = switch (_currentPlaybackMode) {
      PlaybackMode.tts => await ttsService.stop(),
      PlaybackMode.audioFile => await _stopAudioFile(),
      PlaybackMode.none => true,
    };
    
    if (result) {
      _currentPlaybackMode = PlaybackMode.none;
      _currentDocument = null;
      _currentText = null;
    }
    
    return result;
  }
  
  /// Helper method to stop audio file playback
  Future<bool> _stopAudioFile() async {
    try {
      await audioPlayerService.stop();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Sets the playback speed
  Future<void> setSpeed(double speed) async {
    switch (_currentPlaybackMode) {
      case PlaybackMode.tts:
        await ttsService.setSpeechRate(speed);
      case PlaybackMode.audioFile:
        await audioPlayerService.setSpeed(speed);
      case PlaybackMode.none:
        // No-op
        break;
    }
  }
  
  /// Sets the playback volume
  Future<void> setVolume(double volume) async {
    switch (_currentPlaybackMode) {
      case PlaybackMode.tts:
        await ttsService.setVolume(volume);
      case PlaybackMode.audioFile:
        await audioPlayerService.setVolume(volume);
      case PlaybackMode.none:
        // No-op
        break;
    }
  }
  
  /// Seeks to a specific position (only supported for audio files)
  Future<void> seek(Duration position) async {
    if (_currentPlaybackMode == PlaybackMode.audioFile) {
      await audioPlayerService.seek(position);
    }
    // TTS doesn't support seeking - would need to be implemented with text chunking
  }
  
  /// Gets the current playback position (only available for audio files)
  Duration get currentPosition {
    if (_currentPlaybackMode == PlaybackMode.audioFile) {
      return audioPlayerService.playbackState.position;
    }
    return Duration.zero;
  }
  
  /// Gets the total duration (only available for audio files)
  Duration? get totalDuration {
    if (_currentPlaybackMode == PlaybackMode.audioFile) {
      return audioPlayerService.playbackState.duration;
    }
    return null;
  }
  
  /// Gets the current playback progress (0.0 to 1.0)
  double get progress {
    if (_currentPlaybackMode == PlaybackMode.audioFile) {
      return audioPlayerService.playbackState.progress;
    }
    return 0.0;
  }
  
  /// Sets the current playback mode (for testing)
  void setCurrentPlaybackMode(PlaybackMode mode) {
    _currentPlaybackMode = mode;
  }
  
  /// Disposes of resources
  void dispose() {
    _currentPlaybackMode = PlaybackMode.none;
    _currentDocument = null;
    _currentText = null;
    // Note: We don't dispose the injected services as they should be managed elsewhere
  }
}