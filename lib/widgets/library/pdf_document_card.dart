import 'package:flutter/material.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/theme/app_theme.dart';

class PDFDocumentCard extends StatelessWidget {
  final PDFDocument document;
  final bool isGridView;
  final VoidCallback onTap;
  final Function(String) onMenu;

  const PDFDocumentCard({
    super.key,
    required this.document,
    required this.isGridView,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and Document Icon Row
              Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const Spacer(),
                  _buildStatusIcon(context),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMD),
              
              // Filename
              Text(
                document.fileName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              
              // File size and page count
              Text(
                '${document.displaySize} • ${document.totalPages} pages',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              
              // Progress indicator
              if (document.status == DocumentStatus.ready) ...[
                const SizedBox(height: AppTheme.spaceSM),
                _buildProgressIndicator(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Row(
            children: [
              // Document icon with status overlay
              Stack(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _buildStatusIcon(context, small: true),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceMD),
              
              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      '${document.displaySize} • ${document.totalPages} pages',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (document.status == DocumentStatus.ready) ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      _buildProgressIndicator(context, compact: true),
                    ],
                  ],
                ),
              ),
              
              // More button
              IconButton(
                onPressed: () => _showContextMenu(context),
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, {bool small = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = small ? 16.0 : 20.0;

    switch (document.status) {
      case DocumentStatus.ready:
        return Icon(
          Icons.check_circle,
          size: size,
          color: colorScheme.primary,
        );
      case DocumentStatus.processing:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: colorScheme.primary,
          ),
        );
      case DocumentStatus.failed:
        return Icon(
          Icons.error,
          size: size,
          color: colorScheme.error,
        );
      case DocumentStatus.imported:
        return Icon(
          Icons.file_download_outlined,
          size: size,
          color: colorScheme.secondary,
        );
    }
  }

  Widget _buildProgressIndicator(BuildContext context, {bool compact = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: document.readingProgress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            document.displayProgress,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              document.displayProgress,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXS),
        LinearProgressIndicator(
          value: document.readingProgress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Menu items
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info'),
            onTap: () {
              Navigator.of(context).pop();
              onMenu('info');
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.of(context).pop();
              onMenu('share');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onMenu('delete');
            },
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppTheme.spaceMD),
        ],
      ),
    );
  }
}