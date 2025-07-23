import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/providers/voice_selection_provider.dart';
import 'package:maxchomp/widgets/voice/voice_list_tile.dart';

class VoiceSelectionPage extends ConsumerWidget {
  const VoiceSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceSelectionStateProvider);
    final selectedVoice = ref.watch(selectedVoiceProvider);
    final previewingVoice = ref.watch(previewingVoiceProvider);
    final notifier = ref.read(voiceSelectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Voice'),
        leading: const BackButton(),
        elevation: 0,
      ),
      body: voiceState.when(
        loading: () => _buildLoadingState(),
        loaded: (voices) => _buildLoadedState(
          context,
          voices,
          selectedVoice,
          previewingVoice,
          notifier,
        ),
        error: (message) => _buildErrorState(context, message, notifier),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.0),
          Text('Loading voices...'),
        ],
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    List<VoiceModel> voices,
    VoiceModel? selectedVoice,
    VoiceModel? previewingVoice,
    VoiceSelectionNotifier notifier,
  ) {
    if (voices.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: voices.length,
      itemBuilder: (context, index) {
        final voice = voices[index];
        final isSelected = selectedVoice?.identifier == voice.identifier;
        final isPreviewing = previewingVoice?.identifier == voice.identifier;

        return VoiceListTile(
          voice: voice,
          isSelected: isSelected,
          isPreviewing: isPreviewing,
          onVoiceSelected: () => _handleVoiceSelection(notifier, voice),
          onPreview: () => _handlePreview(notifier, voice, isPreviewing),
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    VoiceSelectionNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.0,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Error loading voices',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () => notifier.loadVoices(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.voice_over_off,
              size: 64.0,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16.0),
            Text(
              'No voices available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'No text-to-speech voices are currently available on this device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleVoiceSelection(VoiceSelectionNotifier notifier, VoiceModel voice) {
    notifier.selectVoice(voice);
  }

  void _handlePreview(
    VoiceSelectionNotifier notifier,
    VoiceModel voice,
    bool isPreviewing,
  ) {
    if (isPreviewing) {
      notifier.stopPreview();
    } else {
      notifier.previewVoice(voice);
    }
  }
}

// Extension to add pattern matching to VoiceSelectionState
extension VoiceSelectionStatePattern on VoiceSelectionState {
  T when<T>({
    required T Function() loading,
    required T Function(List<VoiceModel> voices) loaded,
    required T Function(String message) error,
  }) {
    return switch (this) {
      VoiceSelectionStateLoading() => loading(),
      VoiceSelectionStateLoaded(:final voices) => loaded(voices),
      VoiceSelectionStateError(:final message) => error(message),
    };
  }
}