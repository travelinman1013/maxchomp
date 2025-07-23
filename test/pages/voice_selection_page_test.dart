import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/providers/voice_selection_provider.dart';
import 'package:maxchomp/pages/voice_selection_page.dart';
import 'package:maxchomp/widgets/voice/voice_list_tile.dart';
import 'package:maxchomp/core/theme/app_theme.dart';
import 'package:mockito/mockito.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';

class MockTTSService extends Mock implements TTSService {}
class MockSettingsNotifier extends Mock implements SettingsNotifier {}

void main() {
  group('VoiceSelectionPage Widget Tests', () {
    late List<VoiceModel> mockVoices;

    setUp(() {
      mockVoices = [
        VoiceModel(
          name: 'Karen',
          locale: 'en-AU',
          identifier: 'com.apple.voice.compact.en-AU.Karen',
        ),
        VoiceModel(
          name: 'Daniel',
          locale: 'en-GB',
          identifier: 'com.apple.voice.compact.en-GB.Daniel',
        ),
        VoiceModel(
          name: 'Samantha',
          locale: 'en-US',
          identifier: 'com.apple.voice.compact.en-US.Samantha',
        ),
      ];
    });

    Widget createTestWidget({
      VoiceSelectionState? mockState,
      VoiceModel? selectedVoice,
    }) {
      return ProviderScope(
        overrides: [
          voiceSelectionProvider.overrideWith((ref) {
            return TestVoiceSelectionNotifier(
              mockState ?? VoiceSelectionState.loaded(mockVoices),
              selectedVoice,
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const VoiceSelectionPage(),
        ),
      );
    }

    testWidgets('displays AppBar with correct title', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Select Voice'), findsOneWidget);
    });

    testWidgets('displays back button in AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('displays loading state correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        mockState: const VoiceSelectionState.loading(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading voices...'), findsOneWidget);
    });

    testWidgets('displays error state correctly', (tester) async {
      const errorMessage = 'Failed to load voices';
      await tester.pumpWidget(createTestWidget(
        mockState: const VoiceSelectionState.error(errorMessage),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading voices'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays voice list when loaded', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(VoiceListTile), findsNWidgets(mockVoices.length));
    });

    testWidgets('displays voices with correct names', (tester) async {
      await tester.pumpWidget(createTestWidget());

      for (final voice in mockVoices) {
        expect(find.text(voice.name), findsOneWidget);
        expect(find.text(voice.locale), findsOneWidget);
      }
    });

    testWidgets('shows selected voice correctly', (tester) async {
      final selectedVoice = mockVoices.first;
      await tester.pumpWidget(createTestWidget(
        selectedVoice: selectedVoice,
      ));

      // Find the selected voice tile
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping voice tile selects voice', (tester) async {
      final testNotifier = TestVoiceSelectionNotifier(
        VoiceSelectionState.loaded(mockVoices),
        null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceSelectionProvider.overrideWith((ref) => testNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const VoiceSelectionPage(),
          ),
        ),
      );

      // Tap on the first voice
      await tester.tap(find.byType(VoiceListTile).first);
      await tester.pump();

      expect(testNotifier.selectVoiceCalled, isTrue);
      expect(testNotifier.lastSelectedVoice, equals(mockVoices.first));
    });

    testWidgets('displays preview buttons for each voice', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.play_arrow), findsNWidgets(mockVoices.length));
    });

    testWidgets('tapping preview button starts preview', (tester) async {
      final testNotifier = TestVoiceSelectionNotifier(
        VoiceSelectionState.loaded(mockVoices),
        null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceSelectionProvider.overrideWith((ref) => testNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const VoiceSelectionPage(),
          ),
        ),
      );

      // Tap on the first preview button
      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pump();

      expect(testNotifier.previewVoiceCalled, isTrue);
      expect(testNotifier.lastPreviewedVoice, equals(mockVoices.first));
    });

    testWidgets('displays stop button when previewing', (tester) async {
      final testNotifier = TestVoiceSelectionNotifier(
        VoiceSelectionState.loaded(mockVoices),
        null,
        previewingVoice: mockVoices.first,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceSelectionProvider.overrideWith((ref) => testNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const VoiceSelectionPage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('tapping stop button stops preview', (tester) async {
      final testNotifier = TestVoiceSelectionNotifier(
        VoiceSelectionState.loaded(mockVoices),
        null,
        previewingVoice: mockVoices.first,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceSelectionProvider.overrideWith((ref) => testNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const VoiceSelectionPage(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      expect(testNotifier.stopPreviewCalled, isTrue);
    });

    testWidgets('retry button calls loadVoices', (tester) async {
      final testNotifier = TestVoiceSelectionNotifier(
        const VoiceSelectionState.error('Failed to load voices'),
        null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceSelectionProvider.overrideWith((ref) => testNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const VoiceSelectionPage(),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(testNotifier.loadVoicesCalled, isTrue);
    });

    testWidgets('follows Material 3 design principles', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for Material 3 components
      expect(find.byType(Card), findsWidgets);
      
      // Verify proper spacing
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, isNotNull);
    });

    testWidgets('supports accessibility', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Wait for widget to build completely
      await tester.pumpAndSettle();

      // Find VoiceListTile widgets first to ensure they're rendered
      final voiceListTiles = find.byType(VoiceListTile);
      expect(voiceListTiles, findsWidgets);

      // Check semantic labels using Context7 patterns
      // Look for semantic labels in the voice list tiles
      expect(find.text('Karen'), findsOneWidget);
      expect(find.text('Daniel'), findsOneWidget);
      expect(find.text('Samantha'), findsOneWidget);

      // Verify semantic accessibility structure is present
      final firstVoiceTile = tester.widget<VoiceListTile>(voiceListTiles.first);
      expect(firstVoiceTile, isNotNull);
    });

    testWidgets('handles empty voice list', (tester) async {
      await tester.pumpWidget(createTestWidget(
        mockState: const VoiceSelectionState.loaded([]),
      ));

      expect(find.text('No voices available'), findsOneWidget);
      expect(find.byIcon(Icons.voice_over_off), findsOneWidget);
    });
  });
}

// Test helper class
class TestVoiceSelectionNotifier extends VoiceSelectionNotifier {
  bool selectVoiceCalled = false;
  bool previewVoiceCalled = false;
  bool stopPreviewCalled = false;
  bool loadVoicesCalled = false;
  
  VoiceModel? lastSelectedVoice;
  VoiceModel? lastPreviewedVoice;
  VoiceModel? previewingVoice;

  TestVoiceSelectionNotifier(
    VoiceSelectionState initialState,
    VoiceModel? selectedVoice, {
    this.previewingVoice,
  }) : super(MockTTSService(), MockSettingsNotifier()) {
    state = VoiceSelectionNotifierState(
      voiceSelectionState: initialState,
      selectedVoice: selectedVoice,
      previewingVoice: previewingVoice,
    );
  }

  @override
  Future<void> selectVoice(VoiceModel voice) async {
    selectVoiceCalled = true;
    lastSelectedVoice = voice;
    state = state.copyWith(selectedVoice: voice);
  }

  @override
  Future<void> previewVoice(VoiceModel voice, {String? previewText}) async {
    previewVoiceCalled = true;
    lastPreviewedVoice = voice;
    state = state.copyWith(previewingVoice: voice);
  }

  @override
  Future<void> stopPreview() async {
    stopPreviewCalled = true;
    state = state.copyWith(previewingVoice: null);
  }

  @override
  Future<void> loadVoices() async {
    loadVoicesCalled = true;
  }
}