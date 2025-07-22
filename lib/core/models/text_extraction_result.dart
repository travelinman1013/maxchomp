/// Result model for PDF text extraction operations
/// 
/// This model encapsulates the result of text extraction from PDF documents,
/// including success/failure status, extracted text content, and metadata
/// for TTS processing optimization.
class TextExtractionResult {
  final bool isSuccess;
  final String text;
  final List<String> pageTexts;
  final String? error;
  final int totalCharacters;
  final Duration? processingTime;
  final Map<String, dynamic>? metadata;

  const TextExtractionResult({
    required this.isSuccess,
    required this.text,
    required this.pageTexts,
    this.error,
    required this.totalCharacters,
    this.processingTime,
    this.metadata,
  });

  /// Creates a successful text extraction result
  factory TextExtractionResult.success({
    required String text,
    required List<String> pageTexts,
    Duration? processingTime,
    Map<String, dynamic>? metadata,
  }) {
    return TextExtractionResult(
      isSuccess: true,
      text: text,
      pageTexts: pageTexts,
      totalCharacters: text.length,
      processingTime: processingTime,
      metadata: metadata,
    );
  }

  /// Creates a failed text extraction result
  factory TextExtractionResult.failure({
    required String error,
    Duration? processingTime,
  }) {
    return TextExtractionResult(
      isSuccess: false,
      text: '',
      pageTexts: [],
      error: error,
      totalCharacters: 0,
      processingTime: processingTime,
    );
  }

  /// Creates an empty result for documents with no extractable text
  factory TextExtractionResult.empty({
    required int pageCount,
    Duration? processingTime,
  }) {
    return TextExtractionResult(
      isSuccess: true,
      text: '',
      pageTexts: List.filled(pageCount, ''),
      totalCharacters: 0,
      processingTime: processingTime,
    );
  }

  /// Returns true if the extraction was successful and contains text
  bool get hasText => isSuccess && text.isNotEmpty;

  /// Returns the average characters per page
  double get averageCharactersPerPage {
    if (pageTexts.isEmpty) return 0.0;
    return totalCharacters / pageTexts.length;
  }

  /// Returns estimated reading time in minutes (assuming 200 WPM)
  int get estimatedReadingTimeMinutes {
    if (totalCharacters == 0) return 0;
    final wordCount = text.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil();
  }

  /// Returns estimated TTS duration in minutes (assuming 150 WPM)
  int get estimatedTTSDurationMinutes {
    if (totalCharacters == 0) return 0;
    final wordCount = text.split(RegExp(r'\s+')).length;
    return (wordCount / 150).ceil();
  }

  /// Creates a copy with updated values
  TextExtractionResult copyWith({
    bool? isSuccess,
    String? text,
    List<String>? pageTexts,
    String? error,
    int? totalCharacters,
    Duration? processingTime,
    Map<String, dynamic>? metadata,
  }) {
    return TextExtractionResult(
      isSuccess: isSuccess ?? this.isSuccess,
      text: text ?? this.text,
      pageTexts: pageTexts ?? this.pageTexts,
      error: error ?? this.error,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      processingTime: processingTime ?? this.processingTime,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextExtractionResult &&
        other.isSuccess == isSuccess &&
        other.text == text &&
        other.pageTexts.length == pageTexts.length &&
        other.error == error &&
        other.totalCharacters == totalCharacters;
  }

  @override
  int get hashCode {
    return Object.hash(
      isSuccess,
      text,
      pageTexts.length,
      error,
      totalCharacters,
    );
  }

  @override
  String toString() {
    if (!isSuccess) {
      return 'TextExtractionResult.failure(error: $error)';
    }
    return 'TextExtractionResult.success(characters: $totalCharacters, pages: ${pageTexts.length})';
  }
}

/// Metadata result for PDF analysis without full text extraction
class PDFMetadata {
  final bool isSuccess;
  final int pageCount;
  final bool hasText;
  final bool isPasswordProtected;
  final String? title;
  final String? author;
  final DateTime? creationDate;
  final String? error;

  const PDFMetadata({
    required this.isSuccess,
    required this.pageCount,
    required this.hasText,
    required this.isPasswordProtected,
    this.title,
    this.author,
    this.creationDate,
    this.error,
  });

  /// Creates successful metadata result
  factory PDFMetadata.success({
    required int pageCount,
    required bool hasText,
    bool isPasswordProtected = false,
    String? title,
    String? author,
    DateTime? creationDate,
  }) {
    return PDFMetadata(
      isSuccess: true,
      pageCount: pageCount,
      hasText: hasText,
      isPasswordProtected: isPasswordProtected,
      title: title,
      author: author,
      creationDate: creationDate,
    );
  }

  /// Creates failed metadata result
  factory PDFMetadata.failure({
    required String error,
  }) {
    return PDFMetadata(
      isSuccess: false,
      pageCount: 0,
      hasText: false,
      isPasswordProtected: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (!isSuccess) {
      return 'PDFMetadata.failure(error: $error)';
    }
    return 'PDFMetadata.success(pages: $pageCount, hasText: $hasText)';
  }
}