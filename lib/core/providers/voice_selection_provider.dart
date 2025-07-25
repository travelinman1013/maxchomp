import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/core/providers/remote_config_provider.dart';
import 'package:maxchomp/core/providers/analytics_provider.dart';
import 'package:maxchomp/core/models/settings_model.dart';

// Voice Selection State
sealed class VoiceSelectionState {
  const VoiceSelectionState();
  
  const factory VoiceSelectionState.loading() = VoiceSelectionStateLoading;
  const factory VoiceSelectionState.loaded(List<VoiceModel> voices) = VoiceSelectionStateLoaded;
  const factory VoiceSelectionState.error(String message) = VoiceSelectionStateError;
}

class VoiceSelectionStateLoading extends VoiceSelectionState {
  const VoiceSelectionStateLoading();
}

class VoiceSelectionStateLoaded extends VoiceSelectionState {
  final List<VoiceModel> voices;
  
  const VoiceSelectionStateLoaded(this.voices);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceSelectionStateLoaded && 
      runtimeType == other.runtimeType &&
      voices == other.voices;

  @override
  int get hashCode => voices.hashCode;
}

class VoiceSelectionStateError extends VoiceSelectionState {
  final String message;
  
  const VoiceSelectionStateError(this.message);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceSelectionStateError && 
      runtimeType == other.runtimeType &&
      message == other.message;

  @override
  int get hashCode => message.hashCode;
}

// Voice Selection Notifier State
class VoiceSelectionNotifierState {
  final VoiceSelectionState voiceSelectionState;
  final VoiceModel? selectedVoice;
  final VoiceModel? previewingVoice;

  const VoiceSelectionNotifierState({
    required this.voiceSelectionState,
    this.selectedVoice,
    this.previewingVoice,
  });

  VoiceSelectionNotifierState copyWith({
    VoiceSelectionState? voiceSelectionState,
    VoiceModel? selectedVoice,
    VoiceModel? previewingVoice,
    bool clearPreviewingVoice = false,
  }) {
    return VoiceSelectionNotifierState(
      voiceSelectionState: voiceSelectionState ?? this.voiceSelectionState,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      previewingVoice: clearPreviewingVoice ? null : (previewingVoice ?? this.previewingVoice),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceSelectionNotifierState &&
      runtimeType == other.runtimeType &&
      voiceSelectionState == other.voiceSelectionState &&
      selectedVoice == other.selectedVoice &&
      previewingVoice == other.previewingVoice;

  @override
  int get hashCode =>
      voiceSelectionState.hashCode ^
      selectedVoice.hashCode ^
      previewingVoice.hashCode;
}

// Voice Selection Notifier
class VoiceSelectionNotifier extends StateNotifier<VoiceSelectionNotifierState> {
  final TTSService _ttsService;
  final SettingsNotifier _settingsNotifier;
  final AnalyticsService _analytics;
  final Ref _ref;

  VoiceSelectionNotifier(
    this._ttsService, 
    this._settingsNotifier, 
    this._analytics,
    this._ref,
  ) : super(const VoiceSelectionNotifierState(
          voiceSelectionState: VoiceSelectionState.loading(),
        )) {
    loadVoices();
  }

  Future<void> loadVoices() async {
    state = state.copyWith(
      voiceSelectionState: const VoiceSelectionState.loading(),
    );

    try {
      final voices = await _ttsService.getAvailableVoices();
      state = state.copyWith(
        voiceSelectionState: VoiceSelectionState.loaded(voices),
      );
    } catch (e) {
      state = state.copyWith(
        voiceSelectionState: VoiceSelectionState.error(e.toString()),
      );
    }
  }

  Future<void> selectVoice(VoiceModel voice) async {
    try {
      // Track voice selection analytics
      await _analytics.trackVoiceSelection(
        action: 'selected',
        voiceId: voice.identifier,
        voiceName: voice.name,
        voiceLocale: voice.locale,
      );

      await _ttsService.setVoice(voice.name, voice.locale);
      
      // Update state
      state = state.copyWith(selectedVoice: voice);
      
      // Persist to settings
      await _settingsNotifier.updateVoiceSettings(
        VoiceSettings(
          selectedVoiceId: voice.identifier,
          selectedVoiceName: voice.name,
          selectedVoiceLocale: voice.locale,
        ),
      );
    } catch (e) {
      // Don't update state on error
      // Could emit error state or show snackbar here
    }
  }

  Future<void> previewVoice(VoiceModel voice, {String? previewText}) async {
    try {
      // Check if voice preview is enabled via remote config
      final isVoicePreviewEnabled = _ref.read(isVoicePreviewEnabledRemoteProvider);
      if (!isVoicePreviewEnabled) {
        return; // Preview disabled via remote config
      }

      // Track voice preview analytics
      await _analytics.trackVoiceSelection(
        action: 'preview_played',
        voiceId: voice.identifier,
        voiceName: voice.name,
        voiceLocale: voice.locale,
        isPreview: true,
      );

      // Stop current preview if any
      if (state.previewingVoice != null) {
        await _ttsService.stop();
      }

      // Set the voice for preview
      await _ttsService.setVoice(voice.name, voice.locale);
      
      // Update state to show we're previewing
      state = state.copyWith(previewingVoice: voice);
      
      // Speak the preview text
      final textToSpeak = previewText ?? 'Hello, this is a voice preview.';
      await _ttsService.speak(textToSpeak);
      
    } catch (e) {
      // Clear previewing state on error
      state = state.copyWith(clearPreviewingVoice: true);
    }
  }

  Future<void> stopPreview() async {
    try {
      await _ttsService.stop();
    } catch (e) {
      // Continue with state cleanup even if stop fails
    } finally {
      // Always clear the previewing state
      state = state.copyWith(clearPreviewingVoice: true);
    }
  }
}

// Provider
final voiceSelectionProvider = StateNotifierProvider<VoiceSelectionNotifier, VoiceSelectionNotifierState>((ref) {
  final ttsService = ref.watch(ttsServiceProvider);
  final settingsNotifier = ref.watch(settingsProvider.notifier);
  final analytics = ref.watch(analyticsProvider);
  
  // Track voice selection opened analytics
  analytics.trackVoiceSelection(action: 'opened');
  
  return VoiceSelectionNotifier(ttsService, settingsNotifier, analytics, ref);
});

// Helper providers for easy access
final voiceSelectionStateProvider = Provider<VoiceSelectionState>((ref) {
  return ref.watch(voiceSelectionProvider).voiceSelectionState;
});

final selectedVoiceProvider = Provider<VoiceModel?>((ref) {
  return ref.watch(voiceSelectionProvider).selectedVoice;
});

final previewingVoiceProvider = Provider<VoiceModel?>((ref) {
  return ref.watch(voiceSelectionProvider).previewingVoice;
});

/// Provider that combines local settings with remote config for voice preview
final effectiveVoicePreviewEnabledProvider = Provider<bool>((ref) {
  final localSetting = ref.watch(isVoicePreviewEnabledProvider);
  final remoteSetting = ref.watch(isVoicePreviewEnabledRemoteProvider);
  
  // Remote config can disable the feature, but if remote allows it, defer to local setting
  return remoteSetting && localSetting;
});

/// Provider for effective speech rate with remote config limits
final effectiveSpeechRateProvider = Provider<double>((ref) {
  final localRate = ref.watch(settingsProvider).defaultSpeechRate;
  final limits = ref.watch(speechRateLimitsProvider);
  
  // Clamp the local rate within remote config limits
  return localRate.clamp(limits.min, limits.max);
});