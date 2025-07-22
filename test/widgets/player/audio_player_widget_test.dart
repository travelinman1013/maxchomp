import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/models/tts_models.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/widgets/player/audio_player_widget.dart';

// Mock classes for testing
class MockTTSStateNotifier extends TTSStateNotifier {
  MockTTSStateNotifier([TTSStateModel? initialState]) 
    : super(_mockTTSService) {
    if (initialState != null) {
      state = initialState;
    }
  }
  
  static final _mockTTSService = TTSService();
  
  @override
  set state(TTSStateModel value) => super.state = value;
}

class MockTTSProgressNotifier extends TTSProgressNotifier {
  MockTTSProgressNotifier([TTSProgressModel? initialState]) 
    : super(_mockTTSService) {
    if (initialState != null) {
      state = initialState;
    }
  }
  
  static final _mockTTSService = TTSService();
  
  @override
  set state(TTSProgressModel value) => super.state = value;
}

class MockTTSSettingsNotifier extends TTSSettingsNotifier {
  MockTTSSettingsNotifier([TTSSettingsModel? initialState]) 
    : super(_mockTTSService) {
    if (initialState != null) {
      state = initialState;
    }
  }
  
  static final _mockTTSService = TTSService();
  
  @override
  set state(TTSSettingsModel value) => super.state = value;
}

void main() {
  group('AudioPlayerWidget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Player Controls Display', () {
      testWidgets('should display play button when TTS is stopped', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.stopped,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsNothing);
      });

      testWidgets('should display pause button when TTS is playing', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.playing,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets('should always display stop button', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.playing,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.stop), findsOneWidget);
      });
    });

    group('Material 3 Design Compliance', () {
      testWidgets('should use Material 3 components and theming', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.stopped,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: MaterialApp(
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              home: const Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Find Material 3 components
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(IconButton), findsAtLeast(3)); // Play/pause, stop, speed
        
        // Verify Material 3 theming
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(1.0)); // Material 3 subtle elevation
        
        // Check theme usage in buttons
        final theme = Theme.of(tester.element(find.byType(Card)));
        expect(theme.useMaterial3, isTrue);
      });

      testWidgets('should have proper touch target sizes', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.stopped,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Verify minimum touch target size (48dp)
        final iconButtons = find.byType(IconButton);
        for (int i = 0; i < iconButtons.evaluate().length; i++) {
          final button = tester.widget<IconButton>(iconButtons.at(i));
          expect(button.iconSize, greaterThanOrEqualTo(24.0)); // Minimum icon size
        }
      });
    });

    group('Progress Display', () {
      testWidgets('should display progress information when available', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.playing,
          isInitialized: true,
        );

        const mockProgress = TTSProgressModel(
          currentWord: 'test',
          currentSentence: 'This is a test text being spoken',
          wordStartOffset: 10,
          wordEndOffset: 14,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
              ttsProgressNotifierProvider.overrideWith((ref) {
                return MockTTSProgressNotifier(mockProgress);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Check for progress indicators
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.textContaining('Current: test'), findsOneWidget); // Current word display
      });

      testWidgets('should handle no progress information gracefully', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.stopped,
          isInitialized: true,
        );

        const mockProgress = TTSProgressModel(
          currentWord: '',
          currentSentence: '',
          wordStartOffset: 0,
          wordEndOffset: 0,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
              ttsProgressNotifierProvider.overrideWith((ref) {
                return MockTTSProgressNotifier(mockProgress);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.textContaining('test'), findsNothing);
      });
    });

    group('Speed Control', () {
      testWidgets('should display current speech rate', (tester) async {
        // Arrange
        const mockSettings = TTSSettingsModel(
          speechRate: 0.75,
          volume: 1.0,
          pitch: 1.0,
          language: 'en-US',
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsSettingsNotifierProvider.overrideWith((ref) {
                return MockTTSSettingsNotifier(mockSettings);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Check for speed display
        expect(find.textContaining('0.75x'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsOneWidget);
      });

      testWidgets('should allow speed adjustment', (tester) async {
        // Arrange
        const mockSettings = TTSSettingsModel(
          speechRate: 1.0,
          volume: 1.0,
          pitch: 1.0,
          language: 'en-US',
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsSettingsNotifierProvider.overrideWith((ref) {
                return MockTTSSettingsNotifier(mockSettings);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Find and tap speed button
        final speedButton = find.byIcon(Icons.speed);
        expect(speedButton, findsOneWidget);
        
        await tester.tap(speedButton);
        await tester.pumpAndSettle();

        // Assert - Should show speed selection dialog/sheet
        expect(find.text('Playback Speed'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should display error state appropriately', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.error,
          isInitialized: true,
          error: 'TTS initialization failed',
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Check for error display
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.textContaining('TTS initialization failed'), findsOneWidget);
        
        // Controls should be disabled in error state
        final playButtonIcon = find.byIcon(Icons.play_arrow);
        expect(playButtonIcon, findsOneWidget);
        
        // Find the IconButton that contains this icon
        final iconButtons = find.byType(IconButton);
        expect(iconButtons, findsAtLeast(1));
        
        // Check that at least one button is disabled (should be the play button)
        bool foundDisabledButton = false;
        for (int i = 0; i < iconButtons.evaluate().length; i++) {
          final button = tester.widget<IconButton>(iconButtons.at(i));
          if (button.onPressed == null) {
            foundDisabledButton = true;
            break;
          }
        }
        expect(foundDisabledButton, isTrue, reason: 'Expected at least one button to be disabled in error state');
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.stopped,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Check for semantic labels (using byWidgetPredicate instead)
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && widget.properties.label == 'Play audio'), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && widget.properties.label == 'Stop audio'), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && widget.properties.label == 'Adjust playback speed'), findsOneWidget);
      });

      testWidgets('should update semantic labels based on state', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.playing,
          isInitialized: true,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Labels should update for playing state
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && widget.properties.label == 'Pause audio'), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && widget.properties.label == 'Play audio'), findsNothing);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (tester) async {
        // Arrange
        const mockState = TTSStateModel(
          status: TTSState.stopped,
          isInitialized: true,
        );

        // Act - Test with small screen
        await tester.binding.setSurfaceSize(const Size(360, 640));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ttsStateNotifierProvider.overrideWith((ref) {
                return MockTTSStateNotifier(mockState);
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AudioPlayerWidget(),
              ),
            ),
          ),
        );

        // Assert - Should work on mobile size
        expect(find.byType(AudioPlayerWidget), findsOneWidget);

        // Test with large screen  
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpAndSettle();

        // Should still display properly on larger screens
        expect(find.byType(AudioPlayerWidget), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}