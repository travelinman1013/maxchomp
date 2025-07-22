import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/core/providers/audio_playback_provider.dart';
import 'package:maxchomp/widgets/player/audio_player_widget.dart';

import 'basic_audio_integration_test.mocks.dart';

@GenerateMocks([TTSService, PDFTextExtractionService])
void main() {
  group('Basic Audio Integration Tests', () {
    late MockTTSService mockTTSService;
    late MockPDFTextExtractionService mockPDFTextExtractionService;
    late ProviderContainer container;

    setUp(() {
      mockTTSService = MockTTSService();
      mockPDFTextExtractionService = MockPDFTextExtractionService();
      
      // Mock setup
      // Removed unused test document setup

      // Setup mock TTS service basic methods
      when(mockTTSService.stateStream).thenAnswer((_) => Stream<TTSState>.empty());
      when(mockTTSService.progressStream).thenAnswer((_) => Stream<String>.empty());
      when(mockTTSService.currentState).thenReturn(TTSState.stopped);
      when(mockTTSService.isInitialized).thenReturn(true);
      when(mockTTSService.initialize()).thenAnswer((_) async => true);
      when(mockTTSService.dispose()).thenAnswer((_) async {});
      
      // Setup default TTS properties
      when(mockTTSService.currentSpeechRate).thenReturn(1.0);
      when(mockTTSService.currentVolume).thenReturn(1.0);
      when(mockTTSService.currentPitch).thenReturn(1.0);
      when(mockTTSService.currentLanguage).thenReturn('en-US');
      when(mockTTSService.currentWord).thenReturn('');
      when(mockTTSService.currentSentence).thenReturn('');
      when(mockTTSService.wordStartOffset).thenReturn(0);
      when(mockTTSService.wordEndOffset).thenReturn(0);
      when(mockTTSService.lastError).thenReturn('');

      // Setup provider container
      container = ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTTSService),
          pdfTextExtractionServiceProvider.overrideWithValue(mockPDFTextExtractionService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should play sample text when no document provided', (tester) async {
      // Arrange - Setup successful TTS for sample text
      when(mockTTSService.speak('This is a sample text for TTS playback.'))
          .thenAnswer((_) async => true);

      // Build the app with audio player widget (no document)
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(),
            ),
          ),
        ),
      );

      // Initialize TTS service
      final ttsNotifier = container.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize();
      await tester.pumpAndSettle();

      // Act - Trigger play button
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
      
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      // Assert - Verify TTS speak was called with sample text
      verify(mockTTSService.speak('This is a sample text for TTS playback.')).called(1);
      
      // Verify audio playback state shows playing
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isTrue);
      expect(audioPlaybackState.currentText, equals('This is a sample text for TTS playback.'));
      expect(audioPlaybackState.error, isNull);
    });

    testWidgets('should play text when provided as parameter', (tester) async {
      // Arrange - Setup successful TTS for custom text
      const customText = 'This is custom text for testing.';
      when(mockTTSService.speak(customText))
          .thenAnswer((_) async => true);

      // Build the app with audio player widget with custom text
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(text: customText, sourceId: 'custom-test'),
            ),
          ),
        ),
      );

      // Initialize TTS service
      final ttsNotifier = container.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize();
      await tester.pumpAndSettle();

      // Act - Trigger play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Assert - Verify TTS speak was called with custom text
      verify(mockTTSService.speak(customText)).called(1);
      
      // Verify audio playback state
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isTrue);
      expect(audioPlaybackState.currentText, equals(customText));
      expect(audioPlaybackState.currentSourceId, equals('custom-test'));
      expect(audioPlaybackState.error, isNull);
    });

    testWidgets('should handle TTS failure gracefully', (tester) async {
      // Arrange - Setup TTS failure
      when(mockTTSService.speak(any)).thenAnswer((_) async => false);

      // Build the app
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(),
            ),
          ),
        ),
      );

      // Initialize TTS
      final ttsNotifier = container.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize();
      await tester.pumpAndSettle();

      // Act - Trigger play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Assert - Verify TTS failure is handled
      verify(mockTTSService.speak(any)).called(1);
      
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isFalse);
      expect(audioPlaybackState.error, equals('Failed to play text'));
    });
  });
}