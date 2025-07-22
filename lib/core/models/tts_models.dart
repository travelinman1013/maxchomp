import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/models/voice_model.dart';

/// Represents the current state of the TTS system including playback status
class TTSStateModel {
  /// Current TTS playback state
  final TTSState status;
  
  /// Whether the TTS service has been initialized
  final bool isInitialized;
  
  /// Last error message if any error occurred
  final String? error;
  
  /// Creates a new TTSStateModel instance
  const TTSStateModel({
    required this.status,
    required this.isInitialized,
    this.error,
  });
  
  /// Creates a copy of this TTSStateModel with optionally updated fields
  TTSStateModel copyWith({
    TTSState? status,
    bool? isInitialized,
    String? error,
  }) {
    return TTSStateModel(
      status: status ?? this.status,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
  
  /// Returns true if the TTS is currently active (playing or loading)
  bool get isActive => status.isActive;
  
  /// Returns true if TTS can be played
  bool get canPlay => status.canPlay && isInitialized;
  
  /// Returns true if TTS can be paused
  bool get canPause => status.canPause;
  
  /// Returns true if TTS can be stopped
  bool get canStop => status.canStop;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TTSStateModel &&
        other.status == status &&
        other.isInitialized == isInitialized &&
        other.error == error;
  }
  
  @override
  int get hashCode => status.hashCode ^ isInitialized.hashCode ^ error.hashCode;
  
  @override
  String toString() {
    return 'TTSStateModel(status: $status, isInitialized: $isInitialized, error: $error)';
  }
}

/// Represents TTS settings and configuration
class TTSSettingsModel {
  /// Speech rate/speed (0.1 to 3.0)
  final double speechRate;
  
  /// Volume level (0.0 to 1.0)
  final double volume;
  
  /// Voice pitch (0.5 to 2.0)
  final double pitch;
  
  /// Selected language code (e.g., 'en-US')
  final String language;
  
  /// Currently selected voice
  final VoiceModel? selectedVoice;
  
  /// Creates a new TTSSettingsModel instance
  const TTSSettingsModel({
    required this.speechRate,
    required this.volume,
    required this.pitch,
    required this.language,
    this.selectedVoice,
  });
  
  /// Creates a copy of this TTSSettingsModel with optionally updated fields
  TTSSettingsModel copyWith({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
    VoiceModel? selectedVoice,
  }) {
    return TTSSettingsModel(
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
      selectedVoice: selectedVoice ?? this.selectedVoice,
    );
  }
  
  /// Default TTS settings
  static const TTSSettingsModel defaultSettings = TTSSettingsModel(
    speechRate: 1.0,
    volume: 1.0,
    pitch: 1.0,
    language: 'en-US',
    selectedVoice: null,
  );
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TTSSettingsModel &&
        other.speechRate == speechRate &&
        other.volume == volume &&
        other.pitch == pitch &&
        other.language == language &&
        other.selectedVoice == selectedVoice;
  }
  
  @override
  int get hashCode {
    return speechRate.hashCode ^
        volume.hashCode ^
        pitch.hashCode ^
        language.hashCode ^
        selectedVoice.hashCode;
  }
  
  @override
  String toString() {
    return 'TTSSettingsModel(speechRate: $speechRate, volume: $volume, pitch: $pitch, language: $language, selectedVoice: $selectedVoice)';
  }
}

/// Represents TTS progress information during speech playback
class TTSProgressModel {
  /// Currently spoken word
  final String currentWord;
  
  /// Current sentence being spoken
  final String currentSentence;
  
  /// Start offset of current word in the text
  final int wordStartOffset;
  
  /// End offset of current word in the text
  final int wordEndOffset;
  
  /// Creates a new TTSProgressModel instance
  const TTSProgressModel({
    required this.currentWord,
    required this.currentSentence,
    required this.wordStartOffset,
    required this.wordEndOffset,
  });
  
  /// Creates a copy of this TTSProgressModel with optionally updated fields
  TTSProgressModel copyWith({
    String? currentWord,
    String? currentSentence,
    int? wordStartOffset,
    int? wordEndOffset,
  }) {
    return TTSProgressModel(
      currentWord: currentWord ?? this.currentWord,
      currentSentence: currentSentence ?? this.currentSentence,
      wordStartOffset: wordStartOffset ?? this.wordStartOffset,
      wordEndOffset: wordEndOffset ?? this.wordEndOffset,
    );
  }
  
  /// Empty progress state
  static const TTSProgressModel empty = TTSProgressModel(
    currentWord: '',
    currentSentence: '',
    wordStartOffset: 0,
    wordEndOffset: 0,
  );
  
  /// Returns true if there is active progress (word being spoken)
  bool get hasProgress => currentWord.isNotEmpty;
  
  /// Returns the progress as a percentage (0.0 to 1.0) based on word position in sentence
  double get progressPercentage {
    if (currentSentence.isEmpty || wordEndOffset <= wordStartOffset) {
      return 0.0;
    }
    return wordEndOffset / currentSentence.length;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TTSProgressModel &&
        other.currentWord == currentWord &&
        other.currentSentence == currentSentence &&
        other.wordStartOffset == wordStartOffset &&
        other.wordEndOffset == wordEndOffset;
  }
  
  @override
  int get hashCode {
    return currentWord.hashCode ^
        currentSentence.hashCode ^
        wordStartOffset.hashCode ^
        wordEndOffset.hashCode;
  }
  
  @override
  String toString() {
    return 'TTSProgressModel(currentWord: $currentWord, currentSentence: $currentSentence, wordStartOffset: $wordStartOffset, wordEndOffset: $wordEndOffset)';
  }
}