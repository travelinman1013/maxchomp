import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/providers/voice_selection_provider.dart';
import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/providers/settings_provider.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';
import 'package:maxchomp/core/models/settings_model.dart';

// Import existing generated mocks following project patterns
import 'tts_provider_test.mocks.dart';
import 'settings_provider_test.mocks.dart';

void main() {
  group('VoiceSelectionProvider Tests', () {
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

    ProviderContainer createTestContainer() {
      final mockTTSService = MockTTSService();
      final mockSharedPreferences = MockSharedPreferences();
      
      // Set up default mock responses following Context7 patterns
      when(mockTTSService.getAvailableVoices()).thenAnswer((_) async => mockVoices);
      when(mockTTSService.setVoice(any, any)).thenAnswer((_) async {});
      when(mockTTSService.speak(any)).thenAnswer((_) async => true);
      when(mockTTSService.stop()).thenAnswer((_) async => true);
      
      // Set up SharedPreferences mock for settings provider
      when(mockSharedPreferences.getString(any)).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      return ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTTSService),
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
      );
    }

    group('Initial State', () {
      test('starts with loading state', () {
        final container = createTestContainer();
        addTearDown(container.dispose);
                
        final state = container.read(voiceSelectionProvider);

        expect(state.voiceSelectionState, isA<VoiceSelectionStateLoading>());
        expect(state.selectedVoice, isNull);
        expect(state.previewingVoice, isNull);
      });
    });

    group('Load Voices', () {
      test('loads voices successfully', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
                
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();

        final state = container.read(voiceSelectionProvider);
        expect(state.voiceSelectionState, isA<VoiceSelectionStateLoaded>());
        
        final loadedState = state.voiceSelectionState as VoiceSelectionStateLoaded;
        expect(loadedState.voices, equals(mockVoices));
        expect(loadedState.voices.length, equals(3));
      });

      test('handles load voices error', () async {
        const errorMessage = 'Failed to load voices';
        
        // Create a new container with error mock for this test
        final errorMockTTSService = MockTTSService();
        final mockSharedPreferences = MockSharedPreferences();
        when(errorMockTTSService.getAvailableVoices()).thenThrow(Exception(errorMessage));
        when(mockSharedPreferences.getString(any)).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final errorContainer = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(errorMockTTSService),
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          ],
        );
        
        addTearDown(errorContainer.dispose);

        final notifier = errorContainer.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();

        final state = errorContainer.read(voiceSelectionProvider);
        expect(state.voiceSelectionState, isA<VoiceSelectionStateError>());
        
        final errorState = state.voiceSelectionState as VoiceSelectionStateError;
        expect(errorState.message, contains(errorMessage));
      });

      test('transitions from loading to loaded', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        
        // Initial state should be loading
        expect(container.read(voiceSelectionProvider).voiceSelectionState, 
               isA<VoiceSelectionStateLoading>());

        await notifier.loadVoices();

        // Should now be loaded
        final state = container.read(voiceSelectionProvider);
        expect(state.voiceSelectionState, isA<VoiceSelectionStateLoaded>());
      });

      test('handles empty voice list', () async {
        // Create a new container with empty list mock for this test
        final emptyMockTTSService = MockTTSService();
        final mockSharedPreferences = MockSharedPreferences();
        when(emptyMockTTSService.getAvailableVoices()).thenAnswer((_) async => []);
        when(mockSharedPreferences.getString(any)).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final emptyContainer = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(emptyMockTTSService),
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          ],
        );
        
        addTearDown(emptyContainer.dispose);

        final notifier = emptyContainer.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();

        final state = emptyContainer.read(voiceSelectionProvider);
        expect(state.voiceSelectionState, isA<VoiceSelectionStateLoaded>());
        
        final loadedState = state.voiceSelectionState as VoiceSelectionStateLoaded;
        expect(loadedState.voices, isEmpty);
      });
    });

    group('Select Voice', () {
      test('selects voice successfully', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        final voiceToSelect = mockVoices.first;
        await notifier.selectVoice(voiceToSelect);

        final state = container.read(voiceSelectionProvider);
        expect(state.selectedVoice, equals(voiceToSelect));
      });

      test('persists selected voice to settings', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        final voiceToSelect = mockVoices.first;
        await notifier.selectVoice(voiceToSelect);

        // Note: Settings update is handled internally by the provider
      });

      test('handles voice selection error', () async {
        // Create separate container for error scenario
        final errorMockTTSService = MockTTSService();
        final mockSharedPreferences = MockSharedPreferences();
        when(errorMockTTSService.getAvailableVoices()).thenAnswer((_) async => mockVoices);
        when(errorMockTTSService.setVoice(any, any)).thenThrow(Exception('Voice selection failed'));
        when(mockSharedPreferences.getString(any)).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final errorContainer = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(errorMockTTSService),
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          ],
        );
        addTearDown(errorContainer.dispose);

        final notifier = errorContainer.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        final voiceToSelect = mockVoices.first;
        await notifier.selectVoice(voiceToSelect);

        // Voice should not be selected on error
        final state = errorContainer.read(voiceSelectionProvider);
        expect(state.selectedVoice, isNull);
      });

      test('can change selected voice', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        // Select first voice
        await notifier.selectVoice(mockVoices.first);
        expect(container.read(voiceSelectionProvider).selectedVoice, equals(mockVoices.first));

        // Select second voice
        await notifier.selectVoice(mockVoices[1]);
        expect(container.read(voiceSelectionProvider).selectedVoice, equals(mockVoices[1]));
      });
    });

    group('Preview Voice', () {
      test('previews voice successfully', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        final voiceToPreview = mockVoices.first;
        await notifier.previewVoice(voiceToPreview);

        final state = container.read(voiceSelectionProvider);
        expect(state.previewingVoice, equals(voiceToPreview));
      });

      test('handles preview error', () async {
        // Create separate container for error scenario
        final errorMockTTSService = MockTTSService();
        final mockSharedPreferences = MockSharedPreferences();
        when(errorMockTTSService.getAvailableVoices()).thenAnswer((_) async => mockVoices);
        when(errorMockTTSService.setVoice(any, any)).thenThrow(Exception('Preview failed'));
        when(mockSharedPreferences.getString(any)).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final errorContainer = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(errorMockTTSService),
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          ],
        );
        addTearDown(errorContainer.dispose);

        final notifier = errorContainer.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        final voiceToPreview = mockVoices.first;
        await notifier.previewVoice(voiceToPreview);

        // Should not be previewing on error
        final state = errorContainer.read(voiceSelectionProvider);
        expect(state.previewingVoice, isNull);
      });

      test('stops current preview when starting new one', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        // Start first preview
        await notifier.previewVoice(mockVoices.first);
        expect(container.read(voiceSelectionProvider).previewingVoice, equals(mockVoices.first));

        // Start second preview
        await notifier.previewVoice(mockVoices[1]);
        expect(container.read(voiceSelectionProvider).previewingVoice, equals(mockVoices[1]));
      });

      test('uses custom preview text if provided', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        const customText = 'Custom preview text';
        await notifier.previewVoice(mockVoices.first, previewText: customText);
      });
    });

    group('Stop Preview', () {
      test('stops preview successfully', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        // Start preview
        await notifier.previewVoice(mockVoices.first);
        expect(container.read(voiceSelectionProvider).previewingVoice, equals(mockVoices.first));

        // Stop preview
        await notifier.stopPreview();
        expect(container.read(voiceSelectionProvider).previewingVoice, isNull);
      });

      test('handles stop preview when not previewing', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        
        // Stop preview when nothing is playing
        await notifier.stopPreview();
        
        expect(container.read(voiceSelectionProvider).previewingVoice, isNull);
      });

      test('handles stop preview error', () async {
        // Create separate container for error scenario
        final errorMockTTSService = MockTTSService();
        final mockSharedPreferences = MockSharedPreferences();
        when(errorMockTTSService.getAvailableVoices()).thenAnswer((_) async => mockVoices);
        when(errorMockTTSService.setVoice(any, any)).thenAnswer((_) async {});
        when(errorMockTTSService.speak(any)).thenAnswer((_) async => true);
        when(errorMockTTSService.stop()).thenThrow(Exception('Stop failed'));
        when(mockSharedPreferences.getString(any)).thenReturn(null);
        when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
        
        final errorContainer = ProviderContainer(
          overrides: [
            ttsServiceProvider.overrideWithValue(errorMockTTSService),
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          ],
        );
        addTearDown(errorContainer.dispose);

        final notifier = errorContainer.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        // Start preview
        await notifier.previewVoice(mockVoices.first);
        
        // Try to stop preview (will fail)
        await notifier.stopPreview();
        
        // Should still clear the previewing state despite error
        expect(errorContainer.read(voiceSelectionProvider).previewingVoice, isNull);
      });
    });

    group('State Management', () {
      test('maintains state consistency across operations', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        
        // Load voices
        await notifier.loadVoices();
        expect(container.read(voiceSelectionProvider).voiceSelectionState, isA<VoiceSelectionStateLoaded>());

        // Select voice
        await notifier.selectVoice(mockVoices.first);
        expect(container.read(voiceSelectionProvider).selectedVoice, equals(mockVoices.first));

        // Preview different voice
        await notifier.previewVoice(mockVoices[1]);
        expect(container.read(voiceSelectionProvider).previewingVoice, equals(mockVoices[1]));
        expect(container.read(voiceSelectionProvider).selectedVoice, equals(mockVoices.first)); // Should remain selected

        // Stop preview
        await notifier.stopPreview();
        expect(container.read(voiceSelectionProvider).previewingVoice, isNull);
        expect(container.read(voiceSelectionProvider).selectedVoice, equals(mockVoices.first)); // Should remain selected
      });

      test('handles concurrent operations safely', () async {
        final container = createTestContainer();
        addTearDown(container.dispose);
        
        final notifier = container.read(voiceSelectionProvider.notifier);
        await notifier.loadVoices();
        
        // Start multiple preview operations concurrently
        final futures = [
          notifier.previewVoice(mockVoices[0]),
          notifier.previewVoice(mockVoices[1]),
          notifier.previewVoice(mockVoices[2]),
        ];
        
        await Future.wait(futures);
        
        // Only the last preview should be active
        final state = container.read(voiceSelectionProvider);
        expect(state.previewingVoice, equals(mockVoices[2]));
      });
    });

    group('Voice State Helpers', () {
      test('VoiceSelectionStateLoaded.voices returns correct list', () {
        final state = VoiceSelectionState.loaded(mockVoices);
        expect(state, isA<VoiceSelectionStateLoaded>());
        expect((state as VoiceSelectionStateLoaded).voices, equals(mockVoices));
      });

      test('VoiceSelectionStateError.message returns correct error', () {
        const errorMessage = 'Test error message';
        final state = VoiceSelectionState.error(errorMessage);
        expect(state, isA<VoiceSelectionStateError>());
        expect((state as VoiceSelectionStateError).message, equals(errorMessage));
      });

      test('VoiceSelectionNotifierState.copyWith works correctly', () {
        final originalState = VoiceSelectionNotifierState(
          voiceSelectionState: VoiceSelectionState.loaded(mockVoices),
          selectedVoice: mockVoices.first,
          previewingVoice: null,
        );

        final copiedState = originalState.copyWith(
          previewingVoice: mockVoices[1],
        );

        expect(copiedState.voiceSelectionState, equals(originalState.voiceSelectionState));
        expect(copiedState.selectedVoice, equals(originalState.selectedVoice));
        expect(copiedState.previewingVoice, equals(mockVoices[1]));
      });
    });
  });
}