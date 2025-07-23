import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/settings_provider.dart';
import '../core/providers/user_profiles_provider.dart';
import '../core/models/settings_model.dart';
import '../core/widgets/settings_backup_dialogs.dart';

/// Material 3 Settings Page for MaxChomp
/// 
/// Provides organized settings sections following Material Design 3 guidelines
/// with proper accessibility support and responsive layout.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize settings when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0, // Material 3 zero elevation
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Appearance Section
          _buildSectionCard(
            context,
            'Appearance',
            [
              _buildThemeToggle(context, settings),
              _buildThemeModeDescription(context, settings),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // Audio & Voice Section
          _buildSectionCard(
            context,
            'Audio & Voice',
            [
              _buildVoiceSelection(context, settings),
              _buildSpeechRateSlider(context, settings),
              _buildVolumeSlider(context, settings),
              _buildPitchSlider(context, settings),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // Playback Section
          _buildSectionCard(
            context,
            'Playback',
            [
              _buildBackgroundPlaybackToggle(context, settings),
              _buildHapticFeedbackToggle(context, settings),
              _buildVoicePreviewToggle(context, settings),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // User Profiles Section
          _buildSectionCard(
            context,
            'User Profiles',
            [
              _buildProfileSelection(context),
              _buildProfileManagement(context),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // Data & Backup Section
          _buildSectionCard(
            context,
            'Data & Backup',
            [
              _buildExportSettings(context),
              _buildImportSettings(context),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // About Section
          _buildSectionCard(
            context,
            'About',
            [
              _buildResetSettings(context),
              _buildVersionInfo(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1.0, // Material 3 subtle elevation
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, SettingsModel settings) {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      subtitle: const Text('Override system theme'),
      value: settings.isDarkMode,
      onChanged: (value) {
        final themeMode = value ? ThemeMode.dark : ThemeMode.light;
        ref.read(settingsNotifierProvider.notifier).updateThemeMode(themeMode);
      },
      secondary: Icon(
        settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildThemeModeDescription(BuildContext context, SettingsModel settings) {
    String description;
    if (settings.defaultThemeMode == ThemeMode.system) {
      description = 'Follow system theme';
    } else if (settings.defaultThemeMode == ThemeMode.dark) {
      description = 'Always dark';
    } else {
      description = 'Always light';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(72.0, 0.0, 16.0, 8.0),
      child: Text(
        description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildVoiceSelection(BuildContext context, SettingsModel settings) {
    return ListTile(
      title: const Text('Default Voice'),
      subtitle: Text(settings.defaultVoiceId ?? 'System Default'),
      leading: Icon(
        Icons.record_voice_over,
        color: Theme.of(context).colorScheme.primary,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () {
        // TODO: Navigate to voice selection page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice selection coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildSpeechRateSlider(BuildContext context, SettingsModel settings) {
    return _buildSliderTile(
      context,
      title: 'Speech Rate',
      icon: Icons.speed,
      value: settings.defaultSpeechRate,
      min: 0.25,
      max: 2.0,
      divisions: 7,
      formatValue: (value) => '${value.toStringAsFixed(2)}x',
      onChanged: (value) {
        ref.read(settingsNotifierProvider.notifier).updateSpeechRate(value);
      },
    );
  }

  Widget _buildVolumeSlider(BuildContext context, SettingsModel settings) {
    return _buildSliderTile(
      context,
      title: 'Volume',
      icon: Icons.volume_up,
      value: settings.defaultVolume,
      min: 0.0,
      max: 1.0,
      divisions: 10,
      formatValue: (value) => '${(value * 100).round()}%',
      onChanged: (value) {
        ref.read(settingsNotifierProvider.notifier).updateVolume(value);
      },
    );
  }

  Widget _buildPitchSlider(BuildContext context, SettingsModel settings) {
    return _buildSliderTile(
      context,
      title: 'Pitch',
      icon: Icons.tune,
      value: settings.defaultPitch,
      min: 0.5,
      max: 2.0,
      divisions: 6,
      formatValue: (value) => '${value.toStringAsFixed(1)}x',
      onChanged: (value) {
        ref.read(settingsNotifierProvider.notifier).updatePitch(value);
      },
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) formatValue,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(formatValue(value)),
          leading: Icon(icon, color: theme.colorScheme.primary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(72.0, 0.0, 16.0, 16.0),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: formatValue(value),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundPlaybackToggle(BuildContext context, SettingsModel settings) {
    return SwitchListTile(
      title: const Text('Background Playback'),
      subtitle: const Text('Continue playing when app is in background'),
      value: settings.enableBackgroundPlayback,
      onChanged: (value) {
        ref.read(settingsNotifierProvider.notifier).toggleBackgroundPlayback();
      },
      secondary: Icon(
        Icons.play_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildHapticFeedbackToggle(BuildContext context, SettingsModel settings) {
    return SwitchListTile(
      title: const Text('Haptic Feedback'),
      subtitle: const Text('Vibrate on button taps'),
      value: settings.enableHapticFeedback,
      onChanged: (value) {
        ref.read(settingsNotifierProvider.notifier).toggleHapticFeedback();
      },
      secondary: Icon(
        Icons.vibration,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildVoicePreviewToggle(BuildContext context, SettingsModel settings) {
    return SwitchListTile(
      title: const Text('Voice Preview'),
      subtitle: const Text('Play voice samples when selecting'),
      value: settings.enableVoicePreview,
      onChanged: (value) {
        ref.read(settingsNotifierProvider.notifier).toggleVoicePreview();
      },
      secondary: Icon(
        Icons.preview,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildExportSettings(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      title: const Text('Export Settings'),
      subtitle: const Text('Save settings to backup file'),
      leading: Icon(
        Icons.backup,
        color: theme.colorScheme.primary,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => SettingsBackupDialogs.showExportDialog(context, ref),
    );
  }

  Widget _buildImportSettings(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      title: const Text('Import Settings'),
      subtitle: const Text('Restore settings from backup file'),
      leading: Icon(
        Icons.restore,
        color: theme.colorScheme.secondary,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => SettingsBackupDialogs.showImportDialog(context, ref),
    );
  }

  Widget _buildResetSettings(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      title: const Text('Reset Settings'),
      subtitle: const Text('Restore all settings to defaults'),
      leading: Icon(
        Icons.restore,
        color: theme.colorScheme.error,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: () => _showResetDialog(context),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return const ListTile(
      title: Text('Version'),
      subtitle: Text('1.0.0+1'),
      leading: Icon(Icons.info_outline),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text('This will restore all settings to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsNotifierProvider.notifier).resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Build profile selection dropdown following Material 3 patterns
  Widget _buildProfileSelection(BuildContext context) {
    final theme = Theme.of(context);
    final profilesState = ref.watch(userProfilesProvider);
    final activeProfile = profilesState.activeProfile;
    
    return ListTile(
      leading: Icon(
        Icons.account_circle,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Active Profile'),
      subtitle: Text(
        activeProfile?.name ?? 'Default Profile',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: profilesState.profiles.length > 1
          ? DropdownButton<String>(
              value: activeProfile?.id ?? profilesState.profiles.first.id,
              icon: Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
              ),
              underline: Container(),
              items: profilesState.profiles.map((profile) {
                return DropdownMenuItem<String>(
                  value: profile.id,
                  child: Text(
                    profile.name,
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (profileId) {
                if (profileId != null) {
                  ref.read(userProfilesProvider.notifier).setActiveProfile(profileId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${profilesState.profiles.firstWhere((p) => p.id == profileId).name}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            )
          : Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
      onTap: profilesState.profiles.length <= 1
          ? () => _showCreateProfileDialog(context)
          : null,
    );
  }

  /// Build profile management actions following Material 3 patterns
  Widget _buildProfileManagement(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.add_circle_outline,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Create New Profile'),
          subtitle: const Text('Set up custom TTS preferences'),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.outline,
          ),
          onTap: () => _showCreateProfileDialog(context),
        ),
        ListTile(
          leading: Icon(
            Icons.edit_outlined,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Manage Profiles'),
          subtitle: const Text('Edit or delete existing profiles'),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.outline,
          ),
          onTap: () => _showManageProfilesDialog(context),
        ),
      ],
    );
  }

  /// Show create profile dialog with Material 3 design
  void _showCreateProfileDialog(BuildContext context) {
    // TODO: Implement create profile dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create profile dialog - Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show manage profiles dialog with Material 3 design
  void _showManageProfilesDialog(BuildContext context) {
    // TODO: Implement manage profiles dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manage profiles dialog - Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}