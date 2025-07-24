import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../models/tts_models.dart';
import '../providers/user_profiles_provider.dart';

/// Material 3 Profile Management Dialogs
/// 
/// Provides create, edit, and delete profile dialogs following Material Design 3
/// guidelines with proper form validation and accessibility support.
class ProfileManagementDialogs {
  ProfileManagementDialogs._();

  /// Show create profile dialog with Material 3 design
  static Future<void> showCreateProfileDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CreateProfileDialog(),
    );
  }

  /// Show edit profile dialog with Material 3 design
  static Future<void> showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: profile),
    );
  }

  /// Show delete profile dialog with Material 3 design
  static Future<void> showDeleteProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _DeleteProfileDialog(profile: profile),
    );
  }

  /// Show manage profiles dialog with list of all profiles
  static Future<void> showManageProfilesDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ManageProfilesDialog(),
    );
  }
}

/// Create Profile Dialog with Material 3 form validation
class _CreateProfileDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<_CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  double _speechRate = TTSSettingsModel.defaultSettings.speechRate;
  double _volume = TTSSettingsModel.defaultSettings.volume;
  double _pitch = TTSSettingsModel.defaultSettings.pitch;
  String _language = TTSSettingsModel.defaultSettings.language;
  String _selectedIcon = 'account_circle';
  
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12.0),
          const Text('Create Profile'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Profile Name',
                    hintText: 'Enter a unique name for this profile',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Profile name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Profile name must be at least 2 characters';
                    }
                    if (value.trim().length > 30) {
                      return 'Profile name must be less than 30 characters';
                    }
                    
                    // Check for duplicate names
                    final profiles = ref.read(userProfilesProvider).profiles;
                    final nameExists = profiles.any((p) => 
                      p.name.toLowerCase().trim() == value.toLowerCase().trim());
                    if (nameExists) {
                      return 'A profile with this name already exists';
                    }
                    
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                
                const SizedBox(height: 24.0),
                
                // TTS Settings Section
                Text(
                  'Voice Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Speech Rate Slider
                _buildSliderTile(
                  context,
                  title: 'Speech Rate',
                  icon: Icons.speed,
                  value: _speechRate,
                  min: 0.25,
                  max: 2.0,
                  divisions: 7,
                  formatValue: (value) => '${value.toStringAsFixed(2)}x',
                  onChanged: (value) => setState(() => _speechRate = value),
                ),
                
                const SizedBox(height: 16.0),
                
                // Volume Slider
                _buildSliderTile(
                  context,
                  title: 'Volume',
                  icon: Icons.volume_up,
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  formatValue: (value) => '${(value * 100).round()}%',
                  onChanged: (value) => setState(() => _volume = value),
                ),
                
                const SizedBox(height: 16.0),
                
                // Pitch Slider
                _buildSliderTile(
                  context,
                  title: 'Pitch',
                  icon: Icons.tune,
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  formatValue: (value) => '${value.toStringAsFixed(1)}x',
                  onChanged: (value) => setState(() => _pitch = value),
                ),
                
                const SizedBox(height: 24.0),
                
                // Icon Selection
                Text(
                  'Profile Icon',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12.0),
                
                _buildIconSelector(context),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _createProfile,
          child: _isCreating
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Text('Create'),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.0, color: theme.colorScheme.primary),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              formatValue(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: formatValue(value),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIconSelector(BuildContext context) {
    final theme = Theme.of(context);
    const icons = [
      'account_circle',
      'person',
      'face',
      'school',
      'work',
      'home',
      'family_restroom',
      'elderly',
    ];
    
    final iconData = {
      'account_circle': Icons.account_circle,
      'person': Icons.person,
      'face': Icons.face,
      'school': Icons.school,
      'work': Icons.work,
      'home': Icons.home,
      'family_restroom': Icons.family_restroom,
      'elderly': Icons.elderly,
    };
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: icons.map((iconId) {
        final isSelected = _selectedIcon == iconId;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = iconId),
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12.0),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2.0,
                    )
                  : null,
            ),
            child: Icon(
              iconData[iconId],
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isCreating = true);
    
    try {
      final ttsSettings = TTSSettingsModel(
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
        language: _language,
        selectedVoice: null, // TODO: Add voice selection
      );
      
      final profile = await ref.read(userProfilesProvider.notifier).createProfile(
        name: _nameController.text.trim(),
        ttsSettings: ttsSettings,
        iconId: _selectedIcon,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${profile.name}" created successfully!'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Activate',
              onPressed: () {
                ref.read(userProfilesProvider.notifier).setActiveProfile(profile.id);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Edit Profile Dialog with pre-populated data
class _EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile profile;
  
  const _EditProfileDialog({required this.profile});

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  
  late double _speechRate;
  late double _volume;
  late double _pitch;
  late String _language;
  late String _selectedIcon;
  
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _speechRate = widget.profile.ttsSettings.speechRate;
    _volume = widget.profile.ttsSettings.volume;
    _pitch = widget.profile.ttsSettings.pitch;
    _language = widget.profile.ttsSettings.language;
    _selectedIcon = widget.profile.iconId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12.0),
          const Text('Edit Profile'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Profile Name',
                    hintText: 'Enter a unique name for this profile',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Profile name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Profile name must be at least 2 characters';
                    }
                    if (value.trim().length > 30) {
                      return 'Profile name must be less than 30 characters';
                    }
                    
                    // Check for duplicate names (excluding current profile)
                    final profiles = ref.read(userProfilesProvider).profiles;
                    final nameExists = profiles.any((p) => 
                      p.id != widget.profile.id &&
                      p.name.toLowerCase().trim() == value.toLowerCase().trim());
                    if (nameExists) {
                      return 'A profile with this name already exists';
                    }
                    
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                
                const SizedBox(height: 24.0),
                
                // TTS Settings Section
                Text(
                  'Voice Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Speech Rate Slider
                _buildSliderTile(
                  context,
                  title: 'Speech Rate',
                  icon: Icons.speed,
                  value: _speechRate,
                  min: 0.25,
                  max: 2.0,
                  divisions: 7,
                  formatValue: (value) => '${value.toStringAsFixed(2)}x',
                  onChanged: (value) => setState(() => _speechRate = value),
                ),
                
                const SizedBox(height: 16.0),
                
                // Volume Slider
                _buildSliderTile(
                  context,
                  title: 'Volume',
                  icon: Icons.volume_up,
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  formatValue: (value) => '${(value * 100).round()}%',
                  onChanged: (value) => setState(() => _volume = value),
                ),
                
                const SizedBox(height: 16.0),
                
                // Pitch Slider
                _buildSliderTile(
                  context,
                  title: 'Pitch',
                  icon: Icons.tune,
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  formatValue: (value) => '${value.toStringAsFixed(1)}x',
                  onChanged: (value) => setState(() => _pitch = value),
                ),
                
                const SizedBox(height: 24.0),
                
                // Icon Selection
                Text(
                  'Profile Icon',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12.0),
                
                _buildIconSelector(context),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUpdating ? null : _updateProfile,
          child: _isUpdating
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Text('Save'),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.0, color: theme.colorScheme.primary),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              formatValue(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: formatValue(value),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIconSelector(BuildContext context) {
    final theme = Theme.of(context);
    const icons = [
      'account_circle',
      'person',
      'face',
      'school',
      'work',
      'home',
      'family_restroom',
      'elderly',
    ];
    
    final iconData = {
      'account_circle': Icons.account_circle,
      'person': Icons.person,
      'face': Icons.face,
      'school': Icons.school,
      'work': Icons.work,
      'home': Icons.home,
      'family_restroom': Icons.family_restroom,
      'elderly': Icons.elderly,
    };
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: icons.map((iconId) {
        final isSelected = _selectedIcon == iconId;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = iconId),
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12.0),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 2.0,
                    )
                  : null,
            ),
            child: Icon(
              iconData[iconId],
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUpdating = true);
    
    try {
      final ttsSettings = TTSSettingsModel(
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
        language: _language,
        selectedVoice: widget.profile.ttsSettings.selectedVoice,
      );
      
      final updatedProfile = widget.profile.copyWith(
        name: _nameController.text.trim(),
        ttsSettings: ttsSettings,
        iconId: _selectedIcon,
        updatedAt: DateTime.now(),
      );
      
      await ref.read(userProfilesProvider.notifier).updateProfile(updatedProfile);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${updatedProfile.name}" updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Delete Profile Dialog with confirmation
class _DeleteProfileDialog extends ConsumerStatefulWidget {
  final UserProfile profile;
  
  const _DeleteProfileDialog({required this.profile});

  @override
  ConsumerState<_DeleteProfileDialog> createState() => _DeleteProfileDialogState();
}

class _DeleteProfileDialogState extends ConsumerState<_DeleteProfileDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12.0),
          const Text('Delete Profile'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this profile?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(widget.profile.iconId),
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        widget.profile.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'This action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _deleteProfile,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _deleteProfile() async {
    setState(() => _isDeleting = true);
    
    try {
      await ref.read(userProfilesProvider.notifier).deleteProfile(widget.profile.id);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile "${widget.profile.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getIconData(String iconId) {
    const iconMap = {
      'account_circle': Icons.account_circle,
      'person': Icons.person,
      'face': Icons.face,
      'school': Icons.school,
      'work': Icons.work,
      'home': Icons.home,
      'family_restroom': Icons.family_restroom,
      'elderly': Icons.elderly,
    };
    return iconMap[iconId] ?? Icons.account_circle;
  }
}

/// Manage Profiles Dialog showing all profiles with actions
class _ManageProfilesDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profilesState = ref.watch(userProfilesProvider);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.manage_accounts,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12.0),
          const Text('Manage Profiles'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: profilesState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : profilesState.profiles.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    itemCount: profilesState.profiles.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final profile = profilesState.profiles[index];
                      final isActive = profile.id == profilesState.activeProfileId;
                      
                      return _ProfileListTile(
                        profile: profile,
                        isActive: isActive,
                        onEdit: profile.isDefault 
                            ? null 
                            : () => ProfileManagementDialogs.showEditProfileDialog(
                                context, ref, profile),
                        onDelete: profile.isDefault 
                            ? null 
                            : () => ProfileManagementDialogs.showDeleteProfileDialog(
                                context, ref, profile),
                        onActivate: isActive 
                            ? null 
                            : () => ref.read(userProfilesProvider.notifier)
                                .setActiveProfile(profile.id),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ProfileManagementDialogs.showCreateProfileDialog(context, ref);
          },
          child: const Text('Create New'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64.0,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No profiles created yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Create your first profile to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile List Tile for the manage profiles dialog
class _ProfileListTile extends StatelessWidget {
  final UserProfile profile;
  final bool isActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onActivate;
  
  const _ProfileListTile({
    required this.profile,
    required this.isActive,
    this.onEdit,
    this.onDelete,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isActive 
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(
          _getIconData(profile.iconId),
          color: isActive 
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (profile.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Default',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            Text(profile.description),
            const SizedBox(height: 4.0),
            Text(
              'Created ${_formatDate(profile.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onActivate != null)
              IconButton(
                onPressed: onActivate,
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Activate Profile',
              ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Delete Profile',
              ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  IconData _getIconData(String iconId) {
    const iconMap = {
      'account_circle': Icons.account_circle,
      'person': Icons.person,
      'face': Icons.face,
      'school': Icons.school,
      'work': Icons.work,
      'home': Icons.home,
      'family_restroom': Icons.family_restroom,
      'elderly': Icons.elderly,
    };
    return iconMap[iconId] ?? Icons.account_circle;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }
}