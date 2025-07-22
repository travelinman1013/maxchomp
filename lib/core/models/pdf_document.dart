// lib/core/models/pdf_document.dart

import 'dart:io';

enum DocumentStatus {
  imported,
  processing,
  ready,
  failed,
}

class PDFDocument {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize; // in bytes
  final DateTime importedAt;
  final DateTime? lastReadAt;
  final DocumentStatus status;
  final int totalPages;
  final double readingProgress; // 0.0 to 1.0
  final int? currentPage;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const PDFDocument({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.importedAt,
    this.lastReadAt,
    required this.status,
    required this.totalPages,
    this.readingProgress = 0.0,
    this.currentPage,
    this.errorMessage,
    this.metadata,
  });

  PDFDocument copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? fileSize,
    DateTime? importedAt,
    DateTime? lastReadAt,
    DocumentStatus? status,
    int? totalPages,
    double? readingProgress,
    int? currentPage,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      importedAt: importedAt ?? this.importedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      status: status ?? this.status,
      totalPages: totalPages ?? this.totalPages,
      readingProgress: readingProgress ?? this.readingProgress,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'importedAt': importedAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'status': status.name,
      'totalPages': totalPages,
      'readingProgress': readingProgress,
      'currentPage': currentPage,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    return PDFDocument(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      importedAt: DateTime.parse(json['importedAt'] as String),
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'] as String)
          : null,
      status: DocumentStatus.values.byName(json['status'] as String),
      totalPages: json['totalPages'] as int,
      readingProgress: (json['readingProgress'] as num).toDouble(),
      currentPage: json['currentPage'] as int?,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  File get file => File(filePath);

  bool get exists => file.existsSync();

  String get displaySize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get displayProgress => '${(readingProgress * 100).toStringAsFixed(0)}%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PDFDocument &&
        other.id == id &&
        other.fileName == fileName &&
        other.filePath == filePath &&
        other.fileSize == fileSize &&
        other.importedAt == importedAt &&
        other.lastReadAt == lastReadAt &&
        other.status == status &&
        other.totalPages == totalPages &&
        other.readingProgress == readingProgress &&
        other.currentPage == currentPage &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fileName,
        filePath,
        fileSize,
        importedAt,
        lastReadAt,
        status,
        totalPages,
        readingProgress,
        currentPage,
        errorMessage,
      );

  @override
  String toString() {
    return 'PDFDocument(id: $id, fileName: $fileName, status: $status, readingProgress: $readingProgress)';
  }
}