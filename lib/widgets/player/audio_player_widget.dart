import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tts_state.dart';
import '../../core/models/tts_models.dart';
import '../../core/providers/tts_provider.dart';

/// Material 3 audio player widget for MaxChomp TTS playback
/// 
/// Provides play/pause/stop controls, progress display, and speed adjustment
/// following Material Design 3 specifications and accessibility guidelines.
class AudioPlayerWidget extends ConsumerWidget {
  const AudioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsState = ref.watch(ttsStateNotifierProvider);
    final ttsProgress = ref.watch(ttsProgressNotifierProvider);
    final ttsSettings = ref.watch(ttsSettingsNotifierProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1.0, // Material 3 subtle elevation
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error state display
            if (ttsState.status == TTSState.error) ...[
              _buildErrorState(context, ttsState.error),
              const SizedBox(height: 16.0),
            ],

            // Progress display
            if (ttsProgress.hasProgress) ...[
              _buildProgressDisplay(context, ttsProgress),
              const SizedBox(height: 16.0),
            ],

            // Player controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play/Pause button
                _buildPlayPauseButton(context, ref, ttsState),
                
                // Stop button
                _buildStopButton(context, ref, ttsState),
                
                // Speed control button
                _buildSpeedButton(context, ref, ttsSettings),
              ],
            ),

            // Text display (if playing/paused and there's a current sentence)
            if (ttsProgress.currentSentence.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildTextDisplay(context, ttsProgress.currentSentence, ttsProgress),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String? errorMessage) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              errorMessage ?? 'TTS error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDisplay(BuildContext context, TTSProgressModel progress) {
    final theme = Theme.of(context);
    final percentage = (progress.progressPercentage * 100).round();
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress.progressPercentage,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current: ${progress.currentWord}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, WidgetRef ref, TTSStateModel state) {
    final theme = Theme.of(context);
    final isPlaying = state.status == TTSState.playing;
    final isError = state.status == TTSState.error;
    
    return Semantics(
      label: isPlaying ? 'Pause audio' : 'Play audio',
      child: IconButton(
        onPressed: isError ? null : () => _handlePlayPause(ref, isPlaying),
        iconSize: 48.0,
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: isError ? theme.disabledColor : theme.colorScheme.primary,
        ),
        tooltip: isPlaying ? 'Pause audio' : 'Play audio',
      ),
    );
  }

  Widget _buildStopButton(BuildContext context, WidgetRef ref, TTSStateModel state) {
    final theme = Theme.of(context);
    final isError = state.status == TTSState.error;
    final canStop = state.status == TTSState.playing || state.status == TTSState.paused;
    
    return Semantics(
      label: 'Stop audio',
      child: IconButton(
        onPressed: (isError || !canStop) ? null : () => _handleStop(ref),
        iconSize: 48.0,
        icon: Icon(
          Icons.stop,
          color: (isError || !canStop) ? theme.disabledColor : theme.colorScheme.primary,
        ),
        tooltip: 'Stop audio',
      ),
    );
  }

  Widget _buildSpeedButton(BuildContext context, WidgetRef ref, TTSSettingsModel settings) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Adjust playback speed',
          child: IconButton(
            onPressed: () => _showSpeedDialog(context, ref, settings),
            iconSize: 32.0,
            icon: Icon(
              Icons.speed,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Adjust playback speed',
          ),
        ),
        Text(
          '${settings.speechRate}x',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTextDisplay(BuildContext context, String text, TTSProgressModel progress) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _handlePlayPause(WidgetRef ref, bool isPlaying) {
    final notifier = ref.read(ttsStateNotifierProvider.notifier);
    if (isPlaying) {
      // TODO: Implement pause functionality
      // notifier.pause();
    } else {
      // TODO: Implement play/resume functionality  
      // notifier.speak('Sample text');
    }
  }

  void _handleStop(WidgetRef ref) {
    final notifier = ref.read(ttsStateNotifierProvider.notifier);
    // TODO: Implement stop functionality
    // notifier.stop();
  }

  void _showSpeedDialog(BuildContext context, WidgetRef ref, TTSSettingsModel settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return _SpeedSelectionSheet(
          currentSpeed: settings.speechRate,
          onSpeedChanged: (double newSpeed) {
            final notifier = ref.read(ttsSettingsNotifierProvider.notifier);
            // TODO: Implement speed change functionality
            // notifier.updateSpeechRate(newSpeed);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

/// Modal bottom sheet for speed selection
class _SpeedSelectionSheet extends StatefulWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  const _SpeedSelectionSheet({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<_SpeedSelectionSheet> createState() => _SpeedSelectionSheetState();
}

class _SpeedSelectionSheetState extends State<_SpeedSelectionSheet> {
  late double _selectedSpeed;

  @override
  void initState() {
    super.initState();
    _selectedSpeed = widget.currentSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),

          // Title
          Text(
            'Playback Speed',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24.0),

          // Speed slider
          Slider(
            value: _selectedSpeed,
            min: 0.25,
            max: 2.0,
            divisions: 7, // 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
            label: '${_selectedSpeed}x',
            onChanged: (double value) {
              setState(() {
                _selectedSpeed = value;
              });
            },
          ),

          // Speed value display
          Text(
            '${_selectedSpeed}x',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24.0),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onSpeedChanged(_selectedSpeed),
              child: const Text('Apply'),
            ),
          ),
          const SizedBox(height: 8.0),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}