import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/widgets/voice/voice_list_tile.dart';
import 'package:maxchomp/core/theme/app_theme.dart';

void main() {
  group('VoiceListTile Widget Tests', () {
    late VoiceModel testVoice;
    bool onVoiceSelectedCalled = false;
    bool onPreviewCalled = false;
    VoiceModel? selectedVoice;
    VoiceModel? calledVoice;

    setUp(() {
      testVoice = VoiceModel(
        name: 'Karen',
        locale: 'en-AU',
        identifier: 'com.apple.voice.compact.en-AU.Karen',
      );
      onVoiceSelectedCalled = false;
      onPreviewCalled = false;
      selectedVoice = null;
      calledVoice = null;
    });

    Widget createTestWidget({
      VoiceModel? voice,
      bool isSelected = false,
      bool isPreviewing = false,
      VoidCallback? onVoiceSelected,
      VoidCallback? onPreview,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: VoiceListTile(
            voice: voice ?? testVoice,
            isSelected: isSelected,
            isPreviewing: isPreviewing,
            onVoiceSelected: onVoiceSelected ?? () {
              onVoiceSelectedCalled = true;
              calledVoice = voice ?? testVoice;
            },
            onPreview: onPreview ?? () {
              onPreviewCalled = true;
              calledVoice = voice ?? testVoice;
            },
          ),
        ),
      );
    }

    testWidgets('displays voice name and locale', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Karen'), findsOneWidget);
      expect(find.text('en-AU'), findsOneWidget);
    });

    testWidgets('displays play button when not previewing', (tester) async {
      await tester.pumpWidget(createTestWidget(isPreviewing: false));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('displays stop button when previewing', (tester) async {
      await tester.pumpWidget(createTestWidget(isPreviewing: true));

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows selected indicator when selected', (tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: true));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows radio button when not selected', (tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: false));

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('calls onVoiceSelected when tile is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(onVoiceSelectedCalled, isTrue);
      expect(calledVoice, equals(testVoice));
    });

    testWidgets('calls onPreview when preview button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(onPreviewCalled, isTrue);
      expect(calledVoice, equals(testVoice));
    });

    testWidgets('calls onPreview when stop button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget(isPreviewing: true));

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      expect(onPreviewCalled, isTrue);
      expect(calledVoice, equals(testVoice));
    });

    testWidgets('applies Material 3 styling', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('uses correct colors for selected state', (tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: true));

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.tileColor, isNotNull);
    });

    testWidgets('displays correct semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for semantics widgets
      expect(find.byType(Semantics), findsWidgets);
      
      // Verify semantic structure exists
      final semanticsNodes = tester.semantics;
      expect(semanticsNodes, isNotEmpty);
    });

    testWidgets('has proper touch targets for accessibility', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final listTileSize = tester.getSize(find.byType(ListTile));
      expect(listTileSize.height, greaterThanOrEqualTo(48.0)); // Material 3 minimum touch target

      final iconButtonSize = tester.getSize(find.byType(IconButton));
      expect(iconButtonSize.width, greaterThanOrEqualTo(48.0));
      expect(iconButtonSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('displays voice name with proper typography', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final nameText = tester.widget<Text>(find.text('Karen'));
      expect(nameText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('displays locale with subtitle styling', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final localeText = tester.widget<Text>(find.text('en-AU'));
      expect(localeText.style?.fontSize, lessThan(16.0)); // Subtitle styling
    });

    testWidgets('handles long voice names correctly', (tester) async {
      final longNameVoice = VoiceModel(
        name: 'Very Long Voice Name That Should Wrap Or Truncate',
        locale: 'en-US',
        identifier: 'long.voice.identifier',
      );

      await tester.pumpWidget(createTestWidget(voice: longNameVoice));

      expect(find.text('Very Long Voice Name That Should Wrap Or Truncate'), findsOneWidget);
      
      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles different voice locales', (tester) async {
      final voices = [
        VoiceModel(name: 'Pierre', locale: 'fr-FR', identifier: 'fr.voice'),
        VoiceModel(name: 'Hans', locale: 'de-DE', identifier: 'de.voice'),
        VoiceModel(name: 'Maria', locale: 'es-ES', identifier: 'es.voice'),
      ];

      for (final voice in voices) {
        await tester.pumpWidget(createTestWidget(voice: voice));
        
        expect(find.text(voice.name), findsOneWidget);
        expect(find.text(voice.locale), findsOneWidget);
      }
    });

    testWidgets('preview button has correct states', (tester) async {
      // Test play state
      await tester.pumpWidget(createTestWidget(isPreviewing: false));
      
      final playButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(playButton.tooltip, 'Preview voice');

      // Test stop state
      await tester.pumpWidget(createTestWidget(isPreviewing: true));
      
      final stopButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(stopButton.tooltip, 'Stop preview');
    });

    testWidgets('maintains state consistency during interaction', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap the tile to select
      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(onVoiceSelectedCalled, isTrue);

      // Reset and test preview
      onVoiceSelectedCalled = false;
      onPreviewCalled = false;
      
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(onPreviewCalled, isTrue);
      expect(onVoiceSelectedCalled, isFalse); // Should not trigger selection
    });

    testWidgets('supports keyboard navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Focus the tile
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Press enter to select
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(onVoiceSelectedCalled, isTrue);
    });

    testWidgets('handles theme changes correctly', (tester) async {
      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: VoiceListTile(
              voice: testVoice,
              isSelected: false,
              isPreviewing: false,
              onVoiceSelected: () {},
              onPreview: () {},
            ),
          ),
        ),
      );

      expect(find.text('Karen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}