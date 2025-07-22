import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/models/text_extraction_result.dart';

// Generate mock classes
@GenerateMocks([TTSService, PDFTextExtractionService])
import 'audio_playback_service_test.mocks.dart';

// Import the service we're about to create
import 'package:maxchomp/core/services/audio_playback_service.dart';

void main() {
  group('AudioPlaybackService Tests', () {
    late AudioPlaybackService service;
    late MockTTSService mockTTSService;
    late MockPDFTextExtractionService mockPDFTextExtractionService;

    setUp(() {
      mockTTSService = MockTTSService();
      mockPDFTextExtractionService = MockPDFTextExtractionService();
      service = AudioPlaybackService(
        ttsService: mockTTSService,
        pdfTextExtractionService: mockPDFTextExtractionService,
      );
    });

    group('PDF Playback', () {
      test('should extract text and start TTS playback for a PDF document', () async {
        // Arrange
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/path/to/test.pdf',
          fileSize: 1000,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 5,
        );

        const extractedText = 'This is the extracted text from the PDF. It contains multiple sentences for testing.';
        final extractionResult = TextExtractionResult.success(
          text: extractedText,
          pageTexts: [extractedText],
          processingTime: const Duration(seconds: 1),
        );

        when(mockPDFTextExtractionService.extractTextFromPDF(document, any))
            .thenAnswer((_) async => extractionResult);
        when(mockTTSService.isInitialized).thenReturn(true);
        when(mockTTSService.speak(extractedText)).thenAnswer((_) async => true);

        // Act
        final result = await service.playPDF(document);

        // Assert
        expect(result, isTrue);
        verify(mockPDFTextExtractionService.extractTextFromPDF(document, any)).called(1);
        verify(mockTTSService.speak(extractedText)).called(1);
      });

      test('should handle PDF extraction failure', () async {
        // Arrange
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/path/to/test.pdf',
          fileSize: 1000,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 5,
        );

        final extractionResult = TextExtractionResult.failure(
          error: 'Failed to extract text',
          processingTime: const Duration(seconds: 1),
        );

        when(mockTTSService.isInitialized).thenReturn(true);
        when(mockPDFTextExtractionService.extractTextFromPDF(document, any))
            .thenAnswer((_) async => extractionResult);

        // Act
        final result = await service.playPDF(document);

        // Assert
        expect(result, isFalse);
        verify(mockPDFTextExtractionService.extractTextFromPDF(document, any)).called(1);
        verifyNever(mockTTSService.speak(any));
      });

      test('should handle TTS initialization check', () async {
        // Arrange
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/path/to/test.pdf',
          fileSize: 1000,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 5,
        );

        when(mockTTSService.isInitialized).thenReturn(false);

        // Act
        final result = await service.playPDF(document);

        // Assert
        expect(result, isFalse);
        verifyNever(mockPDFTextExtractionService.extractTextFromPDF(any, any));
      });
    });

    group('Playback Control', () {
      test('should pause playback', () async {
        // Arrange
        when(mockTTSService.pause()).thenAnswer((_) async => true);

        // Act
        final result = await service.pause();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.pause()).called(1);
      });

      test('should stop playback', () async {
        // Arrange
        when(mockTTSService.stop()).thenAnswer((_) async => true);

        // Act
        final result = await service.stop();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.stop()).called(1);
      });

      test('should resume playback', () async {
        // Arrange
        when(mockTTSService.speak(any)).thenAnswer((_) async => true);
        
        // Set up a current text for resuming
        service.setCurrentText('Resume this text');

        // Act
        final result = await service.resume();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.speak('Resume this text')).called(1);
      });
    });

    group('Text Chunking', () {
      test('should play text in chunks for better TTS performance', () async {
        // Arrange
        const longText = '''This is a very long text that needs to be chunked.
        It contains multiple sentences and paragraphs.
        Each chunk should be a reasonable size for TTS processing.
        This ensures smooth playback without overwhelming the TTS engine.''';

        when(mockTTSService.isInitialized).thenReturn(true);
        when(mockTTSService.speak(any)).thenAnswer((_) async => true);

        // Act
        final result = await service.playText(longText);

        // Assert
        expect(result, isTrue);
        // Verify that text was spoken (actual chunking implementation will determine call count)
        verify(mockTTSService.speak(any)).called(greaterThan(0));
      });
    });

    group('State Management', () {
      test('should track current document being played', () async {
        // Arrange
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/path/to/test.pdf',
          fileSize: 1000,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 5,
        );

        const extractedText = 'Test text';
        final extractionResult = TextExtractionResult.success(
          text: extractedText,
          pageTexts: [extractedText],
        );

        when(mockPDFTextExtractionService.extractTextFromPDF(document, any))
            .thenAnswer((_) async => extractionResult);
        when(mockTTSService.isInitialized).thenReturn(true);
        when(mockTTSService.speak(extractedText)).thenAnswer((_) async => true);

        // Act
        await service.playPDF(document);

        // Assert
        expect(service.currentDocument?.id, equals(document.id));
        expect(service.hasCurrentDocument, isTrue);
      });

      test('should clear current document on stop', () async {
        // Arrange
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/path/to/test.pdf',
          fileSize: 1000,
          importedAt: DateTime.now(),
          status: DocumentStatus.ready,
          totalPages: 5,
        );

        service.setCurrentDocument(document);
        when(mockTTSService.stop()).thenAnswer((_) async => true);

        // Act
        await service.stop();

        // Assert
        expect(service.currentDocument, isNull);
        expect(service.hasCurrentDocument, isFalse);
      });
    });
  });
}