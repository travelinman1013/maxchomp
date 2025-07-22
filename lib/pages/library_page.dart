import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/providers/library_provider.dart';
import 'package:maxchomp/core/providers/pdf_import_provider.dart';
import 'package:maxchomp/widgets/library/pdf_import_button.dart';
import 'package:maxchomp/widgets/library/pdf_document_card.dart';
import 'package:maxchomp/core/theme/app_theme.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Filter documents based on search query
    final filteredDocuments = libraryState.documents.where((doc) {
      if (_searchQuery.isEmpty) return true;
      return doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Library',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search documents',
          ),
          // View toggle button
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          const SizedBox(width: AppTheme.spaceSM),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(libraryProvider.notifier).refresh();
        },
        child: _buildBody(filteredDocuments, colorScheme, textTheme),
      ),
      floatingActionButton: const PDFImportButton(),
    );
  }

  Widget _buildBody(List<dynamic> documents, ColorScheme colorScheme, TextTheme textTheme) {
    if (documents.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      child: _isGridView 
          ? _buildGridView(documents)
          : _buildListView(documents),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No documents found'
                  : 'Your library is empty',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Import your first PDF to get started',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: AppTheme.spaceLG),
              FilledButton.icon(
                onPressed: () {
                  // Trigger the import button
                  ref.read(pdfImportProvider.notifier).importMultiplePDFs();
                },
                icon: const Icon(Icons.add),
                label: const Text('Import PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<dynamic> documents) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: AppTheme.spaceMD,
        mainAxisSpacing: AppTheme.spaceMD,
        childAspectRatio: 0.75, // Adjust for card proportions
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return PDFDocumentCard(
          document: documents[index],
          isGridView: true,
          onTap: () => _openDocument(documents[index]),
          onMenu: (action) => _handleDocumentAction(documents[index], action),
        );
      },
    );
  }

  Widget _buildListView(List<dynamic> documents) {
    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
          child: PDFDocumentCard(
            document: documents[index],
            isGridView: false,
            onTap: () => _openDocument(documents[index]),
            onMenu: (action) => _handleDocumentAction(documents[index], action),
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Material 3 responsive breakpoints
    if (width < 600) return 2; // Mobile
    if (width < 840) return 3; // Tablet portrait
    return 4; // Tablet landscape and desktop
  }

  void _openDocument(dynamic document) {
    // Navigate to player page with this document
    // TODO: Implement navigation to player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${document.fileName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDocumentAction(dynamic document, String action) {
    switch (action) {
      case 'delete':
        _showDeleteDialog(document);
        break;
      case 'share':
        // TODO: Implement sharing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing ${document.fileName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'info':
        _showDocumentInfo(document);
        break;
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String query = _searchQuery;
        return AlertDialog(
          title: const Text('Search Library'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by filename',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => query = value,
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _searchQuery = query;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(dynamic document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Text(
            'Are you sure you want to delete "${document.fileName}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(libraryProvider.notifier).removeDocument(document.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${document.fileName}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDocumentInfo(dynamic document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document.fileName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Size', value: document.displaySize),
              _InfoRow(label: 'Pages', value: '${document.totalPages}'),
              _InfoRow(label: 'Progress', value: document.displayProgress),
              _InfoRow(label: 'Status', value: document.status.name.toUpperCase()),
              _InfoRow(label: 'Imported', value: _formatDate(document.importedAt)),
              if (document.lastReadAt != null)
                _InfoRow(label: 'Last read', value: _formatDate(document.lastReadAt!)),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}