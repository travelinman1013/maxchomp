import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/library_provider.dart';
import '../core/providers/audio_playback_provider.dart';
import '../core/models/pdf_document.dart';
import '../widgets/player/audio_player_widget.dart';

/// Player page for MaxChomp TTS functionality
/// 
/// Provides a centralized interface for audio playback controls
/// and document selection for TTS reading.
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final libraryState = ref.watch(libraryProvider);
    final audioPlaybackState = ref.watch(audioPlaybackNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Audio Player Widget
            const AudioPlayerWidget(),
            
            const SizedBox(height: 24.0),
            
            // Document Selection Section
            Expanded(
              child: _buildDocumentSelection(context, ref, libraryState.documents, audioPlaybackState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSelection(
    BuildContext context, 
    WidgetRef ref, 
    List<PDFDocument> documents, 
    AudioPlaybackState audioPlaybackState,
  ) {
    final theme = Theme.of(context);

    if (documents.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.library_books,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Select Document to Play',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        
        // Document List
        Expanded(
          child: ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return _buildDocumentTile(context, ref, document, audioPlaybackState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTile(
    BuildContext context, 
    WidgetRef ref, 
    PDFDocument document, 
    AudioPlaybackState audioPlaybackState,
  ) {
    final theme = Theme.of(context);
    final isCurrentDocument = audioPlaybackState.currentDocument?.id == document.id;
    final isPlaying = audioPlaybackState.isPlaying && isCurrentDocument;

    return Card(
      elevation: isCurrentDocument ? 2.0 : 1.0,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentDocument 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            isPlaying ? Icons.volume_up : Icons.picture_as_pdf,
            color: isCurrentDocument 
                ? theme.colorScheme.onPrimary 
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          document.fileName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isCurrentDocument ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${document.totalPages} pages • ${document.displaySize}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (document.readingProgress > 0) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: document.readingProgress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  isCurrentDocument 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.surfaceContainerHigh,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          isCurrentDocument ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isCurrentDocument 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => _selectDocument(ref, document),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Documents Available',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import some PDFs in the Library tab to start listening.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Quick Test Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Try TTS Functionality',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test the text-to-speech feature with sample content',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const AudioPlayerWidget(
                    text: 'Welcome to MaxChomp! This is a sample text to test the text-to-speech functionality. The app can read PDFs aloud with natural-sounding voices.',
                    sourceId: 'sample-demo',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDocument(WidgetRef ref, PDFDocument document) {
    // For now, we'll just trigger playback of the selected document
    // In a full implementation, this might set up the document for playback
    // and allow the user to control it via the AudioPlayerWidget
    
    final audioNotifier = ref.read(audioPlaybackNotifierProvider.notifier);
    
    // If the same document is selected and currently playing, pause it
    final currentState = ref.read(audioPlaybackNotifierProvider);
    if (currentState.currentDocument?.id == document.id && currentState.isPlaying) {
      audioNotifier.pause();
    } else {
      // Play the selected document
      audioNotifier.playPDF(document);
    }
  }
}