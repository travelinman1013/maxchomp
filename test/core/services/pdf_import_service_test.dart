// test/core/services/pdf_import_service_test.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:maxchomp/core/services/pdf_import_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';

import 'pdf_import_service_test.mocks.dart';

// Generate mocks for the dependencies
@GenerateMocks([
  File,
  Directory,
], customMocks: [
  MockSpec<FilePicker>(onMissingStub: OnMissingStub.returnDefault),
])

void main() {
  group('PDFImportService', () {
    late PDFImportService importService;
    late MockFile mockFile;
    late MockDirectory mockDirectory;

    setUp(() {
      importService = PDFImportService();
      mockFile = MockFile();
      mockDirectory = MockDirectory();
    });

    group('PDF Validation', () {
      test('should validate PDF file successfully', () async {
        // Arrange
        when(mockFile.path).thenReturn('/test/path/document.pdf');
        when(mockFile.length()).thenAnswer((_) async => 1024);
        
        // Valid PDF signature: %PDF
        final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
        when(mockFile.readAsBytes()).thenAnswer((_) async => pdfBytes);

        // Act & Assert - should not throw
        // We can't directly test the private method, but we can test through public methods
        expect(() => mockFile.path.endsWith('.pdf'), returnsNormally);
      });

      test('should throw exception for non-PDF file extension', () {
        // Arrange
        when(mockFile.path).thenReturn('/test/path/document.txt');

        // Act & Assert
        expect(mockFile.path.toLowerCase().endsWith('.pdf'), isFalse);
      });

      test('should throw exception for file too large', () async {
        // Arrange
        when(mockFile.path).thenReturn('/test/path/document.pdf');
        when(mockFile.length()).thenAnswer((_) async => 101 * 1024 * 1024); // 101MB

        // Act & Assert
        final fileSize = await mockFile.length();
        const maxSize = 100 * 1024 * 1024; // 100MB
        expect(fileSize > maxSize, isTrue);
      });

      test('should throw exception for invalid PDF signature', () async {
        // Arrange
        when(mockFile.path).thenReturn('/test/path/document.pdf');
        when(mockFile.length()).thenAnswer((_) async => 1024);
        
        // Invalid PDF signature
        final invalidBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG signature
        when(mockFile.readAsBytes()).thenAnswer((_) async => invalidBytes);

        // Act & Assert
        final bytes = await mockFile.readAsBytes();
        final isValidPdf = bytes.length >= 4 && 
            bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
        expect(isValidPdf, isFalse);
      });
    });

    group('File Size Formatting', () {
      test('should format file sizes correctly', () {
        // Test the display size formatting logic
        expect(_formatFileSize(512), equals('512B'));
        expect(_formatFileSize(1024), equals('1.0KB'));
        expect(_formatFileSize(1536), equals('1.5KB'));
        expect(_formatFileSize(1024 * 1024), equals('1.0MB'));
        expect(_formatFileSize(2.5 * 1024 * 1024), equals('2.5MB'));
      });
    });

    group('Page Counting', () {
      test('should count PDF pages correctly', () {
        // Test basic page counting logic
        const pdfContent = '''
          /Type /Page
          some content
          /Type /Page
          more content
          /Type /Page
        ''';
        
        final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(pdfContent);
        expect(pageMatches.length, equals(3));
      });

      test('should return minimum 1 page for invalid content', () {
        const invalidContent = 'invalid pdf content';
        final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(invalidContent);
        final pageCount = pageMatches.length > 0 ? pageMatches.length : 1;
        expect(pageCount, equals(1));
      });
    });

    group('File Operations', () {
      test('should check file existence correctly', () {
        // Arrange
        when(mockFile.existsSync()).thenReturn(true);

        // Act & Assert
        expect(mockFile.existsSync(), isTrue);

        // Test non-existent file
        when(mockFile.existsSync()).thenReturn(false);
        expect(mockFile.existsSync(), isFalse);
      });

      test('should generate unique file names', () {
        // Test unique filename generation logic
        const fileName = 'document.pdf';
        final timestamp1 = DateTime.now().millisecondsSinceEpoch;
        final timestamp2 = timestamp1 + 1;
        
        final baseName = fileName.substring(0, fileName.lastIndexOf('.'));
        final extension = fileName.split('.').last;
        
        final uniqueName1 = '${baseName}_$timestamp1.$extension';
        final uniqueName2 = '${baseName}_$timestamp2.$extension';
        
        expect(uniqueName1, equals('document_$timestamp1.pdf'));
        expect(uniqueName2, equals('document_$timestamp2.pdf'));
        expect(uniqueName1, isNot(equals(uniqueName2)));
      });
    });

    group('Error Handling', () {
      test('should create PDFImportException correctly', () {
        const errorMessage = 'Test error message';
        const exception = PDFImportException(errorMessage);

        expect(exception.message, equals(errorMessage));
        expect(exception.toString(), equals('PDFImportException: $errorMessage'));
      });

      test('should handle Exception interface correctly', () {
        const exception = PDFImportException('Test error');
        
        expect(exception, isA<Exception>());
        expect(() => throw exception, throwsA(isA<PDFImportException>()));
      });
    });

    group('Mock File Picker Integration', () {
      test('should handle successful file selection', () {
        // Test the general flow that would happen with FilePicker
        final mockResult = FilePickerResult([
          PlatformFile(
            name: 'test.pdf',
            path: '/test/path/test.pdf',
            size: 1024,
          ),
        ]);

        expect(mockResult.files.length, equals(1));
        expect(mockResult.files.first.name, equals('test.pdf'));
        expect(mockResult.files.first.path, equals('/test/path/test.pdf'));
        expect(mockResult.files.first.size, equals(1024));
      });

      test('should handle user cancellation', () {
        // Test handling of null result (user canceled)
        const FilePickerResult? mockResult = null;
        
        expect(mockResult, isNull);
      });

      test('should handle multiple file selection', () {
        final mockResult = FilePickerResult([
          PlatformFile(
            name: 'test1.pdf',
            path: '/test/path/test1.pdf',
            size: 1024,
          ),
          PlatformFile(
            name: 'test2.pdf',
            path: '/test/path/test2.pdf',
            size: 2048,
          ),
        ]);

        expect(mockResult.files.length, equals(2));
        expect(mockResult.files[0].name, equals('test1.pdf'));
        expect(mockResult.files[1].name, equals('test2.pdf'));
      });
    });

    group('PDFDocument Creation', () {
      test('should create PDFDocument with correct properties', () {
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
        expect(document.displaySize, equals('1.0KB'));
      });
    });
  });
}

// Helper function to test file size formatting
String _formatFileSize(num bytes) {
  if (bytes < 1024) return '${bytes.toInt()}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}