import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_export_service.dart';

/// Provider for settings export service
final settingsExportServiceProvider = Provider<SettingsExportService>((ref) {
  return SettingsExportService(ref.container);
});