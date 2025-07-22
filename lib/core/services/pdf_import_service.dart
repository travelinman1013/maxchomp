// lib/core/services/pdf_import_service.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/pdf_document.dart';

class PDFImportService {
  final _uuid = const Uuid();

  /// Picks a single PDF file using the file picker
  Future<PDFDocument?> pickAndImportPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false, // Don't load data into memory for large files
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return null; // User canceled the picker
      }

      final platformFile = result.files.first;
      return await _processSelectedFile(platformFile);
    } catch (e) {
      throw PDFImportException('Failed to pick PDF file: ${e.toString()}');
    }
  }

  /// Picks multiple PDF files using the file picker
  Future<List<PDFDocument>> pickAndImportMultiplePDFs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return []; // User canceled the picker
      }

      final documents = <PDFDocument>[];
      for (final platformFile in result.files) {
        try {
          final document = await _processSelectedFile(platformFile);
          if (document != null) {
            documents.add(document);
          }
        } catch (e) {
          // Continue processing other files even if one fails
          // Failed to process file, continuing with others
        }
      }

      return documents;
    } catch (e) {
      throw PDFImportException('Failed to pick PDF files: ${e.toString()}');
    }
  }

  /// Processes a selected platform file and returns a PDFDocument
  Future<PDFDocument?> _processSelectedFile(PlatformFile platformFile) async {
    if (platformFile.path == null) {
      throw PDFImportException('File path is null for ${platformFile.name}');
    }

    final file = File(platformFile.path!);
    if (!file.existsSync()) {
      throw PDFImportException('File does not exist: ${platformFile.path}');
    }

    // Validate the file
    await _validatePDFFile(file);

    // Copy file to app's document directory
    final copiedFile = await _copyFileToAppDirectory(file, platformFile.name);

    // Extract basic PDF info
    final pdfInfo = await _extractPDFInfo(copiedFile);

    // Create PDFDocument model
    final document = PDFDocument(
      id: _uuid.v4(),
      fileName: platformFile.name,
      filePath: copiedFile.path,
      fileSize: await copiedFile.length(),
      importedAt: DateTime.now(),
      status: DocumentStatus.imported,
      totalPages: pdfInfo.totalPages,
      metadata: pdfInfo.metadata,
    );

    return document;
  }

  /// Validates that the file is a valid PDF
  Future<void> _validatePDFFile(File file) async {
    // Check file extension
    if (!file.path.toLowerCase().endsWith('.pdf')) {
      throw PDFImportException('File is not a PDF: ${file.path}');
    }

    // Check file size (max 100MB)
    final fileSize = await file.length();
    const maxSize = 100 * 1024 * 1024; // 100MB
    if (fileSize > maxSize) {
      throw PDFImportException('File is too large (max 100MB): ${_formatFileSize(fileSize)}');
    }

    // Basic PDF signature check
    final bytes = await file.readAsBytes();
    if (bytes.length < 4 || 
        bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
      throw PDFImportException('File is not a valid PDF');
    }
  }

  /// Copies the file to the app's document directory
  Future<File> _copyFileToAppDirectory(File sourceFile, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfsDir = Directory('${appDir.path}/pdfs');
      
      if (!pdfsDir.existsSync()) {
        await pdfsDir.create(recursive: true);
      }

      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final baseName = fileName.substring(0, fileName.lastIndexOf('.'));
      final uniqueFileName = '${baseName}_$timestamp.$extension';
      
      final targetFile = File('${pdfsDir.path}/$uniqueFileName');
      return await sourceFile.copy(targetFile.path);
    } catch (e) {
      throw PDFImportException('Failed to copy file: ${e.toString()}');
    }
  }

  /// Extracts basic information from a PDF file
  Future<_PDFInfo> _extractPDFInfo(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      // Extract PDF information using page counting
      
      // For now, we'll do basic page counting
      // In a real implementation, you might use a more robust PDF parsing library
      final totalPages = await _countPDFPages(bytes);
      
      return _PDFInfo(
        totalPages: totalPages,
        metadata: {
          'fileSize': bytes.length,
          'fileName': pdfFile.path.split('/').last,
          'importedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw PDFImportException('Failed to extract PDF info: ${e.toString()}');
    }
  }

  /// Counts the number of pages in a PDF
  Future<int> _countPDFPages(Uint8List bytes) async {
    try {
      // Simple page counting by looking for /Type /Page entries
      final content = String.fromCharCodes(bytes.where((byte) => byte < 128));
      final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(content);
      return max(1, pageMatches.length);
    } catch (e) {
      // Fallback to 1 page if counting fails
      return 1;
    }
  }

  /// Formats file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Helper class for PDF information
class _PDFInfo {
  final int totalPages;
  final Map<String, dynamic>? metadata;

  _PDFInfo({
    required this.totalPages,
    this.metadata,
  });
}

/// Custom exception for PDF import errors
class PDFImportException implements Exception {
  final String message;
  
  const PDFImportException(this.message);
  
  @override
  String toString() => 'PDFImportException: $message';
}