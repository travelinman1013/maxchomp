import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:maxchomp/core/services/tts_service.dart';
import 'package:maxchomp/core/models/tts_state.dart';
import 'package:maxchomp/core/models/voice_model.dart';

import 'tts_service_test.mocks.dart';

@GenerateMocks([FlutterTts])
void main() {
  group('TTSService', () {
    late TTSService ttsService;
    late MockFlutterTts mockFlutterTts;

    setUp(() {
      mockFlutterTts = MockFlutterTts();
      ttsService = TTSService(flutterTts: mockFlutterTts);
    });

    group('initialization', () {
      test('should initialize with correct default settings', () {
        expect(ttsService.currentState, equals(TTSState.stopped));
        expect(ttsService.isInitialized, isFalse);
      });

      test('should initialize TTS service with default settings', () async {
        // Arrange
        when(mockFlutterTts.setSpeechRate(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setVolume(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setPitch(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setLanguage(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.awaitSpeakCompletion(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.initialize();

        // Assert
        expect(ttsService.isInitialized, isTrue);
        verify(mockFlutterTts.setSpeechRate(1.0)).called(1);
        verify(mockFlutterTts.setVolume(1.0)).called(1);
        verify(mockFlutterTts.setPitch(1.0)).called(1);
        verify(mockFlutterTts.setLanguage('en-US')).called(1);
        verify(mockFlutterTts.awaitSpeakCompletion(true)).called(1);
      });

      test('should set up TTS event handlers during initialization', () async {
        // Arrange
        when(mockFlutterTts.setSpeechRate(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setVolume(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setPitch(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setLanguage(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.awaitSpeakCompletion(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.initialize();

        // Assert
        verify(mockFlutterTts.setStartHandler(any)).called(1);
        verify(mockFlutterTts.setCompletionHandler(any)).called(1);
        verify(mockFlutterTts.setProgressHandler(any)).called(1);
        verify(mockFlutterTts.setErrorHandler(any)).called(1);
        verify(mockFlutterTts.setCancelHandler(any)).called(1);
        verify(mockFlutterTts.setPauseHandler(any)).called(1);
        verify(mockFlutterTts.setContinueHandler(any)).called(1);
      });
    });

    group('voice management', () {
      test('should get available voices', () async {
        // Arrange
        final mockVoices = [
          {'name': 'Karen', 'locale': 'en-AU'},
          {'name': 'Alex', 'locale': 'en-US'},
          {'name': 'Marie', 'locale': 'fr-FR'},
        ];
        when(mockFlutterTts.getVoices).thenAnswer((_) async => mockVoices);

        // Act
        final voices = await ttsService.getAvailableVoices();

        // Assert
        expect(voices, hasLength(3));
        expect(voices[0].name, equals('Karen'));
        expect(voices[0].locale, equals('en-AU'));
        expect(voices[1].name, equals('Alex'));
        expect(voices[1].locale, equals('en-US'));
        verify(mockFlutterTts.getVoices).called(1);
      });

      test('should set voice by name and locale', () async {
        // Arrange
        when(mockFlutterTts.setVoice(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.setVoice('Karen', 'en-AU');

        // Assert
        verify(mockFlutterTts.setVoice({'name': 'Karen', 'locale': 'en-AU'})).called(1);
      });

      test('should get default voice', () async {
        // Arrange
        final defaultVoice = {'name': 'Alex', 'locale': 'en-US'};
        when(mockFlutterTts.getDefaultVoice).thenAnswer((_) async => defaultVoice);

        // Act
        final voice = await ttsService.getDefaultVoice();

        // Assert
        expect(voice?.name, equals('Alex'));
        expect(voice?.locale, equals('en-US'));
        verify(mockFlutterTts.getDefaultVoice).called(1);
      });

      test('should handle null default voice', () async {
        // Arrange
        when(mockFlutterTts.getDefaultVoice).thenAnswer((_) async => null);

        // Act
        final voice = await ttsService.getDefaultVoice();

        // Assert
        expect(voice, isNull);
        verify(mockFlutterTts.getDefaultVoice).called(1);
      });
    });

    group('speech parameters', () {
      test('should set speech rate within valid range', () async {
        // Arrange
        when(mockFlutterTts.setSpeechRate(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.setSpeechRate(1.5);

        // Assert
        expect(ttsService.currentSpeechRate, equals(1.5));
        verify(mockFlutterTts.setSpeechRate(1.5)).called(1);
      });

      test('should clamp speech rate to valid range', () async {
        // Arrange
        when(mockFlutterTts.setSpeechRate(any)).thenAnswer((_) async => 1);

        // Act - test lower bound
        await ttsService.setSpeechRate(-0.5);
        expect(ttsService.currentSpeechRate, equals(0.1));
        
        // Act - test upper bound
        await ttsService.setSpeechRate(5.0);
        expect(ttsService.currentSpeechRate, equals(3.0));

        // Assert
        verify(mockFlutterTts.setSpeechRate(0.1)).called(1);
        verify(mockFlutterTts.setSpeechRate(3.0)).called(1);
      });

      test('should set volume within valid range', () async {
        // Arrange
        when(mockFlutterTts.setVolume(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.setVolume(0.8);

        // Assert
        expect(ttsService.currentVolume, equals(0.8));
        verify(mockFlutterTts.setVolume(0.8)).called(1);
      });

      test('should set pitch within valid range', () async {
        // Arrange
        when(mockFlutterTts.setPitch(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.setPitch(1.2);

        // Assert
        expect(ttsService.currentPitch, equals(1.2));
        verify(mockFlutterTts.setPitch(1.2)).called(1);
      });
    });

    group('text-to-speech playback', () {
      test('should speak text successfully', () async {
        // Arrange
        when(mockFlutterTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        final result = await ttsService.speak('Hello, world!');

        // Assert
        expect(result, isTrue);
        verify(mockFlutterTts.speak('Hello, world!')).called(1);
      });

      test('should handle speak failure', () async {
        // Arrange
        when(mockFlutterTts.speak(any)).thenAnswer((_) async => 0);

        // Act
        final result = await ttsService.speak('Hello, world!');

        // Assert
        expect(result, isFalse);
        verify(mockFlutterTts.speak('Hello, world!')).called(1);
      });

      test('should stop speech successfully', () async {
        // Arrange
        when(mockFlutterTts.stop()).thenAnswer((_) async => 1);

        // Act
        final result = await ttsService.stop();

        // Assert
        expect(result, isTrue);
        verify(mockFlutterTts.stop()).called(1);
      });

      test('should pause speech successfully', () async {
        // Arrange
        when(mockFlutterTts.pause()).thenAnswer((_) async => 1);

        // Act
        final result = await ttsService.pause();

        // Assert
        expect(result, isTrue);
        verify(mockFlutterTts.pause()).called(1);
      });
    });

    group('language management', () {
      test('should get available languages', () async {
        // Arrange
        final languages = ['en-US', 'en-AU', 'fr-FR', 'es-ES'];
        when(mockFlutterTts.getLanguages).thenAnswer((_) async => languages);

        // Act
        final result = await ttsService.getAvailableLanguages();

        // Assert
        expect(result, equals(languages));
        verify(mockFlutterTts.getLanguages).called(1);
      });

      test('should set language successfully', () async {
        // Arrange
        when(mockFlutterTts.setLanguage(any)).thenAnswer((_) async => 1);

        // Act
        await ttsService.setLanguage('fr-FR');

        // Assert
        expect(ttsService.currentLanguage, equals('fr-FR'));
        verify(mockFlutterTts.setLanguage('fr-FR')).called(1);
      });

      test('should check language availability', () async {
        // Arrange
        when(mockFlutterTts.isLanguageAvailable(any)).thenAnswer((_) async => true);

        // Act
        final isAvailable = await ttsService.isLanguageAvailable('es-ES');

        // Assert
        expect(isAvailable, isTrue);
        verify(mockFlutterTts.isLanguageAvailable('es-ES')).called(1);
      });
    });

    group('state management and callbacks', () {
      test('should update state when speech starts', () async {
        // This test simulates the state change callback being called
        // In real implementation, the callback would be set during initialization
        
        // Act
        ttsService.onSpeechStart();

        // Assert
        expect(ttsService.currentState, equals(TTSState.playing));
      });

      test('should update state when speech completes', () async {
        // Act
        ttsService.onSpeechComplete();

        // Assert
        expect(ttsService.currentState, equals(TTSState.stopped));
      });

      test('should update state when speech is paused', () async {
        // Act
        ttsService.onSpeechPause();

        // Assert
        expect(ttsService.currentState, equals(TTSState.paused));
      });

      test('should update state when speech is continued', () async {
        // Act
        ttsService.onSpeechContinue();

        // Assert
        expect(ttsService.currentState, equals(TTSState.playing));
      });

      test('should update state and clear progress on error', () async {
        // Act
        ttsService.onSpeechError('Test error message');

        // Assert
        expect(ttsService.currentState, equals(TTSState.stopped));
        expect(ttsService.lastError, equals('Test error message'));
      });

      test('should track progress during speech', () async {
        // Act
        ttsService.onSpeechProgress('Hello world test', 0, 5, 'Hello');

        // Assert
        expect(ttsService.currentWord, equals('Hello'));
        expect(ttsService.currentSentence, equals('Hello world test'));
        expect(ttsService.wordStartOffset, equals(0));
        expect(ttsService.wordEndOffset, equals(5));
      });
    });

    group('dispose', () {
      test('should clean up resources when disposed', () async {
        // Arrange
        when(mockFlutterTts.stop()).thenAnswer((_) async => 1);

        // Act
        await ttsService.dispose();

        // Assert
        expect(ttsService.currentState, equals(TTSState.stopped));
        verify(mockFlutterTts.stop()).called(1);
      });
    });
  });
}