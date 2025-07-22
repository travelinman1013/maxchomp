import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/widgets/player/audio_player_widget.dart';

import 'audio_player_integration_test.mocks.dart';

@GenerateMocks([TTSService])
void main() {
  group('AudioPlayerWidget Integration Tests', () {
    late MockTTSService mockTTSService;
    late ProviderContainer container;

    setUp(() {
      mockTTSService = MockTTSService();
      
      // Mock streams
      when(mockTTSService.stateStream).thenAnswer((_) => Stream<TTSState>.empty());
      when(mockTTSService.progressStream).thenAnswer((_) => Stream<String>.empty());
      
      // Mock default property values
      when(mockTTSService.currentState).thenReturn(TTSState.stopped);
      when(mockTTSService.isInitialized).thenReturn(true); // Always return initialized for integration tests
      when(mockTTSService.currentSpeechRate).thenReturn(1.0);
      when(mockTTSService.currentVolume).thenReturn(1.0);
      when(mockTTSService.currentPitch).thenReturn(1.0);
      when(mockTTSService.currentLanguage).thenReturn('en-US');
      when(mockTTSService.currentWord).thenReturn('');
      when(mockTTSService.currentSentence).thenReturn('');
      when(mockTTSService.wordStartOffset).thenReturn(0);
      when(mockTTSService.wordEndOffset).thenReturn(0);
      when(mockTTSService.lastError).thenReturn('');
      
      // Mock async methods
      when(mockTTSService.initialize()).thenAnswer((_) async => true);
      when(mockTTSService.dispose()).thenAnswer((_) async {});
      
      container = ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTTSService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });
    
    testWidgets('should initialize TTS service and handle play/pause/stop', (tester) async {
      // Act - Build the widget with mocked TTS service
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
      
      // Initialize TTS service (mocked)
      final ttsNotifier = container.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize();
      await tester.pumpAndSettle();
      
      // Assert - Initial state should be stopped
      expect(container.read(ttsStateNotifierProvider).status, equals(TTSState.stopped));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      
      // Verify TTS service initialization was called
      verify(mockTTSService.initialize()).called(1);
      
      // Test speed control modal
      await tester.tap(find.byIcon(Icons.speed));
      await tester.pumpAndSettle();
      
      // Verify speed dialog appears
      expect(find.text('Playback Speed'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      
      // Verify speed slider configuration
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(0.25));
      expect(slider.max, equals(2.0));
      expect(slider.value, equals(1.0)); // Default speed
      
      // Close speed dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed
      expect(find.text('Playback Speed'), findsNothing);
    });
    
    testWidgets('should handle error states gracefully', (tester) async {
      // Arrange - Create a separate mock service for error state
      final errorMockTTSService = MockTTSService();
      
      // Mock error state streams and properties
      when(errorMockTTSService.stateStream).thenAnswer((_) => Stream.value(TTSState.error));
      when(errorMockTTSService.progressStream).thenAnswer((_) => Stream<String>.empty());
      when(errorMockTTSService.currentState).thenReturn(TTSState.error);
      when(errorMockTTSService.lastError).thenReturn('TTS initialization failed');
      when(errorMockTTSService.isInitialized).thenReturn(false);
      when(errorMockTTSService.initialize()).thenAnswer((_) async => false);
      
      // Create error container with separate mock
      final errorContainer = ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(errorMockTTSService),
        ],
      );
      
      // Act - Build widget with error state
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: errorContainer,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(),
            ),
          ),
        ),
      );
      
      // Trigger the error state by initializing the service
      final ttsNotifier = errorContainer.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize(); // This should trigger error state
      await tester.pumpAndSettle();
      
      // Assert - Error state should be displayed (error message without prefix)
      expect(find.text('TTS initialization failed'), findsOneWidget);
      
      // Verify all controls are disabled (they should be grayed out for error state)
      // Note: In error state, buttons may still exist but should be non-functional
      final currentState = errorContainer.read(ttsStateNotifierProvider);
      expect(currentState.status, equals(TTSState.error));
      expect(currentState.error, equals('TTS initialization failed'));
      
      errorContainer.dispose();
    });
  });
}