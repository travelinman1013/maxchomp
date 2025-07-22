import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/services/pdf_text_extraction_service.dart';
import 'package:maxchomp/core/models/pdf_document.dart';

/// Service that integrates PDF text extraction with TTS playback
/// 
/// This service provides a high-level interface for playing PDF documents
/// by extracting their text content and feeding it to the TTS engine.
class AudioPlaybackService {
  final TTSService ttsService;
  final PDFTextExtractionService pdfTextExtractionService;
  
  // State management
  PDFDocument? _currentDocument;
  String? _currentText;
  List<String>? _textChunks;
  int _currentChunkIndex = 0;
  
  AudioPlaybackService({
    required this.ttsService,
    required this.pdfTextExtractionService,
  });
  
  // Getters
  PDFDocument? get currentDocument => _currentDocument;
  bool get hasCurrentDocument => _currentDocument != null;
  String? get currentText => _currentText;
  
  /// Plays a PDF document by extracting its text and starting TTS playback
  Future<bool> playPDF(PDFDocument document) async {
    // Check if TTS is initialized
    if (!ttsService.isInitialized) {
      return false;
    }
    
    // Extract text from PDF
    final extractionResult = await pdfTextExtractionService.extractTextFromPDF(document, document.file);
    
    if (!extractionResult.isSuccess || !extractionResult.hasText) {
      return false;
    }
    
    // Store current document and text
    _currentDocument = document;
    _currentText = extractionResult.text;
    
    // Start TTS playback
    return await ttsService.speak(extractionResult.text);
  }
  
  /// Plays raw text content
  Future<bool> playText(String text) async {
    if (!ttsService.isInitialized) {
      return false;
    }
    
    _currentText = text;
    _textChunks = _chunkText(text);
    _currentChunkIndex = 0;
    
    // For now, play the entire text
    // TODO: Implement chunk-based playback for better performance
    return await ttsService.speak(text);
  }
  
  /// Pauses the current playback
  Future<bool> pause() async {
    return await ttsService.pause();
  }
  
  /// Stops the current playback and clears the current document
  Future<bool> stop() async {
    final result = await ttsService.stop();
    
    // Clear current state
    _currentDocument = null;
    _currentText = null;
    _textChunks = null;
    _currentChunkIndex = 0;
    
    return result;
  }
  
  /// Resumes playback from where it was paused
  Future<bool> resume() async {
    if (_currentText == null) {
      return false;
    }
    
    // Resume with current text
    // In a full implementation, this would resume from the exact position
    return await ttsService.speak(_currentText!);
  }
  
  /// Sets the current document (for testing)
  void setCurrentDocument(PDFDocument? document) {
    _currentDocument = document;
  }
  
  /// Sets the current text (for testing)
  void setCurrentText(String? text) {
    _currentText = text;
  }
  
  /// Chunks text into manageable pieces for TTS
  List<String> _chunkText(String text, {int maxChunkLength = 500}) {
    if (text.isEmpty) return [];
    
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));
    
    String currentChunk = '';
    
    for (final sentence in sentences) {
      final trimmedSentence = sentence.trim();
      if (trimmedSentence.isEmpty) continue;
      
      // Add proper punctuation back
      final sentenceWithPunctuation = '$trimmedSentence.';
      
      if (currentChunk.isEmpty) {
        currentChunk = sentenceWithPunctuation;
      } else if ((currentChunk.length + sentenceWithPunctuation.length + 1) <= maxChunkLength) {
        currentChunk += ' $sentenceWithPunctuation';
      } else {
        chunks.add(currentChunk);
        currentChunk = sentenceWithPunctuation;
      }
    }
    
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }
    
    return chunks;
  }
  
  /// Gets the next chunk of text for playback
  String? getNextChunk() {
    if (_textChunks == null || _currentChunkIndex >= _textChunks!.length) {
      return null;
    }
    
    return _textChunks![_currentChunkIndex++];
  }
  
  /// Resets chunk playback to the beginning
  void resetChunks() {
    _currentChunkIndex = 0;
  }
  
  /// Disposes of resources
  void dispose() {
    _currentDocument = null;
    _currentText = null;
    _textChunks = null;
    _currentChunkIndex = 0;
  }
}