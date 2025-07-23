import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/models/text_extraction_result.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/services/audio_playback_service.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/providers/audio_playback_provider.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/widgets/player/audio_player_widget.dart';

import 'pdf_to_audio_integration_test.mocks.dart';

@GenerateMocks([TTSService, PDFTextExtractionService])
void main() {
  group('PDF to Audio Integration Tests', () {
    late MockTTSService mockTTSService;
    late MockPDFTextExtractionService mockPDFTextExtractionService;
    late AudioPlaybackService audioPlaybackService;
    late ProviderContainer container;
    late PDFDocument testDocument;
    late StreamController<TTSState> stateController;

    setUp(() {
      mockTTSService = MockTTSService();
      mockPDFTextExtractionService = MockPDFTextExtractionService();
      
      // Setup test document
      testDocument = PDFDocument(
        id: 'test-pdf-id',
        fileName: 'test-document.pdf',
        filePath: '/test/path/test-document.pdf',
        fileSize: 2048,
        importedAt: DateTime.now(),
        status: DocumentStatus.ready,
        totalPages: 5,
      );

      // Setup realistic mock TTS service with state changes and stream
      var currentState = TTSState.stopped;
      stateController = StreamController<TTSState>.broadcast();
      
      when(mockTTSService.stateStream).thenAnswer((_) => stateController.stream);
      when(mockTTSService.progressStream).thenAnswer((_) => Stream<String>.empty());
      when(mockTTSService.currentState).thenAnswer((_) => currentState);
      when(mockTTSService.isInitialized).thenReturn(true);
      when(mockTTSService.initialize()).thenAnswer((_) async => true);
      when(mockTTSService.speak(any)).thenAnswer((_) async {
        currentState = TTSState.playing;
        stateController.add(TTSState.playing);
        return true;
      });
      when(mockTTSService.pause()).thenAnswer((_) async {
        currentState = TTSState.paused;
        stateController.add(TTSState.paused);
        return true;
      });
      when(mockTTSService.stop()).thenAnswer((_) async {
        currentState = TTSState.stopped;
        stateController.add(TTSState.stopped);
        return true;
      });
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

      // Create audio playback service
      audioPlaybackService = AudioPlaybackService(
        ttsService: mockTTSService,
        pdfTextExtractionService: mockPDFTextExtractionService,
      );

      // Setup provider container with all mocks
      container = ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTTSService),
          pdfTextExtractionServiceProvider.overrideWithValue(mockPDFTextExtractionService),
          audioPlaybackServiceProvider.overrideWithValue(audioPlaybackService),
        ],
      );
    });

    tearDown(() {
      container.dispose();  
      stateController.close();
    });

    testWidgets('should complete full PDF to audio pipeline successfully', (tester) async {
      // Arrange - Setup successful text extraction
      final extractionResult = TextExtractionResult.success(
        text: 'This is the extracted text from the PDF document. It contains multiple sentences for testing.',
        pageTexts: ['This is the extracted text from the PDF document. It contains multiple sentences for testing.'],
        metadata: {
          'title': 'Test Document',
          'author': 'Test Author',
          'creationDate': DateTime.now().toIso8601String(),
        },
      );
      
      when(mockPDFTextExtractionService.extractTextFromPDF(any, any))
          .thenAnswer((_) async => extractionResult);

      // Build the app with audio player widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(document: testDocument),
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

      // Assert - Verify the complete pipeline was executed
      // 1. PDF text extraction was called
      verify(mockPDFTextExtractionService.extractTextFromPDF(any, any)).called(1);
      
      // 2. TTS speak was called with extracted text
      verify(mockTTSService.speak(extractionResult.text)).called(1);
      
      // 3. Audio playback state shows playing
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isTrue);
      expect(audioPlaybackState.currentDocument, equals(testDocument));
      expect(audioPlaybackState.error, isNull);
    });

    testWidgets('should handle PDF text extraction failure gracefully', (tester) async {
      // Arrange - Setup failed text extraction
      final extractionResult = TextExtractionResult.failure(
        error: 'Failed to extract text from PDF',
      );
      
      when(mockPDFTextExtractionService.extractTextFromPDF(any, any))
          .thenAnswer((_) async => extractionResult);

      // Build the app with audio player widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(document: testDocument),
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

      // Assert - Verify error handling
      // 1. PDF text extraction was attempted
      verify(mockPDFTextExtractionService.extractTextFromPDF(any, any)).called(1);
      
      // 2. TTS speak was NOT called due to extraction failure
      verifyNever(mockTTSService.speak(any));
      
      // 3. Audio playback state shows failure
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isFalse);
      expect(audioPlaybackState.error, equals('Failed to play PDF'));
    });

    testWidgets('should handle TTS service failure during playback', (tester) async {
      // Arrange - Setup successful text extraction but TTS failure
      final extractionResult = TextExtractionResult.success(
        text: 'This is test text that will fail to play.',
        pageTexts: ['This is test text that will fail to play.'],
        metadata: {
          'title': 'Test Document',
          'author': 'Test Author',
          'creationDate': DateTime.now().toIso8601String(),
        },
      );
      
      when(mockPDFTextExtractionService.extractTextFromPDF(any, any))
          .thenAnswer((_) async => extractionResult);
      
      // Make TTS speak fail
      when(mockTTSService.speak(any)).thenAnswer((_) async => false);

      // Build the app with audio player widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(document: testDocument),
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
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      // Assert - Verify TTS failure handling
      // 1. Text extraction succeeded
      verify(mockPDFTextExtractionService.extractTextFromPDF(any, any)).called(1);
      
      // 2. TTS speak was attempted but failed
      verify(mockTTSService.speak(extractionResult.text)).called(1);
      
      // 3. Audio playback state shows failure
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isFalse);
      expect(audioPlaybackState.error, equals('Failed to play PDF'));
    });

    testWidgets('should support pause and resume functionality', (tester) async {
      // Arrange - Setup successful pipeline
      final extractionResult = TextExtractionResult.success(
        text: 'This is text that can be paused and resumed.',
        pageTexts: ['This is text that can be paused and resumed.'],
        metadata: {'title': 'Test Document', 'author': 'Test Author', 'creationDate': DateTime.now().toIso8601String()},
      );
      
      when(mockPDFTextExtractionService.extractTextFromPDF(any, any))
          .thenAnswer((_) async => extractionResult);

      // Build the app
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(document: testDocument),
            ),
          ),
        ),
      );

      // Initialize and start playback
      final ttsNotifier = container.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize();
      await tester.pumpAndSettle();

      // Start playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Act & Assert - Test pause  
      expect(container.read(audioPlaybackNotifierProvider).isPlaying, isTrue);
      
      // Find and tap pause button - should be available since TTS is now playing
      final pauseButton = find.byIcon(Icons.pause);
      expect(pauseButton, findsOneWidget);
      
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Verify pause was called
      verify(mockTTSService.pause()).called(1);
      
      // Test resume by tapping play again  
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Should call resume since there's existing content
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.hasContent, isTrue);
    });

    testWidgets('should support stop functionality and clear state', (tester) async {
      // Arrange - Setup successful pipeline
      final extractionResult = TextExtractionResult.success(
        text: 'This text will be stopped.',
        pageTexts: ['This text will be stopped.'],
        metadata: {'title': 'Test Document', 'author': 'Test Author', 'creationDate': DateTime.now().toIso8601String()},
      );
      
      when(mockPDFTextExtractionService.extractTextFromPDF(any, any))
          .thenAnswer((_) async => extractionResult);

      // Build the app
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AudioPlayerWidget(document: testDocument),
            ),
          ),
        ),
      );

      // Initialize and start playback
      final ttsNotifier = container.read(ttsStateNotifierProvider.notifier);
      await ttsNotifier.initialize();
      await tester.pumpAndSettle();

      // Start playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Act - Tap stop button (should be enabled since TTS is playing)
      final stopButton = find.byIcon(Icons.stop);
      expect(stopButton, findsOneWidget);
      
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      // Assert - Verify stop was called and state cleared
      verify(mockTTSService.stop()).called(1);
      
      final audioPlaybackState = container.read(audioPlaybackNotifierProvider);
      expect(audioPlaybackState.isPlaying, isFalse);
      expect(audioPlaybackState.isPaused, isFalse);
      expect(audioPlaybackState.currentDocument, isNull);
    });
  });
}