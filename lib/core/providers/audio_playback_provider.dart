import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/services/audio_playback_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';

/// Provider for the PDF text extraction service
final pdfTextExtractionServiceProvider = Provider<PDFTextExtractionService>((ref) {
  return PDFTextExtractionService();
});

/// Provider for the audio playback service
final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final ttsService = ref.read(ttsServiceProvider);
  final pdfTextExtractionService = ref.read(pdfTextExtractionServiceProvider);
  
  return AudioPlaybackService(
    ttsService: ttsService,
    pdfTextExtractionService: pdfTextExtractionService,
  );
});

/// State notifier for managing audio playback state
class AudioPlaybackNotifier extends StateNotifier<AudioPlaybackState> {
  final AudioPlaybackService _audioPlaybackService;
  
  AudioPlaybackNotifier(this._audioPlaybackService)
      : super(const AudioPlaybackState());
  
  /// Plays a PDF document
  Future<void> playPDF(PDFDocument document) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );
    
    try {
      final result = await _audioPlaybackService.playPDF(document);
      
      if (result) {
        state = state.copyWith(
          isLoading: false,
          currentDocument: document,
          isPlaying: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to play PDF',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Plays raw text content
  Future<void> playText(String text, {String? sourceId}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );
    
    try {
      final result = await _audioPlaybackService.playText(text);
      
      if (result) {
        state = state.copyWith(
          isLoading: false,
          currentText: text,
          currentSourceId: sourceId,
          isPlaying: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to play text',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Pauses playback
  Future<void> pause() async {
    final result = await _audioPlaybackService.pause();
    if (result) {
      state = state.copyWith(isPaused: true, isPlaying: false);
    }
  }
  
  /// Resumes playback
  Future<void> resume() async {
    final result = await _audioPlaybackService.resume();
    if (result) {
      state = state.copyWith(isPaused: false, isPlaying: true);
    }
  }
  
  /// Stops playback
  Future<void> stop() async {
    final result = await _audioPlaybackService.stop();
    if (result) {
      state = const AudioPlaybackState();
    }
  }
  
  @override
  void dispose() {
    _audioPlaybackService.dispose();
    super.dispose();
  }
}

/// State model for audio playback
class AudioPlaybackState {
  final bool isLoading;
  final bool isPlaying;
  final bool isPaused;
  final PDFDocument? currentDocument;
  final String? currentText;
  final String? currentSourceId;
  final String? error;
  
  const AudioPlaybackState({
    this.isLoading = false,
    this.isPlaying = false,
    this.isPaused = false,
    this.currentDocument,
    this.currentText,
    this.currentSourceId,
    this.error,
  });
  
  bool get hasContent => currentDocument != null || currentText != null;
  
  AudioPlaybackState copyWith({
    bool? isLoading,
    bool? isPlaying,
    bool? isPaused,
    PDFDocument? currentDocument,
    String? currentText,
    String? currentSourceId,
    String? error,
  }) {
    return AudioPlaybackState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      currentDocument: currentDocument ?? this.currentDocument,
      currentText: currentText ?? this.currentText,
      currentSourceId: currentSourceId ?? this.currentSourceId,
      error: error ?? this.error,
    );
  }
}

/// Provider for audio playback state management
final audioPlaybackNotifierProvider =
    StateNotifierProvider<AudioPlaybackNotifier, AudioPlaybackState>((ref) {
  final audioPlaybackService = ref.read(audioPlaybackServiceProvider);
  return AudioPlaybackNotifier(audioPlaybackService);
});

/// Provider to check if audio is currently playing
final isAudioPlayingProvider = Provider<bool>((ref) {
  final state = ref.watch(audioPlaybackNotifierProvider);
  return state.isPlaying;
});

/// Provider to get the current playing document
final currentPlayingDocumentProvider = Provider<PDFDocument?>((ref) {
  final state = ref.watch(audioPlaybackNotifierProvider);
  return state.currentDocument;
});