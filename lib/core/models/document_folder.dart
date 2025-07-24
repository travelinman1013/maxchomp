import 'package:equatable/equatable.dart';

/// A model representing a folder for organizing PDF documents in MaxChomp
/// 
/// DocumentFolder provides hierarchical organization capabilities with support for:
/// - Parent-child relationships for nested folder structures
/// - Document association and management
/// - Tag-based categorization and filtering
/// - Custom colors for visual organization
/// - JSON serialization for persistence
/// 
/// This model follows the established pattern in MaxChomp using Equatable
/// for value equality and immutable design principles.

class DocumentFolder extends Equatable {
  /// Unique identifier for the folder
  final String id;
  
  /// Display name of the folder (1-255 characters)
  final String name;
  
  /// Optional description providing additional context
  final String? description;
  
  /// Timestamp when the folder was created
  final DateTime createdAt;
  
  /// Timestamp when the folder was last modified
  final DateTime updatedAt;
  
  /// Parent folder ID for hierarchical organization (null for root folders)
  final String? parentId;
  
  /// Optional hex color code for visual customization (e.g., "#FF6B6B")
  final String? color;
  
  /// List of document IDs contained in this folder
  final List<String> documentIds;
  
  /// Tags associated with this folder for categorization
  final List<String> tags;
  
  /// Whether this is a system default folder (cannot be deleted)
  final bool isDefault;
  
  /// Sort order for displaying folders (lower values appear first)
  final int sortOrder;

  const DocumentFolder({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.color,
    this.documentIds = const [],
    this.tags = const [],
    this.isDefault = false,
    this.sortOrder = 0,
  }) : assert(name.length > 0, 'Folder name cannot be empty'),
       assert(name.length <= 255, 'Folder name cannot exceed 255 characters');

  /// Creates a copy of this folder with optionally updated properties
  DocumentFolder copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentId,
    String? color,
    List<String>? documentIds,
    List<String>? tags,
    bool? isDefault,
    int? sortOrder,
  }) {
    return DocumentFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      documentIds: documentIds ?? this.documentIds,
      tags: tags ?? this.tags,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Serializes the folder to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'parentId': parentId,
      'color': color,
      'documentIds': documentIds,
      'tags': tags,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  /// Creates a DocumentFolder from a JSON map
  factory DocumentFolder.fromJson(Map<String, dynamic> json) {
    // Validate color format if present
    final colorValue = json['color'] as String?;
    if (colorValue != null && !_isValidHexColor(colorValue)) {
      throw ArgumentError('Invalid color format: $colorValue');
    }

    return DocumentFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      parentId: json['parentId'] as String?,
      color: colorValue,
      documentIds: List<String>.from(json['documentIds'] as List? ?? []),
      tags: List<String>.from(json['tags'] as List? ?? []),
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// Validates hex color format (#RRGGBB or #RGB)
  static bool _isValidHexColor(String color) {
    return RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$').hasMatch(color);
  }

  /// Validates and sets the color, throwing ArgumentError for invalid format
  DocumentFolder _validateAndCopyWithColor(String? newColor) {
    if (newColor != null && !_isValidHexColor(newColor)) {
      throw ArgumentError('Invalid color format: $newColor. Use format #RRGGBB or #RGB');
    }
    return copyWith(color: newColor);
  }

  // Document Management Methods

  /// Returns the number of documents in this folder
  int get documentCount => documentIds.length;

  /// Checks if the folder contains a specific document
  bool containsDocument(String documentId) => documentIds.contains(documentId);

  /// Adds a document to the folder (if not already present)
  DocumentFolder addDocument(String documentId) {
    if (containsDocument(documentId)) {
      return this;
    }
    return copyWith(
      documentIds: [...documentIds, documentId],
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a document from the folder
  DocumentFolder removeDocument(String documentId) {
    if (!containsDocument(documentId)) {
      return this;
    }
    return copyWith(
      documentIds: documentIds.where((id) => id != documentId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  // Tag Management Methods

  /// Checks if the folder has a specific tag
  bool hasTag(String tag) => tags.contains(tag);

  /// Adds a tag to the folder (if not already present)
  DocumentFolder addTag(String tag) {
    if (hasTag(tag)) {
      return this;
    }
    return copyWith(
      tags: [...tags, tag],
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a tag from the folder
  DocumentFolder removeTag(String tag) {
    if (!hasTag(tag)) {
      return this;
    }
    return copyWith(
      tags: tags.where((t) => t != tag).toList(),
      updatedAt: DateTime.now(),
    );
  }

  // Hierarchy and Organization Methods

  /// Whether this is a root folder (has no parent)
  bool get isRootFolder => parentId == null;

  /// Whether this folder can be deleted (default folders cannot be deleted)
  bool get canBeDeleted => !isDefault;

  /// Calculates the depth of this folder in the hierarchy (0 for root folders)
  int get depth {
    // This is a simple implementation. In a real app, you'd need access to
    // the folder hierarchy to calculate the actual depth.
    return isRootFolder ? 0 : 1;
  }

  /// Checks if this folder is a child of the specified parent folder
  bool isChildOf(String potentialParentId) => parentId == potentialParentId;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdAt,
        updatedAt,
        parentId,
        color,
        documentIds,
        tags,
        isDefault,
        sortOrder,
      ];

  @override
  String toString() {
    return 'DocumentFolder(id: $id, name: $name, ${documentIds.length} documents, '
           'isDefault: $isDefault, parentId: $parentId)';
  }
}