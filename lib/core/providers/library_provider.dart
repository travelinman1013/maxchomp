// lib/core/providers/library_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/pdf_document.dart';

/// State for the PDF document library
class LibraryState {
  final List<PDFDocument> documents;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final LibrarySortBy sortBy;
  final bool sortAscending;

  const LibraryState({
    this.documents = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.sortBy = LibrarySortBy.dateAdded,
    this.sortAscending = false,
  });

  LibraryState copyWith({
    List<PDFDocument>? documents,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    LibrarySortBy? sortBy,
    bool? sortAscending,
  }) {
    return LibraryState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Get filtered and sorted documents
  List<PDFDocument> get filteredDocuments {
    var filtered = documents;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) =>
          doc.fileName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case LibrarySortBy.fileName:
          comparison = a.fileName.compareTo(b.fileName);
          break;
        case LibrarySortBy.fileSize:
          comparison = a.fileSize.compareTo(b.fileSize);
          break;
        case LibrarySortBy.dateAdded:
          comparison = a.importedAt.compareTo(b.importedAt);
          break;
        case LibrarySortBy.lastRead:
          final aLastRead = a.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bLastRead = b.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = aLastRead.compareTo(bLastRead);
          break;
        case LibrarySortBy.readingProgress:
          comparison = a.readingProgress.compareTo(b.readingProgress);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });

    return filtered;
  }
}

/// Sorting options for the library
enum LibrarySortBy {
  fileName,
  fileSize,
  dateAdded,
  lastRead,
  readingProgress,
}

/// StateNotifier for managing the PDF library
class LibraryNotifier extends StateNotifier<LibraryState> {
  static const String _storageKey = 'pdf_library';

  LibraryNotifier() : super(const LibraryState()) {
    _loadDocuments();
  }

  /// Load documents from local storage
  Future<void> _loadDocuments() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = prefs.getStringList(_storageKey) ?? [];
      
      final documents = documentsJson
          .map((json) => PDFDocument.fromJson(jsonDecode(json)))
          .toList();

      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load library: ${e.toString()}',
      );
    }
  }

  /// Save documents to local storage
  Future<void> _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = state.documents
          .map((doc) => jsonEncode(doc.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, documentsJson);
    } catch (e) {
      print('Failed to save documents: $e');
    }
  }

  /// Add a new document to the library
  Future<void> addDocument(PDFDocument document) async {
    final updatedDocuments = [...state.documents, document];
    state = state.copyWith(documents: updatedDocuments);
    await _saveDocuments();
  }

  /// Add multiple documents to the library
  Future<void> addDocuments(List<PDFDocument> documents) async {
    final updatedDocuments = [...state.documents, ...documents];
    state = state.copyWith(documents: updatedDocuments);
    await _saveDocuments();
  }

  /// Update an existing document
  Future<void> updateDocument(PDFDocument updatedDocument) async {
    final updatedDocuments = state.documents.map((doc) {
      return doc.id == updatedDocument.id ? updatedDocument : doc;
    }).toList();
    
    state = state.copyWith(documents: updatedDocuments);
    await _saveDocuments();
  }

  /// Remove a document from the library
  Future<void> removeDocument(String documentId) async {
    final document = state.documents.firstWhere((doc) => doc.id == documentId);
    
    // Delete the physical file
    try {
      if (document.exists) {
        await document.file.delete();
      }
    } catch (e) {
      print('Failed to delete file: $e');
    }

    // Remove from state
    final updatedDocuments = state.documents
        .where((doc) => doc.id != documentId)
        .toList();
    
    state = state.copyWith(documents: updatedDocuments);
    await _saveDocuments();
  }

  /// Update document reading progress
  Future<void> updateReadingProgress(String documentId, double progress, {int? currentPage}) async {
    final document = state.documents.firstWhere((doc) => doc.id == documentId);
    final updatedDocument = document.copyWith(
      readingProgress: progress,
      currentPage: currentPage,
      lastReadAt: DateTime.now(),
    );
    
    await updateDocument(updatedDocument);
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set sorting options
  void setSorting(LibrarySortBy sortBy, {bool? ascending}) {
    state = state.copyWith(
      sortBy: sortBy,
      sortAscending: ascending ?? state.sortAscending,
    );
  }

  /// Toggle sort order
  void toggleSortOrder() {
    state = state.copyWith(sortAscending: !state.sortAscending);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh the library (reload from storage)
  Future<void> refresh() async {
    await _loadDocuments();
  }

  /// Get document by ID
  PDFDocument? getDocumentById(String id) {
    try {
      return state.documents.firstWhere((doc) => doc.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for the PDF library
final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

/// Provider for a specific document by ID
final documentProvider = Provider.family<PDFDocument?, String>((ref, documentId) {
  final libraryState = ref.watch(libraryProvider);
  return libraryState.documents.firstWhere(
    (doc) => doc.id == documentId,
    orElse: () => throw StateError('Document not found: $documentId'),
  );
});