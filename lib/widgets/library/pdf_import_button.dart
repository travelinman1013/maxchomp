// lib/widgets/library/pdf_import_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/pdf_import_provider.dart';
import '../../core/providers/library_provider.dart';

class PDFImportButton extends ConsumerWidget {
  final bool allowMultiple;
  final VoidCallback? onImportComplete;

  const PDFImportButton({
    super.key,
    this.allowMultiple = false,
    this.onImportComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(pdfImportProvider);
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      onPressed: importState.isImporting ? null : () => _handleImport(context, ref),
      icon: importState.isImporting 
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.add),
      label: Text(
        importState.isImporting 
            ? 'Importing...' 
            : allowMultiple 
                ? 'Import PDFs' 
                : 'Import PDF',
      ),
      backgroundColor: importState.isImporting 
          ? theme.colorScheme.surfaceContainer
          : theme.colorScheme.primary,
      foregroundColor: importState.isImporting
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onPrimary,
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final importNotifier = ref.read(pdfImportProvider.notifier);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    try {
      if (allowMultiple) {
        final documents = await importNotifier.importMultiplePDFs();
        if (documents.isNotEmpty) {
          await libraryNotifier.addDocuments(documents);
          if (context.mounted) {
            _showSuccessMessage(context, '${documents.length} PDF(s) imported successfully');
          }
          onImportComplete?.call();
        }
      } else {
        final document = await importNotifier.importSinglePDF();
        if (document != null) {
          await libraryNotifier.addDocument(document);
          if (context.mounted) {
            _showSuccessMessage(context, 'PDF imported successfully');
          }
          onImportComplete?.call();
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorMessage(context, 'Failed to import PDF: ${e.toString()}');
      }
    }

    // Clear any import state errors after handling
    final importState = ref.read(pdfImportProvider);
    if (importState.errorMessage != null) {
      if (context.mounted) {
        _showErrorMessage(context, importState.errorMessage!);
      }
      importNotifier.clearError();
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}