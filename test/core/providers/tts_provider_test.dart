import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/models/voice_model.dart';
import 'package:maxchomp/core/providers/tts_provider.dart';

import 'tts_provider_test.mocks.dart';

@GenerateMocks([TTSService])
void main() {
  group('TTS Providers', () {
    late MockTTSService mockTTSService;
    late ProviderContainer container;

    setUp(() {
      mockTTSService = MockTTSService();
      
      // Mock streams
      when(mockTTSService.stateStream).thenAnswer((_) => Stream<TTSState>.empty());
      when(mockTTSService.progressStream).thenAnswer((_) => Stream<String>.empty());
      
      // Mock default property values
      when(mockTTSService.currentState).thenReturn(TTSState.stopped);
      when(mockTTSService.isInitialized).thenReturn(false);
      when(mockTTSService.currentSpeechRate).thenReturn(1.0);
      when(mockTTSService.currentVolume).thenReturn(1.0);
      when(mockTTSService.currentPitch).thenReturn(1.0);
      when(mockTTSService.currentLanguage).thenReturn('en-US');
      when(mockTTSService.currentWord).thenReturn('');
      when(mockTTSService.currentSentence).thenReturn('');
      when(mockTTSService.wordStartOffset).thenReturn(0);
      when(mockTTSService.wordEndOffset).thenReturn(0);
      when(mockTTSService.lastError).thenReturn('');
      
      container = ProviderContainer(
        overrides: [
          ttsServiceProvider.overrideWithValue(mockTTSService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('ttsServiceProvider', () {
      test('should provide TTSService instance', () {
        // Act
        final ttsService = container.read(ttsServiceProvider);

        // Assert
        expect(ttsService, isA<TTSService>());
      });
    });

    group('ttsStateNotifierProvider', () {
      test('should initialize with stopped state', () {
        // Arrange
        when(mockTTSService.currentState).thenReturn(TTSState.stopped);
        when(mockTTSService.isInitialized).thenReturn(false);

        // Act
        final state = container.read(ttsStateNotifierProvider);

        // Assert
        expect(state.status, equals(TTSState.stopped));
        expect(state.isInitialized, isFalse);
      });

      test('should initialize TTS service', () async {
        // Arrange
        when(mockTTSService.initialize()).thenAnswer((_) async {});
        when(mockTTSService.isInitialized).thenReturn(true);
        when(mockTTSService.currentState).thenReturn(TTSState.stopped);

        // Act
        await container.read(ttsStateNotifierProvider.notifier).initialize();

        // Assert
        verify(mockTTSService.initialize()).called(1);
      });

      test('should speak text successfully', () async {
        // Arrange
        when(mockTTSService.speak(any)).thenAnswer((_) async => true);
        when(mockTTSService.currentState).thenReturn(TTSState.playing);

        // Act
        final result = await container.read(ttsStateNotifierProvider.notifier).speak('Hello, world!');

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.speak('Hello, world!')).called(1);
      });

      test('should handle speak failure', () async {
        // Arrange
        when(mockTTSService.speak(any)).thenAnswer((_) async => false);
        when(mockTTSService.currentState).thenReturn(TTSState.error);

        // Act
        final result = await container.read(ttsStateNotifierProvider.notifier).speak('Hello, world!');

        // Assert
        expect(result, isFalse);
        verify(mockTTSService.speak('Hello, world!')).called(1);
      });

      test('should stop speech', () async {
        // Arrange
        when(mockTTSService.stop()).thenAnswer((_) async => true);
        when(mockTTSService.currentState).thenReturn(TTSState.stopped);

        // Act
        final result = await container.read(ttsStateNotifierProvider.notifier).stop();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.stop()).called(1);
      });

      test('should pause speech', () async {
        // Arrange
        when(mockTTSService.pause()).thenAnswer((_) async => true);
        when(mockTTSService.currentState).thenReturn(TTSState.paused);

        // Act
        final result = await container.read(ttsStateNotifierProvider.notifier).pause();

        // Assert
        expect(result, isTrue);
        verify(mockTTSService.pause()).called(1);
      });
    });

    group('ttsSettingsNotifierProvider', () {
      test('should initialize with default settings', () {
        // Act
        final settings = container.read(ttsSettingsNotifierProvider);

        // Assert
        expect(settings.speechRate, equals(1.0));
        expect(settings.volume, equals(1.0));
        expect(settings.pitch, equals(1.0));
        expect(settings.language, equals('en-US'));
        expect(settings.selectedVoice, isNull);
      });

      test('should update speech rate', () async {
        // Arrange
        when(mockTTSService.setSpeechRate(any)).thenAnswer((_) async {});
        when(mockTTSService.currentSpeechRate).thenReturn(1.5);

        // Act
        await container.read(ttsSettingsNotifierProvider.notifier).updateSpeechRate(1.5);

        // Assert
        verify(mockTTSService.setSpeechRate(1.5)).called(1);
        final settings = container.read(ttsSettingsNotifierProvider);
        expect(settings.speechRate, equals(1.5));
      });

      test('should update volume', () async {
        // Arrange
        when(mockTTSService.setVolume(any)).thenAnswer((_) async {});
        when(mockTTSService.currentVolume).thenReturn(0.8);

        // Act
        await container.read(ttsSettingsNotifierProvider.notifier).updateVolume(0.8);

        // Assert
        verify(mockTTSService.setVolume(0.8)).called(1);
        final settings = container.read(ttsSettingsNotifierProvider);
        expect(settings.volume, equals(0.8));
      });

      test('should update pitch', () async {
        // Arrange
        when(mockTTSService.setPitch(any)).thenAnswer((_) async {});
        when(mockTTSService.currentPitch).thenReturn(1.2);

        // Act
        await container.read(ttsSettingsNotifierProvider.notifier).updatePitch(1.2);

        // Assert
        verify(mockTTSService.setPitch(1.2)).called(1);
        final settings = container.read(ttsSettingsNotifierProvider);
        expect(settings.pitch, equals(1.2));
      });

      test('should update language', () async {
        // Arrange
        when(mockTTSService.setLanguage(any)).thenAnswer((_) async {});
        when(mockTTSService.currentLanguage).thenReturn('fr-FR');

        // Act
        await container.read(ttsSettingsNotifierProvider.notifier).updateLanguage('fr-FR');

        // Assert
        verify(mockTTSService.setLanguage('fr-FR')).called(1);
        final settings = container.read(ttsSettingsNotifierProvider);
        expect(settings.language, equals('fr-FR'));
      });

      test('should update selected voice', () async {
        // Arrange
        final voice = VoiceModel(name: 'Karen', locale: 'en-AU');
        when(mockTTSService.setVoice(any, any)).thenAnswer((_) async {});

        // Act
        await container.read(ttsSettingsNotifierProvider.notifier).updateSelectedVoice(voice);

        // Assert
        verify(mockTTSService.setVoice('Karen', 'en-AU')).called(1);
        final settings = container.read(ttsSettingsNotifierProvider);
        expect(settings.selectedVoice, equals(voice));
      });
    });

    group('availableVoicesProvider', () {
      test('should provide list of available voices', () async {
        // Arrange
        final voices = [
          VoiceModel(name: 'Karen', locale: 'en-AU'),
          VoiceModel(name: 'Alex', locale: 'en-US'),
          VoiceModel(name: 'Marie', locale: 'fr-FR'),
        ];
        when(mockTTSService.getAvailableVoices()).thenAnswer((_) async => voices);

        // Act
        final result = await container.read(availableVoicesProvider.future);

        // Assert
        expect(result, hasLength(3));
        expect(result[0].name, equals('Karen'));
        expect(result[1].name, equals('Alex'));
        expect(result[2].name, equals('Marie'));
        verify(mockTTSService.getAvailableVoices()).called(1);
      });

      test('should handle empty voices list', () async {
        // Arrange
        when(mockTTSService.getAvailableVoices()).thenAnswer((_) async => []);

        // Act
        final result = await container.read(availableVoicesProvider.future);

        // Assert
        expect(result, isEmpty);
        verify(mockTTSService.getAvailableVoices()).called(1);
      });
    });

    group('availableLanguagesProvider', () {
      test('should provide list of available languages', () async {
        // Arrange
        final languages = ['en-US', 'en-AU', 'fr-FR', 'es-ES'];
        when(mockTTSService.getAvailableLanguages()).thenAnswer((_) async => languages);

        // Act
        final result = await container.read(availableLanguagesProvider.future);

        // Assert
        expect(result, equals(languages));
        verify(mockTTSService.getAvailableLanguages()).called(1);
      });
    });

    group('ttsProgressNotifierProvider', () {
      test('should initialize with empty progress', () {
        // Act
        final progress = container.read(ttsProgressNotifierProvider);

        // Assert
        expect(progress.currentWord, isEmpty);
        expect(progress.currentSentence, isEmpty);
        expect(progress.wordStartOffset, equals(0));
        expect(progress.wordEndOffset, equals(0));
      });

      test('should update progress from TTS service', () {
        // Arrange
        when(mockTTSService.currentWord).thenReturn('Hello');
        when(mockTTSService.currentSentence).thenReturn('Hello world test');
        when(mockTTSService.wordStartOffset).thenReturn(0);
        when(mockTTSService.wordEndOffset).thenReturn(5);

        // Act
        container.read(ttsProgressNotifierProvider.notifier).updateFromService(mockTTSService);

        // Assert
        final progress = container.read(ttsProgressNotifierProvider);
        expect(progress.currentWord, equals('Hello'));
        expect(progress.currentSentence, equals('Hello world test'));
        expect(progress.wordStartOffset, equals(0));
        expect(progress.wordEndOffset, equals(5));
      });
    });

    group('isLanguageAvailableProvider', () {
      test('should check if language is available', () async {
        // Arrange
        when(mockTTSService.isLanguageAvailable('es-ES')).thenAnswer((_) async => true);

        // Act
        final isAvailable = await container.read(isLanguageAvailableProvider('es-ES').future);

        // Assert
        expect(isAvailable, isTrue);
        verify(mockTTSService.isLanguageAvailable('es-ES')).called(1);
      });

      test('should handle language not available', () async {
        // Arrange
        when(mockTTSService.isLanguageAvailable('zh-CN')).thenAnswer((_) async => false);

        // Act
        final isAvailable = await container.read(isLanguageAvailableProvider('zh-CN').future);

        // Assert
        expect(isAvailable, isFalse);
        verify(mockTTSService.isLanguageAvailable('zh-CN')).called(1);
      });
    });
  });
}