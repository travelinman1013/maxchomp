import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/pages/settings_page.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/models/settings_model.dart';
import 'package:maxchomp/core/services/settings_export_service.dart';
import 'package:maxchomp/core/providers/settings_export_provider.dart';

import 'settings_page_test.mocks.dart';

/// Test-specific SettingsNotifier that starts with initialized state
class TestSettingsNotifier extends SettingsNotifier {
  TestSettingsNotifier(SharedPreferences sharedPreferences, SettingsModel initialState) 
      : super(sharedPreferences) {
    state = initialState;
  }

  @override
  Future<void> initialize() async {
    // Do nothing - state is already set in constructor for tests
  }
}

@GenerateMocks([SharedPreferences, SettingsExportService])
void main() {
  group('Settings Page Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late MockSettingsExportService mockExportService;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      mockExportService = MockSettingsExportService();
      
      // Mock default behavior with valid settings JSON
      const defaultSettingsJson = '{"isDarkMode": false, "defaultSpeechRate": 1.0, "defaultVolume": 1.0, "defaultPitch": 1.0, "enableBackgroundPlayback": true, "enableHapticFeedback": true, "enableVoicePreview": true, "defaultThemeMode": "system"}';
      when(mockSharedPreferences.getString('settings')).thenReturn(defaultSettingsJson);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
    });

    /// Helper to reset mock state between tests that check call counts
    void resetMockForCallCountTest() {
      reset(mockSharedPreferences);
      // Re-setup mock behavior after reset
      const defaultSettingsJson = '{"isDarkMode": false, "defaultSpeechRate": 1.0, "defaultVolume": 1.0, "defaultPitch": 1.0, "enableBackgroundPlayback": true, "enableHapticFeedback": true, "enableVoicePreview": true, "defaultThemeMode": "system"}';
      when(mockSharedPreferences.getString('settings')).thenReturn(defaultSettingsJson);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
    }

    Widget createTestWidget({SettingsModel? initialSettings}) {
      final testSettings = initialSettings ?? const SettingsModel();
      
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          settingsExportServiceProvider.overrideWithValue(mockExportService),
          // Override the settings notifier provider with a pre-initialized state
          settingsNotifierProvider.overrideWith((ref) {
            // Create a test-specific notifier that's already initialized
            final notifier = TestSettingsNotifier(mockSharedPreferences, testSettings);
            return notifier;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
            useMaterial3: true,
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1200), // Ensure enough height for all sections
            ),
            child: const SettingsPage(),
          ),
        ),
      );
    }

    /// Helper method to pump and settle widget with proper timing for async state
    Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(widget);
      // Use pump() calls with timeout to ensure all content renders
      await tester.pump(); // Initial render
      await tester.pump(const Duration(milliseconds: 100)); // Allow state initialization
      await tester.pump(); // Allow UI to rebuild after state changes
      
      // Try standard pumpAndSettle with timeout for complex UI
      try {
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      } catch (e) {
        // If pumpAndSettle times out, continue with manual pumps
        await tester.pump();
        await tester.pump();
      }
    }

    group('UI Structure', () {
      testWidgets('should display settings page with Material 3 AppBar', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        
        // Verify Material 3 AppBar properties
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.elevation, equals(0)); // Material 3 zero elevation
      });

      testWidgets('should display grouped settings sections', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());
        
        // Assert - Check for main setting groups, scrolling to ensure visibility
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Audio & Voice'), findsOneWidget);
        
        // Scroll to ensure Playback section is visible (Context7 pattern)
        final playbackText = find.text('Playback');
        await tester.scrollUntilVisible(playbackText, 500.0);
        await tester.pump();
        expect(playbackText, findsOneWidget);
        
        // Scroll to ensure About section is visible
        final aboutText = find.text('About');
        await tester.scrollUntilVisible(aboutText, 500.0);
        await tester.pump();
        expect(aboutText, findsOneWidget);
        
        // Verify the ListView is present (container for settings)
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should display theme toggle switch', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert
        expect(find.text('Dark Mode'), findsOneWidget);
        expect(find.byType(Switch), findsWidgets);
      });

      testWidgets('should display voice settings section', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert
        expect(find.text('Default Voice'), findsOneWidget);
        expect(find.text('Speech Rate'), findsOneWidget);
        expect(find.text('Volume'), findsOneWidget);
        expect(find.text('Pitch'), findsOneWidget);
      });
    });

    group('Theme Interaction', () {
      testWidgets('should toggle dark mode when switch is tapped', (tester) async {
        // Arrange - Reset mock for clean call count
        resetMockForCallCountTest();
        await pumpAndSettle(tester, createTestWidget());
        
        // Find the dark mode switch
        final darkModeSwitch = find.widgetWithText(SwitchListTile, 'Dark Mode');
        expect(darkModeSwitch, findsOneWidget);
        
        // Verify initial state (light mode)
        final initialSwitch = tester.widget<SwitchListTile>(darkModeSwitch);
        expect(initialSwitch.value, isFalse);
        
        // Act - Tap the switch
        await tester.tap(darkModeSwitch);
        await tester.pump();
        
        // Assert - Switch should be toggled
        final updatedSwitch = tester.widget<SwitchListTile>(darkModeSwitch);
        expect(updatedSwitch.value, isTrue);
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });

      testWidgets('should display correct theme mode text', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert - Should show system as default
        expect(find.text('Follow system theme'), findsOneWidget);
      });
    });

    group('Voice Settings Interaction', () {
      testWidgets('should display voice selection tile', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert
        expect(find.text('Default Voice'), findsOneWidget);
        expect(find.text('System Default'), findsOneWidget); // No voice selected initially
      });

      testWidgets('should display speech rate slider', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert
        expect(find.text('Speech Rate'), findsOneWidget);
        expect(find.byType(Slider), findsWidgets);
        expect(find.text('1.0x'), findsOneWidget); // Default speech rate
      });

      testWidgets('should update speech rate when slider is moved', (tester) async {
        // Arrange - Reset mock for clean call count
        resetMockForCallCountTest();
        await pumpAndSettle(tester, createTestWidget());
        
        // Reset after initialization to track only slider changes
        reset(mockSharedPreferences);
        when(mockSharedPreferences.getString('settings')).thenReturn('{"isDarkMode": false, "defaultSpeechRate": 1.0, "defaultVolume": 1.0, "defaultPitch": 1.0, "enableBackgroundPlayback": true, "enableHapticFeedback": true, "enableVoicePreview": true, "defaultThemeMode": "system"}');
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        // Find the speech rate slider
        final sliders = find.byType(Slider);
        expect(sliders, findsWidgets);
        
        // Get the first slider (speech rate)
        final speechRateSlider = sliders.first;
        
        // Act - Move slider to 1.5x
        await tester.drag(speechRateSlider, const Offset(100, 0));
        await tester.pump();
        
        // Assert - Settings should be updated (verify at least 1 call for the slider change)
        verify(mockSharedPreferences.setString('settings', any)).called(greaterThan(0));
      });
    });

    group('Playback Settings', () {
      testWidgets('should display background playback toggle', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());
        
        // Scroll to ensure Background Playback is visible (Context7 pattern)
        final backgroundText = find.text('Background Playback');
        await tester.scrollUntilVisible(backgroundText, 500.0);
        await tester.pump();
        
        // Assert
        expect(backgroundText, findsOneWidget);
        expect(find.text('Continue playing when app is in background'), findsOneWidget);
      });

      testWidgets('should display haptic feedback toggle', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());
        
        // Scroll to ensure Haptic Feedback is visible (Context7 pattern)
        final hapticText = find.text('Haptic Feedback');
        await tester.scrollUntilVisible(hapticText, 500.0);
        await tester.pump();
        
        // Assert
        expect(hapticText, findsOneWidget);
        expect(find.text('Vibrate on button taps'), findsOneWidget);
      });

      testWidgets('should toggle background playback setting', (tester) async {
        // Arrange - Reset mock for clean call count
        resetMockForCallCountTest();
        await pumpAndSettle(tester, createTestWidget());
        
        // Scroll to ensure Background Playback is visible (Context7 pattern)
        final backgroundText = find.text('Background Playback');
        await tester.scrollUntilVisible(backgroundText, 500.0);
        await tester.pump();
        
        // Find the background playback switch
        final backgroundSwitch = find.widgetWithText(SwitchListTile, 'Background Playback');
        expect(backgroundSwitch, findsOneWidget);
        
        // Verify initial state (enabled by default)
        final initialSwitch = tester.widget<SwitchListTile>(backgroundSwitch);
        expect(initialSwitch.value, isTrue);
        
        // Act - Tap the switch to disable
        await tester.tap(backgroundSwitch);
        await tester.pump();
        
        // Assert - Switch should be toggled
        final updatedSwitch = tester.widget<SwitchListTile>(backgroundSwitch);
        expect(updatedSwitch.value, isFalse);
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });
    });

    group('Data & Backup Settings', () {
      testWidgets('should display data & backup section', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());

        // Assert - Check for Data & Backup section without forcing visibility
        expect(find.text('Data & Backup'), findsOneWidget);
      });

      testWidgets('should display export settings option', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());

        // Scroll to make the section visible
        await tester.scrollUntilVisible(
          find.text('Export Settings'),
          500.0,
          scrollable: find.byType(ListView),
        );

        // Assert - Check for export settings tile
        expect(find.text('Export Settings'), findsOneWidget);
        expect(find.text('Save settings to backup file'), findsOneWidget);
        expect(find.byIcon(Icons.backup), findsOneWidget);
      });

      testWidgets('should display import settings option', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());

        // Scroll to make the section visible
        await tester.scrollUntilVisible(
          find.text('Import Settings'),
          500.0,
          scrollable: find.byType(ListView),
        );

        // Assert - Check for import settings tile
        expect(find.text('Import Settings'), findsOneWidget);
        expect(find.text('Restore settings from backup file'), findsOneWidget);
        expect(find.byIcon(Icons.restore), findsOneWidget);
      });

      testWidgets('should show export dialog when export tile is tapped', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());

        // Scroll to make the tile visible and tap it
        await tester.scrollUntilVisible(
          find.text('Export Settings'),
          500.0,
          scrollable: find.byType(ListView),
        );
        await tester.tap(find.text('Export Settings'));
        await tester.pumpAndSettle();

        // Assert - Check for export dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Export Settings'), findsAtLeastNWidgets(1)); // One in title, one in tile
      });

      testWidgets('should show import dialog when import tile is tapped', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());

        // Scroll to make the tile visible and tap it
        await tester.scrollUntilVisible(
          find.text('Import Settings'),
          500.0,
          scrollable: find.byType(ListView),
        );
        await tester.tap(find.text('Import Settings'));
        await tester.pumpAndSettle();

        // Assert - Check for import dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Import Settings'), findsAtLeastNWidgets(1)); // One in title, one in tile
      });

      testWidgets('should use correct Material 3 styling for export/import tiles', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());

        // Scroll to make the tiles visible
        await tester.scrollUntilVisible(
          find.text('Export Settings'),
          500.0,
          scrollable: find.byType(ListView),
        );

        // Assert - Check for ListTiles with proper styling
        expect(find.byType(ListTile), findsAtLeastNWidgets(2));
        
        // Check for trailing arrows (scroll to see import settings too)
        await tester.scrollUntilVisible(
          find.text('Import Settings'),
          500.0,
          scrollable: find.byType(ListView),
        );
        expect(find.byIcon(Icons.arrow_forward_ios), findsAtLeastNWidgets(2));
      });
    });

    group('Material 3 Design Compliance', () {
      testWidgets('should use Material 3 components and theming', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert - Check for Material 3 specific components
        expect(find.byType(ListTile), findsWidgets);
        expect(find.byType(SwitchListTile), findsWidgets);
        
        // Verify Material 3 card usage for sections
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('should have proper Material 3 spacing and layout', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert - Check for proper padding and spacing
        expect(find.byType(Padding), findsWidgets);
        expect(find.byType(Column), findsWidgets);
        
        // Verify section headers are properly styled
        final headerTexts = find.byWidgetPredicate(
          (widget) => widget is Text && 
                     widget.style?.fontSize != null &&
                     widget.style!.fontSize! > 14.0
        );
        expect(headerTexts, findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert - Check for semantic labels on interactive elements
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.label != null,
          ),
          findsWidgets,
        );
      });

      testWidgets('should support screen reader navigation', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        // Assert - Check for proper semantic structure
        expect(find.byType(ListTile), findsWidgets);
        expect(find.byType(SwitchListTile), findsWidgets);
        
        // Verify switches have proper accessibility properties
        final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
        for (final switchTile in switches) {
          expect(switchTile.title, isNotNull);
          expect(switchTile.subtitle, isNotNull);
        }
      });
    });

    group('Reset Functionality', () {
      testWidgets('should display reset settings option', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());
        
        // Ensure About section is visible using Context7 scrolling pattern
        final aboutText = find.text('About');
        await tester.scrollUntilVisible(aboutText, 500.0);
        await tester.pump();
        
        // Assert - Check for About section first
        expect(aboutText, findsOneWidget);
        
        // Ensure Reset Settings is visible
        final resetText = find.text('Reset Settings');
        await tester.scrollUntilVisible(resetText, 500.0);
        await tester.pump();
        
        expect(resetText, findsOneWidget);
      });

      testWidgets('should show confirmation dialog when reset is tapped', (tester) async {
        // Act
        await pumpAndSettle(tester, createTestWidget());
        
        // Scroll to make Reset Settings button visible (Context7 pattern)
        final resetButton = find.text('Reset Settings');
        await tester.scrollUntilVisible(resetButton, 500.0);
        await tester.pump();
        
        // Tap reset settings
        await tester.tap(resetButton);
        await tester.pump();
        
        // Assert - Confirmation dialog should appear
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Reset Settings?'), findsOneWidget);
        expect(find.text('This will restore all settings to their default values.'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });

      testWidgets('should reset settings when confirmed', (tester) async {
        // Arrange - Reset mock for clean call count
        resetMockForCallCountTest();
        await pumpAndSettle(tester, createTestWidget());
        
        // Scroll to make Reset Settings button visible (Context7 pattern)
        final resetButton = find.text('Reset Settings');
        await tester.scrollUntilVisible(resetButton, 500.0);
        await tester.pump();
        
        // Tap reset settings and confirm
        await tester.tap(resetButton);
        await tester.pump();
        
        await tester.tap(find.text('Reset'));
        await tester.pump();
        
        // Assert - Settings should be saved (reset to defaults)
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });
    });
  });
}