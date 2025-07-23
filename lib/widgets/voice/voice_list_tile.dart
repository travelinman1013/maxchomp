import 'package:flutter/material.dart';
import 'package:maxchomp/core/models/voice_model.dart';

class VoiceListTile extends StatelessWidget {
  final VoiceModel voice;
  final bool isSelected;
  final bool isPreviewing;
  final VoidCallback onVoiceSelected;
  final VoidCallback onPreview;

  const VoiceListTile({
    super.key,
    required this.voice,
    required this.isSelected,
    required this.isPreviewing,
    required this.onVoiceSelected,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: isSelected ? 2.0 : 1.0,
      child: Semantics(
        label: 'Select voice: ${voice.name}',
        child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        tileColor: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          semanticLabel: isSelected ? 'Selected voice' : 'Unselected voice',
        ),
        title: Text(
          voice.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colorScheme.onPrimaryContainer : null,
          ),
        ),
        subtitle: Text(
          voice.locale,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected 
                ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                : colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Semantics(
          label: 'Preview voice: ${voice.name}',
          child: IconButton(
            onPressed: onPreview,
            icon: Icon(
              isPreviewing ? Icons.stop : Icons.play_arrow,
              color: isPreviewing ? colorScheme.error : colorScheme.primary,
            ),
            tooltip: isPreviewing ? 'Stop preview' : 'Preview voice',
          ),
        ),
        onTap: onVoiceSelected,
        // Ensure proper touch targets for accessibility
        minVerticalPadding: 16.0,
        // Enable keyboard navigation
        focusColor: colorScheme.primary.withOpacity(0.12),
        hoverColor: colorScheme.primary.withOpacity(0.08),
        ),
      ),
    );
  }
}

// Helper widget for voice locale display with flag support (future enhancement)
class VoiceLocaleDisplay extends StatelessWidget {
  final String locale;
  final TextStyle? style;

  const VoiceLocaleDisplay({
    super.key,
    required this.locale,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Future: Add flag icon based on locale
        // _getFlagIcon(locale),
        // const SizedBox(width: 4.0),
        Text(
          locale.toUpperCase(),
          style: style,
        ),
      ],
    );
  }

  // Future enhancement: Get flag icon for locale
  // Widget _getFlagIcon(String locale) {
  //   // Implementation for flag icons based on locale
  //   return const Icon(Icons.flag, size: 16.0);
  // }
}