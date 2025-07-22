import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maxchomp/core/services/audio_playback_service.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/providers/audio_playback_provider.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';

import 'audio_playback_provider_test.mocks.dart';

@GenerateMocks([AudioPlaybackService, TTSService, PDFTextExtractionService])
void main() {
  group('AudioPlaybackProvider Tests', () {
    late MockAudioPlaybackService mockAudioPlaybackService;
    late MockTTSService mockTTSService;
    late MockPDFTextExtractionService mockPDFTextExtractionService;
    late ProviderContainer container;

    setUp(() {
      mockAudioPlaybackService = MockAudioPlaybackService();
      mockTTSService = MockTTSService();
      mockPDFTextExtractionService = MockPDFTextExtractionService();
      
      container = ProviderContainer(
        overrides: [
          audioPlaybackServiceProvider.overrideWithValue(mockAudioPlaybackService),
          ttsServiceProvider.overrideWithValue(mockTTSService),
          pdfTextExtractionServiceProvider.overrideWithValue(mockPDFTextExtractionService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('AudioPlaybackState', () {
      test('should create default state correctly', () {
        // Arrange & Act
        const state = AudioPlaybackState();
        
        // Assert
        expect(state.isLoading, isFalse);
        expect(state.isPlaying, isFalse);
        expect(state.isPaused, isFalse);
        expect(state.currentDocument, isNull);
        expect(state.currentText, isNull);
        expect(state.currentSourceId, isNull);
        expect(state.error, isNull);
        expect(state.hasContent, isFalse);
      });

      test('should handle copyWith correctly with all fields', () {
        // Arrange
        const initialState = AudioPlaybackState();
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        // Act
        final newState = initialState.copyWith(
          isLoading: true,
          isPlaying: true,
          isPaused: false,
          currentDocument: testDocument,
          currentText: 'test text',
          currentSourceId: 'test-source',
          error: 'test error',
        );
        
        // Assert
        expect(newState.isLoading, isTrue);
        expect(newState.isPlaying, isTrue);
        expect(newState.isPaused, isFalse);
        expect(newState.currentDocument, equals(testDocument));
        expect(newState.currentText, equals('test text'));
        expect(newState.currentSourceId, equals('test-source'));
        expect(newState.error, equals('test error'));
        expect(newState.hasContent, isTrue);
      });

      test('should identify hasContent correctly for document', () {
        // Arrange
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        // Act
        final state = AudioPlaybackState(currentDocument: testDocument);
        
        // Assert
        expect(state.hasContent, isTrue);
      });

      test('should identify hasContent correctly for text', () {
        // Arrange & Act
        const state = AudioPlaybackState(currentText: 'test text');
        
        // Assert
        expect(state.hasContent, isTrue);
      });
    });

    group('AudioPlaybackNotifier', () {
      test('should initialize with default state', () {
        // Act
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        final initialState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        expect(initialState.isLoading, isFalse);
        expect(initialState.isPlaying, isFalse);
        expect(initialState.isPaused, isFalse);
        expect(initialState.currentDocument, isNull);
        expect(initialState.currentText, isNull);
        expect(initialState.error, isNull);
        expect(notifier, isA<AudioPlaybackNotifier>());
      });

      test('should successfully play PDF document', () async {
        // Arrange
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        when(mockAudioPlaybackService.playPDF(testDocument))
            .thenAnswer((_) async => true);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.playPDF(testDocument);
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.playPDF(testDocument)).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isTrue);
        expect(finalState.currentDocument, equals(testDocument));
        expect(finalState.error, isNull);
      });

      test('should handle PDF playback failure', () async {
        // Arrange
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        when(mockAudioPlaybackService.playPDF(testDocument))
            .thenAnswer((_) async => false);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.playPDF(testDocument);
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.playPDF(testDocument)).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isFalse);
        expect(finalState.error, equals('Failed to play PDF'));
      });

      test('should handle PDF playback exception', () async {
        // Arrange
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        when(mockAudioPlaybackService.playPDF(testDocument))
            .thenThrow(Exception('PDF processing error'));
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.playPDF(testDocument);
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.playPDF(testDocument)).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isFalse);
        expect(finalState.error, equals('Exception: PDF processing error'));
      });

      test('should successfully play text content', () async {
        // Arrange
        const testText = 'This is test content for TTS playback.';
        const sourceId = 'manual-input';
        
        when(mockAudioPlaybackService.playText(testText))
            .thenAnswer((_) async => true);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.playText(testText, sourceId: sourceId);
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.playText(testText)).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isTrue);
        expect(finalState.currentText, equals(testText));
        expect(finalState.currentSourceId, equals(sourceId));
        expect(finalState.error, isNull);
      });

      test('should handle text playback failure', () async {
        // Arrange
        const testText = 'This is test content for TTS playback.';
        
        when(mockAudioPlaybackService.playText(testText))
            .thenAnswer((_) async => false);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.playText(testText);
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.playText(testText)).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isFalse);
        expect(finalState.error, equals('Failed to play text'));
      });

      test('should handle text playback exception', () async {
        // Arrange
        const testText = 'This is test content for TTS playback.';
        
        when(mockAudioPlaybackService.playText(testText))
            .thenThrow(Exception('TTS processing error'));
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.playText(testText);
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.playText(testText)).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isFalse);
        expect(finalState.error, equals('Exception: TTS processing error'));
      });

      test('should successfully pause playback', () async {
        // Arrange - Set up playing state first
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        when(mockAudioPlaybackService.playPDF(testDocument))
            .thenAnswer((_) async => true);
        when(mockAudioPlaybackService.pause())
            .thenAnswer((_) async => true);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        await notifier.playPDF(testDocument);
        
        // Act
        await notifier.pause();
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.pause()).called(1);
        expect(finalState.isPaused, isTrue);
        expect(finalState.isPlaying, isFalse);
      });

      test('should successfully resume playback', () async {
        // Arrange - Set up paused state first
        when(mockAudioPlaybackService.resume())
            .thenAnswer((_) async => true);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.resume();
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.resume()).called(1);
        expect(finalState.isPaused, isFalse);
        expect(finalState.isPlaying, isTrue);
      });

      test('should successfully stop playback', () async {
        // Arrange - Set up playing state first
        when(mockAudioPlaybackService.stop())
            .thenAnswer((_) async => true);
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act
        await notifier.stop();
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        verify(mockAudioPlaybackService.stop()).called(1);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isFalse);
        expect(finalState.isPaused, isFalse);
        expect(finalState.currentDocument, isNull);
        expect(finalState.error, isNull);
      });
    });

    group('Derived Providers', () {
      test('isAudioPlayingProvider should return correct playing state', () {
        // Arrange - Create a state with isPlaying = true
        container = ProviderContainer(
          overrides: [
            audioPlaybackNotifierProvider.overrideWith((ref) {
              return AudioPlaybackNotifier(mockAudioPlaybackService);
            }),
          ],
        );
        
        // Set up playing state
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        notifier.state = notifier.state.copyWith(isPlaying: true);
        
        // Act
        final isPlaying = container.read(isAudioPlayingProvider);
        
        // Assert
        expect(isPlaying, isTrue);
      });

      test('currentPlayingDocumentProvider should return current document', () {
        // Arrange
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        container = ProviderContainer(
          overrides: [
            audioPlaybackNotifierProvider.overrideWith((ref) {
              return AudioPlaybackNotifier(mockAudioPlaybackService);
            }),
          ],
        );
        
        // Set up document state
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        notifier.state = notifier.state.copyWith(currentDocument: testDocument);
        
        // Act
        final currentDocument = container.read(currentPlayingDocumentProvider);
        
        // Assert
        expect(currentDocument, equals(testDocument));
      });
    });

    group('Loading States', () {
      test('should show loading state during PDF playback initialization', () async {
        // Arrange
        final testDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test-document.pdf',
          filePath: '/test/path.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 10,
        );
        
        // Create a completer to control when the service call completes
        when(mockAudioPlaybackService.playPDF(testDocument))
            .thenAnswer((_) async {
          // Simulate some processing time
          await Future.delayed(const Duration(milliseconds: 10));
          return true;
        });
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act - Start playback but don't await
        final playbackFuture = notifier.playPDF(testDocument);
        
        // Check loading state immediately
        final loadingState = container.read(audioPlaybackNotifierProvider);
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.error, isNull);
        
        // Wait for completion
        await playbackFuture;
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isTrue);
      });

      test('should show loading state during text playback initialization', () async {
        // Arrange
        const testText = 'This is test content for TTS playback.';
        
        when(mockAudioPlaybackService.playText(testText))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return true;
        });
        
        final notifier = container.read(audioPlaybackNotifierProvider.notifier);
        
        // Act - Start playback but don't await
        final playbackFuture = notifier.playText(testText);
        
        // Check loading state immediately
        final loadingState = container.read(audioPlaybackNotifierProvider);
        expect(loadingState.isLoading, isTrue);
        expect(loadingState.error, isNull);
        
        // Wait for completion
        await playbackFuture;
        final finalState = container.read(audioPlaybackNotifierProvider);
        
        // Assert
        expect(finalState.isLoading, isFalse);
        expect(finalState.isPlaying, isTrue);
      });
    });
  });
}