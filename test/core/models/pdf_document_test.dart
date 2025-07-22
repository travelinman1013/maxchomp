// test/core/models/pdf_document_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:maxchomp/core/models/pdf_document.dart';

void main() {
  group('PDFDocument', () {
    late PDFDocument testDocument;

    setUp(() {
      testDocument = PDFDocument(
        id: 'test-id',
        fileName: 'test.pdf',
        filePath: '/test/path/test.pdf',
        fileSize: 1024,
        importedAt: DateTime(2025, 1, 1),
        status: DocumentStatus.ready,
        totalPages: 10,
        readingProgress: 0.5,
        currentPage: 5,
      );
    });

    group('Constructor and Properties', () {
      test('should create PDFDocument with required parameters', () {
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/test/path/test.pdf',
          fileSize: 1024,
          importedAt: DateTime(2025, 1, 1),
          status: DocumentStatus.imported,
          totalPages: 5,
        );

        expect(document.id, equals('test-id'));
        expect(document.fileName, equals('test.pdf'));
        expect(document.filePath, equals('/test/path/test.pdf'));
        expect(document.fileSize, equals(1024));
        expect(document.status, equals(DocumentStatus.imported));
        expect(document.totalPages, equals(5));
        expect(document.readingProgress, equals(0.0));
        expect(document.currentPage, isNull);
      });

      test('should create PDFDocument with all optional parameters', () {
        final importedAt = DateTime.now();
        final lastReadAt = DateTime.now();
        
        final document = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/test/path/test.pdf',
          fileSize: 1024,
          importedAt: importedAt,
          lastReadAt: lastReadAt,
          status: DocumentStatus.ready,
          totalPages: 5,
          readingProgress: 0.75,
          currentPage: 4,
          errorMessage: 'Test error',
          metadata: {'key': 'value'},
        );

        expect(document.lastReadAt, equals(lastReadAt));
        expect(document.readingProgress, equals(0.75));
        expect(document.currentPage, equals(4));
        expect(document.errorMessage, equals('Test error'));
        expect(document.metadata, equals({'key': 'value'}));
      });
    });

    group('copyWith', () {
      test('should return new instance with updated properties', () {
        final updated = testDocument.copyWith(
          fileName: 'updated.pdf',
          readingProgress: 0.75,
          currentPage: 7,
        );

        expect(updated.fileName, equals('updated.pdf'));
        expect(updated.readingProgress, equals(0.75));
        expect(updated.currentPage, equals(7));
        
        // Original properties should remain unchanged
        expect(updated.id, equals(testDocument.id));
        expect(updated.filePath, equals(testDocument.filePath));
        expect(updated.fileSize, equals(testDocument.fileSize));
      });

      test('should return identical instance when no parameters provided', () {
        final copied = testDocument.copyWith();
        
        expect(copied.id, equals(testDocument.id));
        expect(copied.fileName, equals(testDocument.fileName));
        expect(copied.readingProgress, equals(testDocument.readingProgress));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = testDocument.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['fileName'], equals('test.pdf'));
        expect(json['filePath'], equals('/test/path/test.pdf'));
        expect(json['fileSize'], equals(1024));
        expect(json['status'], equals('ready'));
        expect(json['totalPages'], equals(10));
        expect(json['readingProgress'], equals(0.5));
        expect(json['currentPage'], equals(5));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'fileName': 'test.pdf',
          'filePath': '/test/path/test.pdf',
          'fileSize': 1024,
          'importedAt': '2025-01-01T00:00:00.000',
          'lastReadAt': '2025-01-02T00:00:00.000',
          'status': 'ready',
          'totalPages': 10,
          'readingProgress': 0.5,
          'currentPage': 5,
          'errorMessage': null,
          'metadata': null,
        };

        final document = PDFDocument.fromJson(json);

        expect(document.id, equals('test-id'));
        expect(document.fileName, equals('test.pdf'));
        expect(document.filePath, equals('/test/path/test.pdf'));
        expect(document.fileSize, equals(1024));
        expect(document.importedAt, equals(DateTime(2025, 1, 1)));
        expect(document.lastReadAt, equals(DateTime(2025, 1, 2)));
        expect(document.status, equals(DocumentStatus.ready));
        expect(document.totalPages, equals(10));
        expect(document.readingProgress, equals(0.5));
        expect(document.currentPage, equals(5));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'test-id',
          'fileName': 'test.pdf',
          'filePath': '/test/path/test.pdf',
          'fileSize': 1024,
          'importedAt': '2025-01-01T00:00:00.000',
          'lastReadAt': null,
          'status': 'imported',
          'totalPages': 5,
          'readingProgress': 0.0,
          'currentPage': null,
          'errorMessage': null,
          'metadata': null,
        };

        final document = PDFDocument.fromJson(json);

        expect(document.lastReadAt, isNull);
        expect(document.currentPage, isNull);
        expect(document.errorMessage, isNull);
        expect(document.metadata, isNull);
      });
    });

    group('Display Helpers', () {
      test('should format file size correctly', () {
        expect(testDocument.displaySize, equals('1.0KB'));

        final smallFile = testDocument.copyWith(fileSize: 512);
        expect(smallFile.displaySize, equals('512B'));

        final largeFile = testDocument.copyWith(fileSize: 2 * 1024 * 1024);
        expect(largeFile.displaySize, equals('2.0MB'));
      });

      test('should format progress percentage correctly', () {
        expect(testDocument.displayProgress, equals('50%'));

        final zeroProgress = testDocument.copyWith(readingProgress: 0.0);
        expect(zeroProgress.displayProgress, equals('0%'));

        final fullProgress = testDocument.copyWith(readingProgress: 1.0);
        expect(fullProgress.displayProgress, equals('100%'));

        final partialProgress = testDocument.copyWith(readingProgress: 0.337);
        expect(partialProgress.displayProgress, equals('34%'));
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when all properties match', () {
        final document1 = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/test/path/test.pdf',
          fileSize: 1024,
          importedAt: DateTime(2025, 1, 1),
          status: DocumentStatus.ready,
          totalPages: 10,
        );

        final document2 = PDFDocument(
          id: 'test-id',
          fileName: 'test.pdf',
          filePath: '/test/path/test.pdf',
          fileSize: 1024,
          importedAt: DateTime(2025, 1, 1),
          status: DocumentStatus.ready,
          totalPages: 10,
        );

        expect(document1, equals(document2));
        expect(document1.hashCode, equals(document2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final document2 = testDocument.copyWith(fileName: 'different.pdf');

        expect(testDocument, isNot(equals(document2)));
        expect(testDocument.hashCode, isNot(equals(document2.hashCode)));
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        final stringRep = testDocument.toString();

        expect(stringRep, contains('PDFDocument'));
        expect(stringRep, contains('test-id'));
        expect(stringRep, contains('test.pdf'));
        expect(stringRep, contains('ready'));
        expect(stringRep, contains('0.5'));
      });
    });
  });

  group('DocumentStatus', () {
    test('should have all expected values', () {
      expect(DocumentStatus.values.length, equals(4));
      expect(DocumentStatus.values, contains(DocumentStatus.imported));
      expect(DocumentStatus.values, contains(DocumentStatus.processing));
      expect(DocumentStatus.values, contains(DocumentStatus.ready));
      expect(DocumentStatus.values, contains(DocumentStatus.failed));
    });

    test('should serialize status names correctly', () {
      expect(DocumentStatus.imported.name, equals('imported'));
      expect(DocumentStatus.processing.name, equals('processing'));
      expect(DocumentStatus.ready.name, equals('ready'));
      expect(DocumentStatus.failed.name, equals('failed'));
    });
  });
}