// lib/core/providers/pdf_import_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pdf_document.dart';
import '../services/pdf_import_service.dart';

/// State for PDF import operations
class PDFImportState {
  final bool isImporting;
  final List<PDFDocument> importedDocuments;
  final String? errorMessage;
  final double? importProgress;

  const PDFImportState({
    this.isImporting = false,
    this.importedDocuments = const [],
    this.errorMessage,
    this.importProgress,
  });

  PDFImportState copyWith({
    bool? isImporting,
    List<PDFDocument>? importedDocuments,
    String? errorMessage,
    double? importProgress,
  }) {
    return PDFImportState(
      isImporting: isImporting ?? this.isImporting,
      importedDocuments: importedDocuments ?? this.importedDocuments,
      errorMessage: errorMessage,
      importProgress: importProgress ?? this.importProgress,
    );
  }
}

/// Provider for PDF import service
final pdfImportServiceProvider = Provider<PDFImportService>((ref) {
  return PDFImportService();
});

/// StateNotifier for managing PDF import operations
class PDFImportNotifier extends StateNotifier<PDFImportState> {
  final PDFImportService _importService;

  PDFImportNotifier(this._importService) : super(const PDFImportState());

  /// Import a single PDF file
  Future<PDFDocument?> importSinglePDF() async {
    state = state.copyWith(isImporting: true, errorMessage: null);

    try {
      final document = await _importService.pickAndImportPDF();
      
      if (document != null) {
        final updatedDocuments = [...state.importedDocuments, document];
        state = state.copyWith(
          isImporting: false,
          importedDocuments: updatedDocuments,
        );
        return document;
      } else {
        // User canceled the picker
        state = state.copyWith(isImporting: false);
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Import multiple PDF files
  Future<List<PDFDocument>> importMultiplePDFs() async {
    state = state.copyWith(isImporting: true, errorMessage: null);

    try {
      final documents = await _importService.pickAndImportMultiplePDFs();
      
      if (documents.isNotEmpty) {
        final updatedDocuments = [...state.importedDocuments, ...documents];
        state = state.copyWith(
          isImporting: false,
          importedDocuments: updatedDocuments,
        );
      } else {
        // User canceled the picker or no valid files
        state = state.copyWith(isImporting: false);
      }
      
      return documents;
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset import state
  void reset() {
    state = const PDFImportState();
  }
}

/// Provider for PDF import state notifier
final pdfImportProvider = StateNotifierProvider<PDFImportNotifier, PDFImportState>((ref) {
  final importService = ref.watch(pdfImportServiceProvider);
  return PDFImportNotifier(importService);
});