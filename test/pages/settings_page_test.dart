import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/pages/settings_page.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/models/settings_model.dart';

import 'settings_page_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  group('Settings Page Tests', () {
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      
      // Mock default behavior
      when(mockSharedPreferences.getString('settings')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
    });

    Widget createTestWidget({SettingsModel? initialSettings}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
        child: MaterialApp(
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
            useMaterial3: true,
          ),
          home: const SettingsPage(),
        ),
      );
    }

    group('UI Structure', () {
      testWidgets('should display settings page with Material 3 AppBar', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        
        // Verify Material 3 AppBar properties
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.elevation, equals(0)); // Material 3 zero elevation
      });

      testWidgets('should display grouped settings sections', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert - Check for main setting groups
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Audio & Voice'), findsOneWidget);
        expect(find.text('Playback'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
      });

      testWidgets('should display theme toggle switch', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Dark Mode'), findsOneWidget);
        expect(find.byType(Switch), findsWidgets);
      });

      testWidgets('should display voice settings section', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Default Voice'), findsOneWidget);
        expect(find.text('Speech Rate'), findsOneWidget);
        expect(find.text('Volume'), findsOneWidget);
        expect(find.text('Pitch'), findsOneWidget);
      });
    });

    group('Theme Interaction', () {
      testWidgets('should toggle dark mode when switch is tapped', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Find the dark mode switch
        final darkModeSwitch = find.widgetWithText(SwitchListTile, 'Dark Mode');
        expect(darkModeSwitch, findsOneWidget);
        
        // Verify initial state (light mode)
        final initialSwitch = tester.widget<SwitchListTile>(darkModeSwitch);
        expect(initialSwitch.value, isFalse);
        
        // Act - Tap the switch
        await tester.tap(darkModeSwitch);
        await tester.pumpAndSettle();
        
        // Assert - Switch should be toggled
        final updatedSwitch = tester.widget<SwitchListTile>(darkModeSwitch);
        expect(updatedSwitch.value, isTrue);
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });

      testWidgets('should display correct theme mode text', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert - Should show system as default
        expect(find.text('Follow system theme'), findsOneWidget);
      });
    });

    group('Voice Settings Interaction', () {
      testWidgets('should display voice selection tile', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Default Voice'), findsOneWidget);
        expect(find.text('System Default'), findsOneWidget); // No voice selected initially
      });

      testWidgets('should display speech rate slider', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Speech Rate'), findsOneWidget);
        expect(find.byType(Slider), findsWidgets);
        expect(find.text('1.0x'), findsOneWidget); // Default speech rate
      });

      testWidgets('should update speech rate when slider is moved', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Find the speech rate slider
        final sliders = find.byType(Slider);
        expect(sliders, findsWidgets);
        
        // Get the first slider (speech rate)
        final speechRateSlider = sliders.first;
        
        // Act - Move slider to 1.5x
        await tester.drag(speechRateSlider, const Offset(100, 0));
        await tester.pumpAndSettle();
        
        // Assert - Settings should be updated
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });
    });

    group('Playback Settings', () {
      testWidgets('should display background playback toggle', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Background Playback'), findsOneWidget);
        expect(find.text('Continue playing when app is in background'), findsOneWidget);
      });

      testWidgets('should display haptic feedback toggle', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Haptic Feedback'), findsOneWidget);
        expect(find.text('Vibrate on button taps'), findsOneWidget);
      });

      testWidgets('should toggle background playback setting', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Find the background playback switch
        final backgroundSwitch = find.widgetWithText(SwitchListTile, 'Background Playback');
        expect(backgroundSwitch, findsOneWidget);
        
        // Verify initial state (enabled by default)
        final initialSwitch = tester.widget<SwitchListTile>(backgroundSwitch);
        expect(initialSwitch.value, isTrue);
        
        // Act - Tap the switch to disable
        await tester.tap(backgroundSwitch);
        await tester.pumpAndSettle();
        
        // Assert - Switch should be toggled
        final updatedSwitch = tester.widget<SwitchListTile>(backgroundSwitch);
        expect(updatedSwitch.value, isFalse);
        
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });
    });

    group('Material 3 Design Compliance', () {
      testWidgets('should use Material 3 components and theming', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert - Check for Material 3 specific components
        expect(find.byType(ListTile), findsWidgets);
        expect(find.byType(SwitchListTile), findsWidgets);
        
        // Verify Material 3 card usage for sections
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('should have proper Material 3 spacing and layout', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
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
        await tester.pumpAndSettle();
        
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
        await tester.pumpAndSettle();
        
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
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Reset Settings'), findsOneWidget);
      });

      testWidgets('should show confirmation dialog when reset is tapped', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Tap reset settings
        await tester.tap(find.text('Reset Settings'));
        await tester.pumpAndSettle();
        
        // Assert - Confirmation dialog should appear
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Reset Settings?'), findsOneWidget);
        expect(find.text('This will restore all settings to their default values.'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });

      testWidgets('should reset settings when confirmed', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Tap reset settings and confirm
        await tester.tap(find.text('Reset Settings'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        
        // Assert - Settings should be saved (reset to defaults)
        verify(mockSharedPreferences.setString('settings', any)).called(1);
      });
    });
  });
}