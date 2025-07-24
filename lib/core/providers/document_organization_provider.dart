import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/document_folder.dart';
import '../services/document_organization_service.dart';

/// Provider for DocumentOrganizationService instance
final documentOrganizationServiceProvider = Provider<DocumentOrganizationService>((ref) {
  // This will be overridden in tests and by a proper implementation
  throw UnimplementedError('DocumentOrganizationService provider not implemented');
});

/// State class for document organization provider
class DocumentOrganizationState {
  final List<DocumentFolder> allFolders;
  final List<DocumentFolder> rootFolders;

  const DocumentOrganizationState({
    required this.allFolders,
    required this.rootFolders,
  });

  /// Get child folders for a given parent folder ID
  List<DocumentFolder> getChildFolders(String parentId) {
    return allFolders.where((folder) => folder.parentId == parentId).toList();
  }

  DocumentOrganizationState copyWith({
    List<DocumentFolder>? allFolders,
    List<DocumentFolder>? rootFolders,
  }) {
    return DocumentOrganizationState(
      allFolders: allFolders ?? this.allFolders,
      rootFolders: rootFolders ?? this.rootFolders,
    );
  }
}

/// StateNotifier for managing document organization state
class DocumentOrganizationNotifier extends AsyncNotifier<DocumentOrganizationState> {
  DocumentOrganizationService get _service => ref.read(documentOrganizationServiceProvider);

  @override
  Future<DocumentOrganizationState> build() async {
    await _service.initialize();
    
    final allFolders = _service.getAllFolders();
    final rootFolders = _service.getRootFolders();
    
    return DocumentOrganizationState(
      allFolders: allFolders,
      rootFolders: rootFolders,
    );
  }

  /// Create a new folder
  Future<DocumentFolder> createFolder({
    required String name,
    String? description,
    String? parentId,
    String? color,
    List<String>? tags,
  }) async {
    final folder = await _service.createFolder(
      name: name,
      description: description,
      parentId: parentId,
      color: color,
      tags: tags ?? [],
    );

    await _refreshState();
    return folder;
  }

  /// Update an existing folder
  Future<DocumentFolder?> updateFolder(
    String folderId, {
    String? name,
    String? description,
    String? color,
    List<String>? tags,
  }) async {
    final updatedFolder = await _service.updateFolder(
      folderId,
      name: name,
      description: description,
      color: color,
      tags: tags,
    );

    if (updatedFolder != null) {
      await _refreshState();
    }
    
    return updatedFolder;
  }

  /// Delete a folder
  Future<bool> deleteFolder(String folderId) async {
    final success = await _service.deleteFolder(folderId);
    
    if (success) {
      await _refreshState();
    }
    
    return success;
  }

  /// Add a document to a folder
  Future<DocumentFolder?> addDocumentToFolder(String folderId, String documentId) async {
    final updatedFolder = await _service.addDocumentToFolder(folderId, documentId);
    
    if (updatedFolder != null) {
      await _refreshState();
    }
    
    return updatedFolder;
  }

  /// Remove a document from a folder
  Future<DocumentFolder?> removeDocumentFromFolder(String folderId, String documentId) async {
    final updatedFolder = await _service.removeDocumentFromFolder(folderId, documentId);
    
    if (updatedFolder != null) {
      await _refreshState();
    }
    
    return updatedFolder;
  }

  /// Move a document between folders
  Future<void> moveDocumentToFolder(String documentId, String fromFolderId, String toFolderId) async {
    await _service.moveDocumentToFolder(documentId, fromFolderId, toFolderId);
    await _refreshState();
  }

  /// Add a tag to a folder
  Future<DocumentFolder?> addTagToFolder(String folderId, String tag) async {
    final updatedFolder = await _service.addTagToFolder(folderId, tag);
    
    if (updatedFolder != null) {
      await _refreshState();
    }
    
    return updatedFolder;
  }

  /// Remove a tag from a folder
  Future<DocumentFolder?> removeTagFromFolder(String folderId, String tag) async {
    final updatedFolder = await _service.removeTagFromFolder(folderId, tag);
    
    if (updatedFolder != null) {
      await _refreshState();
    }
    
    return updatedFolder;
  }

  /// Get all unique tags across all folders
  List<String> getAllTags() {
    return _service.getAllTags();
  }

  /// Get folders that contain specific tags
  List<DocumentFolder> getFoldersByTags(List<String> tags) {
    return _service.filterFoldersByTags(tags);
  }

  /// Search folders by query
  List<DocumentFolder> searchFolders(String query) {
    return _service.searchFolders(query);
  }

  /// Filter folders by date range
  List<DocumentFolder> filterFoldersByDateRange(DateTime fromDate, DateTime toDate) {
    return _service.filterFoldersByDateRange(fromDate, toDate);
  }

  /// Get folder path (hierarchy from root to folder)
  List<DocumentFolder> getFolderPath(String folderId) {
    return _service.getFolderPath(folderId);
  }

  /// Get folder breadcrumbs
  List<String> getFolderBreadcrumbs(String folderId) {
    return _service.getFolderBreadcrumbs(folderId);
  }

  /// Move folder to new parent
  Future<DocumentFolder?> moveFolder(String folderId, String? newParentId) async {
    final movedFolder = await _service.moveFolder(folderId, newParentId);
    
    if (movedFolder != null) {
      await _refreshState();
    }
    
    return movedFolder;
  }

  /// Export folders data
  Map<String, dynamic> exportFoldersData() {
    return _service.exportFoldersData();
  }

  /// Import folders data
  Future<void> importFoldersData(Map<String, dynamic> data) async {
    await _service.importFoldersData(data);
    await _refreshState();
  }

  /// Refresh the current state from the service
  Future<void> _refreshState() async {
    final allFolders = _service.getAllFolders();
    final rootFolders = _service.getRootFolders();
    
    state = AsyncValue.data(DocumentOrganizationState(
      allFolders: allFolders,
      rootFolders: rootFolders,
    ));
  }
}

/// Provider for document organization state and operations
final documentOrganizationProvider = AsyncNotifierProvider<DocumentOrganizationNotifier, DocumentOrganizationState>(
  DocumentOrganizationNotifier.new,
);