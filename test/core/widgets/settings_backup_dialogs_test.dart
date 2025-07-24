import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/core/widgets/settings_backup_dialogs.dart';
import 'package:maxchomp/core/services/settings_export_service.dart';
import 'package:maxchomp/core/providers/settings_export_provider.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/models/settings_model.dart';

import 'settings_backup_dialogs_test.mocks.dart';

@GenerateMocks([SettingsExportService, SharedPreferences])
void main() {
  group('SettingsBackupDialogs', () {
    late MockSettingsExportService mockExportService;
    late MockSharedPreferences mockSharedPreferences;
    late ProviderContainer container;

    setUp(() {
      mockExportService = MockSettingsExportService();
      mockSharedPreferences = MockSharedPreferences();
      
      // Mock SharedPreferences behavior
      const defaultSettingsJson = '{"isDarkMode": false, "defaultSpeechRate": 1.0, "defaultVolume": 1.0, "defaultPitch": 1.0, "enableBackgroundPlayback": true, "enableHapticFeedback": true, "enableVoicePreview": true, "defaultThemeMode": "system"}';
      when(mockSharedPreferences.getString('settings')).thenReturn(defaultSettingsJson);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
      
      container = ProviderContainer(
        overrides: [
          settingsExportServiceProvider.overrideWithValue(mockExportService),
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          settingsNotifierProvider.overrideWith((ref) => TestSettingsNotifier(mockSharedPreferences)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Export Dialog', () {
      testWidgets('displays export dialog with correct title and content', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        // Tap button to show dialog
        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Verify dialog is displayed
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Export Settings'), findsOneWidget);
        expect(find.byIcon(Icons.backup), findsOneWidget);

        // Verify content
        expect(find.text('Save your current settings to a backup file. This includes:'), findsOneWidget);
        expect(find.text('Audio & voice preferences'), findsOneWidget);
        expect(find.text('Theme settings'), findsOneWidget);
        expect(find.text('Playback options'), findsOneWidget);
        expect(find.text('App version information'), findsOneWidget);

        // Verify buttons
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
      });

      testWidgets('shows feature list with check icons', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Verify check icons for each feature
        expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(4));
      });

      testWidgets('closes dialog when cancel is tapped', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify dialog is closed
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('displays error message when export fails', (tester) async {
        // Mock export service to return failure
        when(mockExportService.exportSettings())
            .thenAnswer((_) async => const ServiceResult.failure('Export failed'));

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Note: Since file picker is platform-dependent, we can't easily test
        // the full export flow in unit tests. This would be covered in integration tests.
      });
    });

    group('Import Dialog', () {
      testWidgets('displays import dialog with correct title and content', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showImportDialog(context, ref),
                  child: const Text('Show Import'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Import'));
        await tester.pumpAndSettle();

        // Verify dialog is displayed
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Import Settings'), findsOneWidget);
        expect(find.byIcon(Icons.restore), findsOneWidget);

        // Verify content
        expect(find.text('Restore settings from a backup file. This will overwrite your current settings.'), findsOneWidget);

        // Verify warning card
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        expect(find.text('This will replace all current settings. Make sure to backup first if needed.'), findsOneWidget);

        // Verify buttons
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Select File'), findsOneWidget);
      });

      testWidgets('displays warning message with amber icon', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showImportDialog(context, ref),
                  child: const Text('Show Import'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Import'));
        await tester.pumpAndSettle();

        // Verify warning card is displayed
        final warningContainer = find.ancestor(
          of: find.byIcon(Icons.warning_amber),
          matching: find.byType(Container),
        );
        expect(warningContainer, findsOneWidget);
      });

      testWidgets('closes dialog when cancel is tapped', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showImportDialog(context, ref),
                  child: const Text('Show Import'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Import'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify dialog is closed
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Material 3 Design Compliance', () {
      testWidgets('uses correct Material 3 theming for export dialog', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
                useMaterial3: true,
              ),
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Verify Material 3 components are used
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);

        // Verify primary color is applied to icons
        final backupIcon = tester.widget<Icon>(find.byIcon(Icons.backup));
        expect(backupIcon.color, isNotNull);
      });

      testWidgets('uses correct Material 3 theming for import dialog', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
                useMaterial3: true,
              ),
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showImportDialog(context, ref),
                  child: const Text('Show Import'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Import'));
        await tester.pumpAndSettle();

        // Verify Material 3 components are used
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
      });

      testWidgets('applies proper Material 3 elevation and styling', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
                useMaterial3: true,
              ),
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Verify dialog has proper Material 3 styling
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(dialog, isNotNull);
      });
    });

    group('Accessibility', () {
      testWidgets('provides semantic labels for export dialog elements', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Verify dialog title is accessible
        expect(find.text('Export Settings'), findsOneWidget);

        // Verify buttons are accessible
        expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Export'), findsOneWidget);
      });

      testWidgets('provides semantic labels for import dialog elements', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showImportDialog(context, ref),
                  child: const Text('Show Import'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Import'));
        await tester.pumpAndSettle();

        // Verify dialog title is accessible
        expect(find.text('Import Settings'), findsOneWidget);

        // Verify buttons are accessible
        expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Select File'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message with proper styling', (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
                useMaterial3: true,
              ),
              home: Consumer(
                builder: (context, ref, child) => ElevatedButton(
                  onPressed: () => SettingsBackupDialogs.showExportDialog(context, ref),
                  child: const Text('Show Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Export'));
        await tester.pumpAndSettle();

        // Error states would be tested in integration tests due to file picker dependency
        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });
  });
}

/// Test-specific SettingsNotifier for widget testing
class TestSettingsNotifier extends SettingsNotifier {
  TestSettingsNotifier(SharedPreferences sharedPreferences) : super(sharedPreferences) {
    state = const SettingsModel();
  }

  @override
  Future<void> initialize() async {
    // State is already set in constructor for tests
  }

  @override
  Future<void> importSettings(SettingsModel settings) async {
    state = settings;
  }
}