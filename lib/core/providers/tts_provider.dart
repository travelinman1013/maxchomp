import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/models/tts_models.dart';
import 'package:maxchomp/core/models/voice_model.dart';

/// Provider for the TTS service instance
final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

/// State notifier for TTS playback state
class TTSStateNotifier extends StateNotifier<TTSStateModel> {
  final TTSService _ttsService;
  StreamSubscription<TTSState>? _stateSubscription;

  TTSStateNotifier(this._ttsService)
      : super(TTSStateModel(
          status: _ttsService.currentState,
          isInitialized: _ttsService.isInitialized,
        )) {
    // Listen to TTS state changes
    _stateSubscription = _ttsService.stateStream.listen((ttsState) {
      state = state.copyWith(
        status: ttsState,
        error: ttsState == TTSState.error ? _ttsService.lastError : null,
      );
    });
  }

  /// Initialize the TTS service
  Future<void> initialize() async {
    try {
      await _ttsService.initialize();
      state = state.copyWith(
        isInitialized: _ttsService.isInitialized,
        status: _ttsService.currentState,
      );
    } catch (e) {
      state = state.copyWith(
        status: TTSState.error,
        error: e.toString(),
      );
    }
  }

  /// Speak the given text
  Future<bool> speak(String text) async {
    try {
      final result = await _ttsService.speak(text);
      state = state.copyWith(
        status: _ttsService.currentState,
        error: result ? null : 'Failed to speak text',
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        status: TTSState.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Stop TTS playback
  Future<bool> stop() async {
    try {
      final result = await _ttsService.stop();
      state = state.copyWith(
        status: _ttsService.currentState,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        status: TTSState.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Pause TTS playback
  Future<bool> pause() async {
    try {
      final result = await _ttsService.pause();
      state = state.copyWith(
        status: _ttsService.currentState,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        status: TTSState.error,
        error: e.toString(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _ttsService.dispose();
    super.dispose();
  }
}

/// Provider for TTS state management
final ttsStateNotifierProvider =
    StateNotifierProvider<TTSStateNotifier, TTSStateModel>((ref) {
  final ttsService = ref.read(ttsServiceProvider);
  return TTSStateNotifier(ttsService);
});

/// State notifier for TTS settings
class TTSSettingsNotifier extends StateNotifier<TTSSettingsModel> {
  final TTSService _ttsService;

  TTSSettingsNotifier(this._ttsService) : super(TTSSettingsModel.defaultSettings);

  /// Update speech rate
  Future<void> updateSpeechRate(double rate) async {
    try {
      await _ttsService.setSpeechRate(rate);
      state = state.copyWith(speechRate: _ttsService.currentSpeechRate);
    } catch (e) {
      // Handle error silently or emit to error stream
    }
  }

  /// Update volume
  Future<void> updateVolume(double volume) async {
    try {
      await _ttsService.setVolume(volume);
      state = state.copyWith(volume: _ttsService.currentVolume);
    } catch (e) {
      // Handle error silently or emit to error stream
    }
  }

  /// Update pitch
  Future<void> updatePitch(double pitch) async {
    try {
      await _ttsService.setPitch(pitch);
      state = state.copyWith(pitch: _ttsService.currentPitch);
    } catch (e) {
      // Handle error silently or emit to error stream
    }
  }

  /// Update language
  Future<void> updateLanguage(String language) async {
    try {
      await _ttsService.setLanguage(language);
      state = state.copyWith(language: _ttsService.currentLanguage);
    } catch (e) {
      // Handle error silently or emit to error stream
    }
  }

  /// Update selected voice
  Future<void> updateSelectedVoice(VoiceModel voice) async {
    try {
      await _ttsService.setVoice(voice.name, voice.locale);
      state = state.copyWith(selectedVoice: voice);
    } catch (e) {
      // Handle error silently or emit to error stream
    }
  }
}

/// Provider for TTS settings management
final ttsSettingsNotifierProvider =
    StateNotifierProvider<TTSSettingsNotifier, TTSSettingsModel>((ref) {
  final ttsService = ref.read(ttsServiceProvider);
  return TTSSettingsNotifier(ttsService);
});

/// Provider for available voices
final availableVoicesProvider = FutureProvider<List<VoiceModel>>((ref) async {
  final ttsService = ref.read(ttsServiceProvider);
  return await ttsService.getAvailableVoices();
});

/// Provider for available languages
final availableLanguagesProvider = FutureProvider<List<dynamic>>((ref) async {
  final ttsService = ref.read(ttsServiceProvider);
  return await ttsService.getAvailableLanguages();
});

/// State notifier for TTS progress tracking
class TTSProgressNotifier extends StateNotifier<TTSProgressModel> {
  final TTSService _ttsService;
  StreamSubscription<String>? _progressSubscription;

  TTSProgressNotifier(this._ttsService) : super(TTSProgressModel.empty) {
    // Listen to progress updates
    _progressSubscription = _ttsService.progressStream.listen((word) {
      updateFromService(_ttsService);
    });
  }

  /// Update progress from TTS service
  void updateFromService(TTSService service) {
    state = TTSProgressModel(
      currentWord: service.currentWord,
      currentSentence: service.currentSentence,
      wordStartOffset: service.wordStartOffset,
      wordEndOffset: service.wordEndOffset,
    );
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for TTS progress tracking
final ttsProgressNotifierProvider =
    StateNotifierProvider<TTSProgressNotifier, TTSProgressModel>((ref) {
  final ttsService = ref.read(ttsServiceProvider);
  return TTSProgressNotifier(ttsService);
});

/// Provider to check if a specific language is available
final isLanguageAvailableProvider = FutureProvider.family<bool, String>((ref, language) async {
  final ttsService = ref.read(ttsServiceProvider);
  return await ttsService.isLanguageAvailable(language);
});