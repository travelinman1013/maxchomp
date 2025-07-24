import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/settings_export_provider.dart';

/// Material 3 dialogs for settings backup and restore functionality
/// 
/// Provides consistent design following Material Design 3 guidelines
/// with proper accessibility support and error handling.
class SettingsBackupDialogs {
  
  /// Shows export (backup) dialog with file selection and progress
  static Future<void> showExportDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      builder: (context) => _SettingsExportDialog(),
    );
  }
  
  /// Shows import (restore) dialog with file picker and validation
  static Future<void> showImportDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      builder: (context) => _SettingsImportDialog(),
    );
  }
}

/// Export dialog for backing up settings to a JSON file
class _SettingsExportDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SettingsExportDialog> createState() => _SettingsExportDialogState();
}

class _SettingsExportDialogState extends ConsumerState<_SettingsExportDialog> {
  bool _isExporting = false;
  String? _exportError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.backup,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8.0),
          const Text('Export Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save your current settings to a backup file. This includes:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12.0),
          _buildExportFeatureList(theme),
          if (_exportError != null) ...[
            const SizedBox(height: 16.0),
            _buildErrorMessage(theme, _exportError!),
          ],
          if (_isExporting) ...[
            const SizedBox(height: 16.0),
            _buildExportProgress(theme),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isExporting ? null : _performExport,
          child: _isExporting 
            ? const SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildExportFeatureList(ThemeData theme) {
    final features = [
      'Audio & voice preferences',
      'Theme settings',
      'Playback options',
      'App version information',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16.0,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                feature,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildErrorMessage(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportProgress(ThemeData theme) {
    return Row(
      children: [
        const SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
        const SizedBox(width: 12.0),
        Text(
          'Exporting settings...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
      _exportError = null;
    });

    try {
      // Get save location from user
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Settings Backup',
        fileName: 'maxchomp_settings_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) {
        // User cancelled
        setState(() {
          _isExporting = false;
        });
        return;
      }

      // Perform export using the service
      final exportService = ref.read(settingsExportServiceProvider);
      final result = await exportService.exportSettingsToFile(outputFile);

      if (mounted) {
        if (result.isSuccess) {
          Navigator.of(context).pop();
          _showSuccessSnackBar(context, 'Settings exported successfully');
        } else {
          setState(() {
            _exportError = result.error ?? 'Export failed';
            _isExporting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _exportError = 'Unexpected error: ${e.toString()}';
          _isExporting = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8.0),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Import dialog for restoring settings from a JSON file
class _SettingsImportDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SettingsImportDialog> createState() => _SettingsImportDialogState();
}

class _SettingsImportDialogState extends ConsumerState<_SettingsImportDialog> {
  bool _isImporting = false;
  String? _importError;
  String? _selectedFile;
  bool _showConfirmation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_showConfirmation) {
      return _buildConfirmationDialog(theme);
    }
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.restore,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8.0),
          const Text('Import Settings'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restore settings from a backup file. This will overwrite your current settings.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16.0),
          _buildWarningCard(theme),
          if (_selectedFile != null) ...[
            const SizedBox(height: 16.0),
            _buildSelectedFileCard(theme),
          ],
          if (_importError != null) ...[
            const SizedBox(height: 16.0),
            _buildErrorMessage(theme, _importError!),
          ],
          if (_isImporting) ...[
            const SizedBox(height: 16.0),
            _buildImportProgress(theme),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isImporting ? null : _selectFile,
          child: _isImporting 
            ? const SizedBox(
                width: 16.0,
                height: 16.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : Text(_selectedFile == null ? 'Select File' : 'Import'),
        ),
      ],
    );
  }

  Widget _buildWarningCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: theme.colorScheme.onSecondaryContainer,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'This will replace all current settings. Make sure to backup first if needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.file_present,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected file:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _selectedFile!.split('/').last,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportProgress(ThemeData theme) {
    return Row(
      children: [
        const SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
        const SizedBox(width: 12.0),
        Text(
          'Importing settings...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationDialog(ThemeData theme) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8.0),
          const Text('Confirm Import'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to import these settings? This will overwrite all current settings and cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16.0),
          _buildSelectedFileCard(theme),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showConfirmation = false;
            });
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _performImport,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Import & Overwrite'),
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    if (_selectedFile != null) {
      // File already selected, show confirmation
      setState(() {
        _showConfirmation = true;
      });
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Settings Backup File',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.single.path!;
          _importError = null;
        });
      }
    } catch (e) {
      setState(() {
        _importError = 'File selection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _performImport() async {
    if (_selectedFile == null) return;

    setState(() {
      _isImporting = true;
      _importError = null;
    });

    try {
      // Perform import using the service
      final exportService = ref.read(settingsExportServiceProvider);
      final result = await exportService.importSettingsFromFile(_selectedFile!);

      if (mounted) {
        if (result.isSuccess) {
          Navigator.of(context).pop();
          _showSuccessSnackBar(context, 'Settings imported successfully');
        } else {
          setState(() {
            _importError = result.error ?? 'Import failed';
            _isImporting = false;
            _showConfirmation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importError = 'Unexpected error: ${e.toString()}';
          _isImporting = false;
          _showConfirmation = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8.0),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}