import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/models/voice_model.dart';

/// Service for managing Text-to-Speech functionality using flutter_tts
class TTSService {
  final FlutterTts _flutterTts;
  
  // State management
  TTSState _currentState = TTSState.stopped;
  bool _isInitialized = false;
  
  // Speech parameters
  double _currentSpeechRate = 1.0;
  double _currentVolume = 1.0;
  double _currentPitch = 1.0;
  String _currentLanguage = 'en-US';
  
  // Progress tracking
  String _currentWord = '';
  String _currentSentence = '';
  int _wordStartOffset = 0;
  int _wordEndOffset = 0;
  String _lastError = '';
  
  // Stream controllers for state changes
  final StreamController<TTSState> _stateController = StreamController<TTSState>.broadcast();
  final StreamController<String> _progressController = StreamController<String>.broadcast();
  
  /// Creates a new TTSService instance with optional FlutterTts instance for testing
  TTSService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();
  
  // Getters
  TTSState get currentState => _currentState;
  bool get isInitialized => _isInitialized;
  double get currentSpeechRate => _currentSpeechRate;
  double get currentVolume => _currentVolume;
  double get currentPitch => _currentPitch;
  String get currentLanguage => _currentLanguage;
  String get currentWord => _currentWord;
  String get currentSentence => _currentSentence;
  int get wordStartOffset => _wordStartOffset;
  int get wordEndOffset => _wordEndOffset;
  String get lastError => _lastError;
  
  // Streams
  Stream<TTSState> get stateStream => _stateController.stream;
  Stream<String> get progressStream => _progressController.stream;
  
  /// Initializes the TTS service with default settings and event handlers
  Future<void> initialize() async {
    await _flutterTts.setSpeechRate(_currentSpeechRate);
    await _flutterTts.setVolume(_currentVolume);
    await _flutterTts.setPitch(_currentPitch);
    await _flutterTts.setLanguage(_currentLanguage);
    await _flutterTts.awaitSpeakCompletion(true);
    
    // Set up event handlers
    _flutterTts.setStartHandler(() => onSpeechStart());
    _flutterTts.setCompletionHandler(() => onSpeechComplete());
    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      onSpeechProgress(text, startOffset, endOffset, word);
    });
    _flutterTts.setErrorHandler((dynamic message) => onSpeechError(message.toString()));
    _flutterTts.setCancelHandler(() => onSpeechCancel(''));
    _flutterTts.setPauseHandler(() => onSpeechPause());
    _flutterTts.setContinueHandler(() => onSpeechContinue());
    
    _isInitialized = true;
  }
  
  /// Gets all available voices from the TTS engine
  Future<List<VoiceModel>> getAvailableVoices() async {
    final voices = await _flutterTts.getVoices;
    return voices.map<VoiceModel>((voice) => VoiceModel.fromMap(voice)).toList();
  }
  
  /// Sets the TTS voice by name and locale
  Future<void> setVoice(String name, String locale) async {
    await _flutterTts.setVoice({'name': name, 'locale': locale});
  }
  
  /// Gets the default voice from the TTS engine
  Future<VoiceModel?> getDefaultVoice() async {
    final voice = await _flutterTts.getDefaultVoice;
    if (voice == null) return null;
    return VoiceModel.fromMap(voice);
  }
  
  /// Sets the speech rate (speed) with validation and clamping
  Future<void> setSpeechRate(double rate) async {
    // Clamp to valid range (0.1 to 3.0)
    final clampedRate = rate.clamp(0.1, 3.0);
    _currentSpeechRate = clampedRate;
    await _flutterTts.setSpeechRate(clampedRate);
  }
  
  /// Sets the volume with validation
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    _currentVolume = clampedVolume;
    await _flutterTts.setVolume(clampedVolume);
  }
  
  /// Sets the pitch with validation
  Future<void> setPitch(double pitch) async {
    final clampedPitch = pitch.clamp(0.5, 2.0);
    _currentPitch = clampedPitch;
    await _flutterTts.setPitch(clampedPitch);
  }
  
  /// Speaks the given text
  Future<bool> speak(String text) async {
    final result = await _flutterTts.speak(text);
    return result == 1;
  }
  
  /// Stops the current speech
  Future<bool> stop() async {
    final result = await _flutterTts.stop();
    return result == 1;
  }
  
  /// Pauses the current speech
  Future<bool> pause() async {
    final result = await _flutterTts.pause();
    return result == 1;
  }
  
  /// Gets available languages from the TTS engine
  Future<List<dynamic>> getAvailableLanguages() async {
    return await _flutterTts.getLanguages;
  }
  
  /// Sets the language for TTS
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _flutterTts.setLanguage(language);
  }
  
  /// Checks if a language is available
  Future<bool> isLanguageAvailable(String language) async {
    return await _flutterTts.isLanguageAvailable(language);
  }
  
  // Event handler methods (public for testing)
  void onSpeechStart() {
    _currentState = TTSState.playing;
    _stateController.add(_currentState);
  }
  
  void onSpeechComplete() {
    _currentState = TTSState.stopped;
    _currentWord = '';
    _currentSentence = '';
    _stateController.add(_currentState);
  }
  
  void onSpeechPause() {
    _currentState = TTSState.paused;
    _stateController.add(_currentState);
  }
  
  void onSpeechContinue() {
    _currentState = TTSState.playing;
    _stateController.add(_currentState);
  }
  
  void onSpeechError(String message) {
    _currentState = TTSState.stopped;
    _lastError = message;
    _currentWord = '';
    _currentSentence = '';
    _stateController.add(_currentState);
  }
  
  void onSpeechCancel(String message) {
    _currentState = TTSState.stopped;
    _currentWord = '';
    _currentSentence = '';
    _stateController.add(_currentState);
  }
  
  void onSpeechProgress(String text, int startOffset, int endOffset, String word) {
    _currentSentence = text;
    _currentWord = word;
    _wordStartOffset = startOffset;
    _wordEndOffset = endOffset;
    _progressController.add(word);
  }
  
  /// Disposes of resources and stops any ongoing speech
  Future<void> dispose() async {
    await _flutterTts.stop();
    _currentState = TTSState.stopped;
    await _stateController.close();
    await _progressController.close();
  }
}