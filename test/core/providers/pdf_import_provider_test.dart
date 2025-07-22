// test/core/providers/pdf_import_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/providers/pdf_import_provider.dart';
import 'package:maxchomp/core/services/pdf_import_service.dart';

import 'pdf_import_provider_test.mocks.dart';

@GenerateMocks([PDFImportService])
void main() {
  group('PDFImportProvider', () {
    late MockPDFImportService mockImportService;
    late ProviderContainer container;

    setUp(() {
      mockImportService = MockPDFImportService();
      
      container = ProviderContainer(
        overrides: [
          pdfImportServiceProvider.overrideWithValue(mockImportService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('PDFImportState', () {
      test('should create initial state correctly', () {
        const state = PDFImportState();

        expect(state.isImporting, isFalse);
        expect(state.importedDocuments, isEmpty);
        expect(state.errorMessage, isNull);
        expect(state.importProgress, isNull);
      });

      test('should create state with parameters', () {
        final documents = [
          PDFDocument(
            id: 'test-id',
            fileName: 'test.pdf',
            filePath: '/test/path/test.pdf',
            fileSize: 1024,
            importedAt: DateTime.now(),
            status: DocumentStatus.imported,
            totalPages: 5,
          ),
        ];

        final state = PDFImportState(
          isImporting: true,
          importedDocuments: documents,
          errorMessage: 'Test error',
          importProgress: 0.5,
        );

        expect(state.isImporting, isTrue);
        expect(state.importedDocuments, equals(documents));
        expect(state.errorMessage, equals('Test error'));
        expect(state.importProgress, equals(0.5));
      });

      test('should copy with new values', () {
        const originalState = PDFImportState(
          isImporting: false,
          importedDocuments: [],
        );

        final newState = originalState.copyWith(
          isImporting: true,
          errorMessage: 'New error',
        );

        expect(newState.isImporting, isTrue);
        expect(newState.importedDocuments, isEmpty);
        expect(newState.errorMessage, equals('New error'));
      });

      test('should copy with null values', () {
        const originalState = PDFImportState(
          isImporting: true,
          errorMessage: 'Old error',
        );

        final newState = originalState.copyWith(
          errorMessage: null,
        );

        expect(newState.isImporting, isTrue);
        expect(newState.errorMessage, isNull);
      });
    });

    group('PDFImportNotifier', () {
      test('should initialize with default state', () {
        final notifier = container.read(pdfImportProvider.notifier);
        final state = container.read(pdfImportProvider);

        expect(state.isImporting, isFalse);
        expect(state.importedDocuments, isEmpty);
        expect(state.errorMessage, isNull);
      });

      test('should import single PDF successfully', () async {
        // Arrange
        final expectedDocument = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/test/path/test.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.imported,
          totalPages: 5,
        );

        when(mockImportService.pickAndImportPDF())
            .thenAnswer((_) async => expectedDocument);

        final notifier = container.read(pdfImportProvider.notifier);

        // Act
        final result = await notifier.importSinglePDF();

        // Assert
        expect(result, equals(expectedDocument));
        
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, contains(expectedDocument));
        expect(finalState.errorMessage, isNull);
      });

      test('should handle user cancellation for single PDF', () async {
        // Arrange
        when(mockImportService.pickAndImportPDF())
            .thenAnswer((_) async => null);

        final notifier = container.read(pdfImportProvider.notifier);

        // Act
        final result = await notifier.importSinglePDF();

        // Assert
        expect(result, isNull);
        
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, isEmpty);
        expect(finalState.errorMessage, isNull);
      });

      test('should handle error during single PDF import', () async {
        // Arrange
        const errorMessage = 'Import failed';
        when(mockImportService.pickAndImportPDF())
            .thenThrow(const PDFImportException(errorMessage));

        final notifier = container.read(pdfImportProvider.notifier);

        // Act
        final result = await notifier.importSinglePDF();

        // Assert
        expect(result, isNull);
        
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, isEmpty);
        expect(finalState.errorMessage, contains(errorMessage));
      });

      test('should import multiple PDFs successfully', () async {
        // Arrange
        final expectedDocuments = [
          PDFDocument(
            id: 'test-id-1',
            fileName: 'test1.pdf',
            filePath: '/test/path/test1.pdf',
            fileSize: 1024,
            importedAt: DateTime.now(),
            status: DocumentStatus.imported,
            totalPages: 5,
          ),
          PDFDocument(
            id: 'test-id-2',
            fileName: 'test2.pdf',
            filePath: '/test/path/test2.pdf',
            fileSize: 2048,
            importedAt: DateTime.now(),
            status: DocumentStatus.imported,
            totalPages: 10,
          ),
        ];

        when(mockImportService.pickAndImportMultiplePDFs())
            .thenAnswer((_) async => expectedDocuments);

        final notifier = container.read(pdfImportProvider.notifier);

        // Act
        final result = await notifier.importMultiplePDFs();

        // Assert
        expect(result, equals(expectedDocuments));
        
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, containsAll(expectedDocuments));
        expect(finalState.errorMessage, isNull);
      });

      test('should handle user cancellation for multiple PDFs', () async {
        // Arrange
        when(mockImportService.pickAndImportMultiplePDFs())
            .thenAnswer((_) async => []);

        final notifier = container.read(pdfImportProvider.notifier);

        // Act
        final result = await notifier.importMultiplePDFs();

        // Assert
        expect(result, isEmpty);
        
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, isEmpty);
        expect(finalState.errorMessage, isNull);
      });

      test('should handle error during multiple PDF import', () async {
        // Arrange
        const errorMessage = 'Multiple import failed';
        when(mockImportService.pickAndImportMultiplePDFs())
            .thenThrow(const PDFImportException(errorMessage));

        final notifier = container.read(pdfImportProvider.notifier);

        // Act
        final result = await notifier.importMultiplePDFs();

        // Assert
        expect(result, isEmpty);
        
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, isEmpty);
        expect(finalState.errorMessage, contains(errorMessage));
      });

      test('should clear error message', () {
        // Arrange
        final notifier = container.read(pdfImportProvider.notifier);
        notifier.state = const PDFImportState(errorMessage: 'Test error');

        // Act
        notifier.clearError();

        // Assert
        final finalState = container.read(pdfImportProvider);
        expect(finalState.errorMessage, isNull);
      });

      test('should reset import state', () {
        // Arrange
        final documents = [
          PDFDocument(
            id: 'test-id',
            fileName: 'test.pdf',
            filePath: '/test/path/test.pdf',
            fileSize: 1024,
            importedAt: DateTime.now(),
            status: DocumentStatus.imported,
            totalPages: 5,
          ),
        ];

        final notifier = container.read(pdfImportProvider.notifier);
        notifier.state = PDFImportState(
          isImporting: true,
          importedDocuments: documents,
          errorMessage: 'Test error',
        );

        // Act
        notifier.reset();

        // Assert
        final finalState = container.read(pdfImportProvider);
        expect(finalState.isImporting, isFalse);
        expect(finalState.importedDocuments, isEmpty);
        expect(finalState.errorMessage, isNull);
      });

      test('should accumulate imported documents', () async {
        // Arrange
        final document1 = PDFDocument(
          id: 'test-id-1',
          fileName: 'test1.pdf',
          filePath: '/test/path/test1.pdf',
          fileSize: 1024,
          importedAt: DateTime.now(),
          status: DocumentStatus.imported,
          totalPages: 5,
        );

        final document2 = PDFDocument(
          id: 'test-id-2',
          fileName: 'test2.pdf',
          filePath: '/test/path/test2.pdf',
          fileSize: 2048,
          importedAt: DateTime.now(),
          status: DocumentStatus.imported,
          totalPages: 10,
        );

        when(mockImportService.pickAndImportPDF())
            .thenAnswer((_) async => document1);

        final notifier = container.read(pdfImportProvider.notifier);

        // Act - Import first document
        await notifier.importSinglePDF();

        // Set up second import
        when(mockImportService.pickAndImportPDF())
            .thenAnswer((_) async => document2);

        // Act - Import second document
        await notifier.importSinglePDF();

        // Assert
        final finalState = container.read(pdfImportProvider);
        expect(finalState.importedDocuments.length, equals(2));
        expect(finalState.importedDocuments, contains(document1));
        expect(finalState.importedDocuments, contains(document2));
      });
    });

    group('Provider Integration', () {
      test('should provide PDFImportService', () {
        final service = container.read(pdfImportServiceProvider);
        expect(service, isA<PDFImportService>());
      });

      test('should create PDFImportNotifier with service', () {
        final notifier = container.read(pdfImportProvider.notifier);
        expect(notifier, isA<PDFImportNotifier>());
      });
    });
  });
}