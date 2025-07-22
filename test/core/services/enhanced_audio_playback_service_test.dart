import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:maxchomp/core/services/enhanced_audio_playback_service.dart';
import 'package:maxchomp/core/services/audio_player_service.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/models/text_extraction_result.dart';
import 'package:maxchomp/core/models/audio_playback_state_model.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'dart:io';

import 'enhanced_audio_playback_service_test.mocks.dart';

@GenerateMocks([AudioPlayerService, TTSService, PDFTextExtractionService])
void main() {
  group('EnhancedAudioPlaybackService Tests', () {
    late EnhancedAudioPlaybackService enhancedAudioService;
    late MockAudioPlayerService mockAudioPlayerService;
    late MockTTSService mockTTSService;
    late MockPDFTextExtractionService mockPDFTextExtractionService;

    setUp(() {
      mockAudioPlayerService = MockAudioPlayerService();
      mockTTSService = MockTTSService();
      mockPDFTextExtractionService = MockPDFTextExtractionService();
      
      // Set up default mocks
      when(mockTTSService.isInitialized).thenReturn(true);
      when(mockTTSService.currentState).thenReturn(TTSState.stopped);
      when(mockAudioPlayerService.playbackState).thenReturn(AudioPlaybackStateModel.stopped());
      
      enhancedAudioService = EnhancedAudioPlaybackService(
        audioPlayerService: mockAudioPlayerService,
        ttsService: mockTTSService,
        pdfTextExtractionService: mockPDFTextExtractionService,
      );
    });

    tearDown(() {
      enhancedAudioService.dispose();
    });

    group('Initialization', () {
      test('should initialize with stopped state', () {
        expect(enhancedAudioService.isPlaying, isFalse);
        expect(enhancedAudioService.isPaused, isFalse);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
      });
    });

    group('TTS Playback', () {
      test('should play PDF using TTS successfully', () async {
        // Arrange
        final document = PDFDocument(
          id: 'test-doc',
          fileName: 'test.pdf',
          filePath: '/path/to/test.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 1,
        );
        
        const testText = 'This is test content for TTS playback.';
        final extractionResult = TextExtractionResult.success(
          text: testText,
          pageTexts: [testText],
        );

        when(mockPDFTextExtractionService.extractTextFromPDF(any, any))
            .thenAnswer((_) async => extractionResult);
        when(mockTTSService.speak(testText))
            .thenAnswer((_) async => true);
        
        // Act
        final result = await enhancedAudioService.playPDFWithTTS(document);

        // Assert
        expect(result, isTrue);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.tts);
        verify(mockPDFTextExtractionService.extractTextFromPDF(any, any)).called(1);
        verify(mockTTSService.speak(testText)).called(1);
      });

      test('should play text using TTS successfully', () async {
        // Arrange
        const testText = 'This is test text for TTS playback.';
        when(mockTTSService.speak(testText)).thenAnswer((_) async => true);

        // Act
        final result = await enhancedAudioService.playTextWithTTS(testText);

        // Assert
        expect(result, isTrue);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.tts);
        verify(mockTTSService.speak(testText)).called(1);
      });

      test('should handle TTS service not initialized', () async {
        // Arrange
        when(mockTTSService.isInitialized).thenReturn(false);

        // Act
        final result = await enhancedAudioService.playTextWithTTS('test text');

        // Assert
        expect(result, isFalse);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
        verifyNever(mockTTSService.speak(any));
      });

      test('should handle TTS playback failure', () async {
        // Arrange
        const testText = 'This will fail';
        when(mockTTSService.speak(testText)).thenAnswer((_) async => false);

        // Act
        final result = await enhancedAudioService.playTextWithTTS(testText);

        // Assert
        expect(result, isFalse);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
        verify(mockTTSService.speak(testText)).called(1);
      });
    });

    group('Audio File Playback', () {
      test('should play audio file successfully', () async {
        // Arrange
        const audioPath = '/path/to/audio.mp3';
        when(mockAudioPlayerService.playAudioFile(audioPath))
            .thenAnswer((_) async => {});
        when(mockAudioPlayerService.playbackState).thenReturn(
          AudioPlaybackStateModel.playing(
            position: Duration.zero,
            duration: const Duration(minutes: 5),
            audioPath: audioPath,
          ),
        );

        // Act
        await enhancedAudioService.playAudioFile(audioPath);

        // Assert
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.audioFile);
        verify(mockAudioPlayerService.playAudioFile(audioPath)).called(1);
      });

      test('should play audio from URL successfully', () async {
        // Arrange
        const audioUrl = 'https://example.com/audio.mp3';
        when(mockAudioPlayerService.playFromUrl(audioUrl))
            .thenAnswer((_) async => {});
        when(mockAudioPlayerService.playbackState).thenReturn(
          AudioPlaybackStateModel.playing(
            position: Duration.zero,
            duration: const Duration(minutes: 3),
            audioUrl: audioUrl,
          ),
        );

        // Act
        await enhancedAudioService.playAudioFromUrl(audioUrl);

        // Assert
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.audioFile);
        verify(mockAudioPlayerService.playFromUrl(audioUrl)).called(1);
      });

      test('should handle audio file playback failure', () async {
        // Arrange
        const audioPath = '/invalid/path.mp3';
        when(mockAudioPlayerService.playAudioFile(audioPath))
            .thenThrow(Exception('File not found'));

        // Act & Assert
        expect(
          () => enhancedAudioService.playAudioFile(audioPath),
          throwsException,
        );
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
      });
    });

    group('Playback Controls', () {
      test('should pause TTS playback', () async {
        // Arrange - set up TTS playing state
        when(mockTTSService.currentState).thenReturn(TTSState.playing);
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.tts);
        when(mockTTSService.pause()).thenAnswer((_) async => true);

        // Act
        final result = await enhancedAudioService.pause();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.pause()).called(1);
        verifyNever(mockAudioPlayerService.pause());
      });

      test('should pause audio file playback', () async {
        // Arrange - set up audio file playing state
        when(mockAudioPlayerService.playbackState).thenReturn(
          AudioPlaybackStateModel.playing(
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 5),
          ),
        );
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        when(mockAudioPlayerService.pause()).thenAnswer((_) async => {});

        // Act
        final result = await enhancedAudioService.pause();

        // Assert
        expect(result, isTrue);
        verify(mockAudioPlayerService.pause()).called(1);
        verifyNever(mockTTSService.pause());
      });

      test('should resume TTS playback', () async {
        // Arrange - first play some text to set up the current text
        const testText = 'This is test text for resuming.';
        when(mockTTSService.speak(testText)).thenAnswer((_) async => true);
        await enhancedAudioService.playTextWithTTS(testText);
        
        // Now test resume
        when(mockTTSService.speak(testText)).thenAnswer((_) async => true);

        // Act
        final result = await enhancedAudioService.resume();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.speak(testText)).called(2); // Called once for play, once for resume
        verifyNever(mockAudioPlayerService.resume());
      });

      test('should resume audio file playback', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        when(mockAudioPlayerService.resume()).thenAnswer((_) async => {});

        // Act
        final result = await enhancedAudioService.resume();

        // Assert
        expect(result, isTrue);
        verify(mockAudioPlayerService.resume()).called(1);
        verifyNever(mockTTSService.speak(any));
      });

      test('should stop TTS playback', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.tts);
        when(mockTTSService.stop()).thenAnswer((_) async => true);

        // Act
        final result = await enhancedAudioService.stop();

        // Assert
        expect(result, isTrue);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
        verify(mockTTSService.stop()).called(1);
      });

      test('should stop audio file playback', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        when(mockAudioPlayerService.stop()).thenAnswer((_) async => {});

        // Act
        final result = await enhancedAudioService.stop();

        // Assert
        expect(result, isTrue);
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
        verify(mockAudioPlayerService.stop()).called(1);
      });
    });

    group('Speed and Volume Control', () {
      test('should set TTS speed', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.tts);
        const speed = 1.5;
        when(mockTTSService.setSpeechRate(speed)).thenAnswer((_) async => {});

        // Act
        await enhancedAudioService.setSpeed(speed);

        // Assert
        verify(mockTTSService.setSpeechRate(speed)).called(1);
        verifyNever(mockAudioPlayerService.setSpeed(any));
      });

      test('should set audio file speed', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        const speed = 1.5;
        when(mockAudioPlayerService.setSpeed(speed)).thenAnswer((_) async => {});

        // Act
        await enhancedAudioService.setSpeed(speed);

        // Assert
        verify(mockAudioPlayerService.setSpeed(speed)).called(1);
        verifyNever(mockTTSService.setSpeechRate(any));
      });

      test('should set TTS volume', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.tts);
        const volume = 0.8;
        when(mockTTSService.setVolume(volume)).thenAnswer((_) async => {});

        // Act
        await enhancedAudioService.setVolume(volume);

        // Assert
        verify(mockTTSService.setVolume(volume)).called(1);
        verifyNever(mockAudioPlayerService.setVolume(any));
      });

      test('should set audio file volume', () async {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        const volume = 0.8;
        when(mockAudioPlayerService.setVolume(volume)).thenAnswer((_) async => {});

        // Act
        await enhancedAudioService.setVolume(volume);

        // Assert
        verify(mockAudioPlayerService.setVolume(volume)).called(1);
        verifyNever(mockTTSService.setVolume(any));
      });
    });

    group('State Management', () {
      test('should report TTS playing state correctly', () {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.tts);
        when(mockTTSService.currentState).thenReturn(TTSState.playing);

        // Assert
        expect(enhancedAudioService.isPlaying, isTrue);
        expect(enhancedAudioService.isPaused, isFalse);
      });

      test('should report audio file playing state correctly', () {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        when(mockAudioPlayerService.playbackState).thenReturn(
          AudioPlaybackStateModel.playing(
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 5),
          ),
        );

        // Assert
        expect(enhancedAudioService.isPlaying, isTrue);
        expect(enhancedAudioService.isPaused, isFalse);
      });

      test('should report TTS paused state correctly', () {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.tts);
        when(mockTTSService.currentState).thenReturn(TTSState.paused);

        // Assert
        expect(enhancedAudioService.isPlaying, isFalse);
        expect(enhancedAudioService.isPaused, isTrue);
      });

      test('should report audio file paused state correctly', () {
        // Arrange
        enhancedAudioService.setCurrentPlaybackMode(PlaybackMode.audioFile);
        when(mockAudioPlayerService.playbackState).thenReturn(
          AudioPlaybackStateModel.paused(
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 5),
          ),
        );

        // Assert
        expect(enhancedAudioService.isPlaying, isFalse);
        expect(enhancedAudioService.isPaused, isTrue);
      });
    });

    group('Resource Management', () {
      test('should dispose all services on dispose', () {
        // Act
        enhancedAudioService.dispose();

        // Assert
        expect(enhancedAudioService.currentPlaybackMode, PlaybackMode.none);
        // Note: We don't verify disposal of injected services as they should be managed elsewhere
      });
    });
  });
}