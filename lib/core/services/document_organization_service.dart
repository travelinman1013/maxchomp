import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/document_folder.dart';

/// Service for managing document organization with folders and tags
/// 
/// This service provides comprehensive document organization capabilities including:
/// - CRUD operations for folders with hierarchical support
/// - Document association and management across folders
/// - Tag-based categorization and filtering
/// - Search and filtering functionality
/// - Data persistence using SharedPreferences
/// - Import/export functionality for data backup
/// 
/// The service follows MaxChomp patterns with proper error handling,
/// performance optimization, and comprehensive validation.

class DocumentOrganizationService {
  static const String foldersKey = 'document_folders_data';
  static const String defaultFolderName = 'Documents';
  static const int currentVersion = 1;

  final SharedPreferences _preferences;
  final Uuid _uuid = const Uuid();
  
  List<DocumentFolder> _folders = [];
  bool _isInitialized = false;

  DocumentOrganizationService(this._preferences);

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the service and load existing folder data
  Future<void> initialize() async {
    try {
      await _loadFoldersFromStorage();
      
      // Create default folder if no folders exist
      if (_folders.isEmpty) {
        await _createDefaultFolder();
      }
      
      _isInitialized = true;
    } catch (e) {
      // If loading fails, start with empty state and create default folder
      _folders = [];
      await _createDefaultFolder();
      _isInitialized = true;
    }
  }

  /// Create a new folder with the specified properties
  Future<DocumentFolder> createFolder({
    required String name,
    String? description,
    String? parentId,
    String? color,
    List<String> tags = const [],
  }) async {
    _validateFolderName(name);
    
    // Validate parent exists if specified
    if (parentId != null && getFolderById(parentId) == null) {
      throw ArgumentError('Parent folder with ID $parentId does not exist');
    }
    
    // Check for duplicate names in the same parent
    final siblings = parentId == null 
        ? getRootFolders() 
        : getChildFolders(parentId);
    
    if (siblings.any((folder) => folder.name.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('A folder named "$name" already exists in this location');
    }

    final now = DateTime.now();
    final folder = DocumentFolder(
      id: _uuid.v4(),
      name: name.trim(),
      description: description?.trim(),
      createdAt: now,
      updatedAt: now,
      parentId: parentId,
      color: color,
      tags: List<String>.from(tags),
    );

    _folders.add(folder);
    await _saveFoldersToStorage();
    
    return folder;
  }

  /// Get folder by ID, returns null if not found
  DocumentFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((folder) => folder.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update an existing folder's properties
  Future<DocumentFolder?> updateFolder(
    String id, {
    String? name,
    String? description,
    String? color,
    List<String>? tags,
  }) async {
    final folder = getFolderById(id);
    if (folder == null) return null;

    if (name != null) {
      _validateFolderName(name);
      
      // Check for duplicate names in the same parent (excluding current folder)
      final siblings = folder.parentId == null 
          ? getRootFolders() 
          : getChildFolders(folder.parentId!);
      
      if (siblings.any((f) => f.id != id && f.name.toLowerCase() == name.toLowerCase())) {
        throw ArgumentError('A folder named "$name" already exists in this location');
      }
    }

    final updatedFolder = folder.copyWith(
      name: name?.trim(),
      description: description?.trim(),
      color: color,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    final index = _folders.indexWhere((f) => f.id == id);
    _folders[index] = updatedFolder;
    
    await _saveFoldersToStorage();
    return updatedFolder;
  }

  /// Delete a folder and all its children recursively
  Future<bool> deleteFolder(String id) async {
    final folder = getFolderById(id);
    if (folder == null) return false;

    if (folder.isDefault) {
      throw ArgumentError('Cannot delete default folder');
    }

    // Get all folder IDs to delete (including children recursively)
    final idsToDelete = _getFolderAndChildrenIds(id);
    
    // Remove all folders
    _folders.removeWhere((folder) => idsToDelete.contains(folder.id));
    
    await _saveFoldersToStorage();
    return true;
  }

  /// Get all folders in the system
  List<DocumentFolder> getAllFolders() {
    return List<DocumentFolder>.from(_folders);
  }

  /// Get all root folders (folders without parents)
  List<DocumentFolder> getRootFolders() {
    return _folders.where((folder) => folder.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get direct children of a folder
  List<DocumentFolder> getChildFolders(String parentId) {
    return _folders.where((folder) => folder.parentId == parentId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get the full path from root to the specified folder
  List<DocumentFolder> getFolderPath(String folderId) {
    final path = <DocumentFolder>[];
    DocumentFolder? current = getFolderById(folderId);
    
    while (current != null) {
      path.insert(0, current);
      current = current.parentId != null ? getFolderById(current.parentId!) : null;
    }
    
    return path;
  }

  /// Get breadcrumb names for the folder path
  List<String> getFolderBreadcrumbs(String folderId) {
    return getFolderPath(folderId).map((folder) => folder.name).toList();
  }

  /// Move a folder to a new parent
  Future<DocumentFolder?> moveFolder(String folderId, String? newParentId) async {
    final folder = getFolderById(folderId);
    if (folder == null) return null;

    // Validate new parent exists if specified
    if (newParentId != null && getFolderById(newParentId) == null) {
      throw ArgumentError('Target parent folder does not exist');
    }

    // Prevent moving folder to its own child
    if (newParentId != null && _isDescendant(newParentId, folderId)) {
      throw ArgumentError('Cannot move folder to its own descendant');
    }

    final updatedFolder = folder.copyWith(
      parentId: newParentId,
      updatedAt: DateTime.now(),
    );

    final index = _folders.indexWhere((f) => f.id == folderId);
    _folders[index] = updatedFolder;
    
    await _saveFoldersToStorage();
    return updatedFolder;
  }

  /// Add a document to a folder
  Future<DocumentFolder?> addDocumentToFolder(String folderId, String documentId) async {
    final folder = getFolderById(folderId);
    if (folder == null) return null;

    if (folder.containsDocument(documentId)) {
      return folder; // Document already in folder
    }

    final updatedFolder = folder.addDocument(documentId);
    final index = _folders.indexWhere((f) => f.id == folderId);
    _folders[index] = updatedFolder;
    
    await _saveFoldersToStorage();
    return updatedFolder;
  }

  /// Remove a document from a folder
  Future<DocumentFolder?> removeDocumentFromFolder(String folderId, String documentId) async {
    final folder = getFolderById(folderId);
    if (folder == null) return null;

    final updatedFolder = folder.removeDocument(documentId);
    final index = _folders.indexWhere((f) => f.id == folderId);
    _folders[index] = updatedFolder;
    
    await _saveFoldersToStorage();
    return updatedFolder;
  }

  /// Get all folders that contain a specific document
  List<DocumentFolder> getFoldersContainingDocument(String documentId) {
    return _folders.where((folder) => folder.containsDocument(documentId)).toList();
  }

  /// Move a document from one folder to another
  Future<void> moveDocumentToFolder(
    String documentId,
    String sourceFolderId,
    String targetFolderId,
  ) async {
    await removeDocumentFromFolder(sourceFolderId, documentId);
    await addDocumentToFolder(targetFolderId, documentId);
  }

  /// Add a tag to a folder
  Future<DocumentFolder?> addTagToFolder(String folderId, String tag) async {
    final folder = getFolderById(folderId);
    if (folder == null) return null;

    final updatedFolder = folder.addTag(tag);
    final index = _folders.indexWhere((f) => f.id == folderId);
    _folders[index] = updatedFolder;
    
    await _saveFoldersToStorage();
    return updatedFolder;
  }

  /// Remove a tag from a folder
  Future<DocumentFolder?> removeTagFromFolder(String folderId, String tag) async {
    final folder = getFolderById(folderId);
    if (folder == null) return null;

    final updatedFolder = folder.removeTag(tag);
    final index = _folders.indexWhere((f) => f.id == folderId);
    _folders[index] = updatedFolder;
    
    await _saveFoldersToStorage();
    return updatedFolder;
  }

  /// Get all unique tags across all folders
  List<String> getAllTags() {
    final allTags = <String>{};
    for (final folder in _folders) {
      allTags.addAll(folder.tags);
    }
    return allTags.toList()..sort();
  }

  /// Get folders that have any of the specified tags
  List<DocumentFolder> getFoldersByTag(String tag) {
    return _folders.where((folder) => folder.hasTag(tag)).toList();
  }

  /// Search folders by name or description
  List<DocumentFolder> searchFolders(String query) {
    final lowerQuery = query.toLowerCase();
    return _folders.where((folder) {
      return folder.name.toLowerCase().contains(lowerQuery) ||
             (folder.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Filter folders by multiple tags (folders must have ALL specified tags)
  List<DocumentFolder> filterFoldersByTags(List<String> tags) {
    return _folders.where((folder) {
      return tags.every((tag) => folder.hasTag(tag));
    }).toList();
  }

  /// Filter folders by date range
  List<DocumentFolder> filterFoldersByDateRange(DateTime from, DateTime to) {
    return _folders.where((folder) {
      return folder.createdAt.isAfter(from) && folder.createdAt.isBefore(to);
    }).toList();
  }

  /// Export all folders data for backup/sync
  Map<String, dynamic> exportFoldersData() {
    return {
      'folders': _folders.map((folder) => folder.toJson()).toList(),
      'version': currentVersion,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Import folders data from backup/sync
  Future<void> importFoldersData(Map<String, dynamic> data) async {
    try {
      final foldersJson = data['folders'] as List;
      _folders = foldersJson
          .map((json) => DocumentFolder.fromJson(json as Map<String, dynamic>))
          .toList();
      
      await _saveFoldersToStorage();
    } catch (e) {
      throw Exception('Failed to import folders data: $e');
    }
  }

  // Private helper methods

  void _validateFolderName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }
    if (trimmedName.length > 255) {
      throw ArgumentError('Folder name cannot exceed 255 characters');
    }
  }

  Future<void> _createDefaultFolder() async {
    final defaultFolder = DocumentFolder(
      id: _uuid.v4(),
      name: defaultFolderName,
      description: 'Default folder for documents',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: true,
    );
    
    _folders.add(defaultFolder);
    await _saveFoldersToStorage();
  }

  List<String> _getFolderAndChildrenIds(String folderId) {
    final idsToDelete = <String>[folderId];
    final children = getChildFolders(folderId);
    
    for (final child in children) {
      idsToDelete.addAll(_getFolderAndChildrenIds(child.id));
    }
    
    return idsToDelete;
  }

  bool _isDescendant(String potentialDescendantId, String ancestorId) {
    final descendant = getFolderById(potentialDescendantId);
    if (descendant == null) return false;
    
    DocumentFolder? current = descendant;
    while (current != null) {
      if (current.id == ancestorId) return true;
      current = current.parentId != null ? getFolderById(current.parentId!) : null;
    }
    
    return false;
  }

  Future<void> _loadFoldersFromStorage() async {
    final jsonString = _preferences.getString(foldersKey);
    if (jsonString == null) return;

    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final foldersJson = data['folders'] as List;
      
      _folders = foldersJson
          .map((json) => DocumentFolder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, start with empty folders
      _folders = [];
      throw Exception('Failed to load folders from storage: $e');
    }
  }

  Future<void> _saveFoldersToStorage() async {
    try {
      final data = {
        'folders': _folders.map((folder) => folder.toJson()).toList(),
        'version': currentVersion,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      final jsonString = json.encode(data);
      final success = await _preferences.setString(foldersKey, jsonString);
      
      if (!success) {
        throw Exception('Failed to save folders to storage');
      }
    } catch (e) {
      throw Exception('Failed to persist folders data: $e');
    }
  }
}