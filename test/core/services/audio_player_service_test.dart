import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:maxchomp/core/services/audio_player_service.dart';
import 'package:maxchomp/core/models/audio_playback_state_model.dart';

import 'audio_player_service_test.mocks.dart';

@GenerateMocks([AudioPlayer])
void main() {
  group('AudioPlayerService Tests', () {
    late AudioPlayerService audioPlayerService;
    late MockAudioPlayer mockAudioPlayer;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      
      // Set up default stream mocks to prevent MissingStubError
      when(mockAudioPlayer.playerStateStream).thenAnswer((_) => Stream.value(
        PlayerState(false, ProcessingState.idle),
      ));
      when(mockAudioPlayer.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
      when(mockAudioPlayer.durationStream).thenAnswer((_) => Stream.value(null));
      
      audioPlayerService = AudioPlayerService(audioPlayer: mockAudioPlayer);
    });

    tearDown(() {
      audioPlayerService.dispose();
    });

    group('Initialization', () {
      test('should initialize with stopped state', () {
        expect(audioPlayerService.playbackState, AudioPlaybackStateModel.stopped());
      });

      test('should setup player state stream', () {
        // Act
        audioPlayerService.initialize();

        // Assert
        verify(mockAudioPlayer.playerStateStream).called(1);
        verify(mockAudioPlayer.positionStream).called(1);
        verify(mockAudioPlayer.durationStream).called(1);
      });
    });

    group('Audio File Playback', () {
      test('should play audio file successfully', () async {
        // Arrange
        const audioPath = '/path/to/audio.mp3';
        when(mockAudioPlayer.setFilePath(audioPath))
            .thenAnswer((_) async => const Duration(minutes: 5));
        when(mockAudioPlayer.play()).thenAnswer((_) async {});
        when(mockAudioPlayer.playerStateStream).thenAnswer((_) => Stream.value(
          PlayerState(true, ProcessingState.ready),
        ));

        // Act
        await audioPlayerService.playAudioFile(audioPath);

        // Assert
        verify(mockAudioPlayer.setFilePath(audioPath)).called(1);
        verify(mockAudioPlayer.play()).called(1);
      });

      test('should handle play audio file failure', () async {
        // Arrange
        const audioPath = '/path/to/invalid.mp3';
        when(mockAudioPlayer.setFilePath(audioPath))
            .thenThrow(Exception('File not found'));

        // Act & Assert
        expect(
          () => audioPlayerService.playAudioFile(audioPath),
          throwsException,
        );
      });

      test('should play from URL successfully', () async {
        // Arrange
        const audioUrl = 'https://example.com/audio.mp3';
        when(mockAudioPlayer.setUrl(audioUrl))
            .thenAnswer((_) async => const Duration(minutes: 3));
        when(mockAudioPlayer.play()).thenAnswer((_) async {});

        // Act
        await audioPlayerService.playFromUrl(audioUrl);

        // Assert
        verify(mockAudioPlayer.setUrl(audioUrl)).called(1);
        verify(mockAudioPlayer.play()).called(1);
      });
    });

    group('Playback Controls', () {
      test('should pause playback', () async {
        // Arrange
        when(mockAudioPlayer.pause()).thenAnswer((_) async {});

        // Act
        await audioPlayerService.pause();

        // Assert
        verify(mockAudioPlayer.pause()).called(1);
      });

      test('should resume playback', () async {
        // Arrange
        when(mockAudioPlayer.play()).thenAnswer((_) async {});

        // Act
        await audioPlayerService.resume();

        // Assert
        verify(mockAudioPlayer.play()).called(1);
      });

      test('should stop playback', () async {
        // Arrange
        when(mockAudioPlayer.stop()).thenAnswer((_) async {});

        // Act
        await audioPlayerService.stop();

        // Assert
        verify(mockAudioPlayer.stop()).called(1);
      });

      test('should seek to position', () async {
        // Arrange
        const position = Duration(seconds: 30);
        when(mockAudioPlayer.seek(position)).thenAnswer((_) async {});

        // Act
        await audioPlayerService.seek(position);

        // Assert
        verify(mockAudioPlayer.seek(position)).called(1);
      });
    });

    group('Speed Control', () {
      test('should set playback speed', () async {
        // Arrange
        const speed = 1.5;
        when(mockAudioPlayer.setSpeed(speed)).thenAnswer((_) async => speed);

        // Act
        await audioPlayerService.setSpeed(speed);

        // Assert
        verify(mockAudioPlayer.setSpeed(speed)).called(1);
      });

      test('should clamp speed to valid range', () async {
        // Arrange
        const invalidSpeed = 5.0;
        const clampedSpeed = 2.0;
        when(mockAudioPlayer.setSpeed(clampedSpeed)).thenAnswer((_) async => clampedSpeed);

        // Act
        await audioPlayerService.setSpeed(invalidSpeed);

        // Assert
        verify(mockAudioPlayer.setSpeed(clampedSpeed)).called(1);
      });
    });

    group('Volume Control', () {
      test('should set volume', () async {
        // Arrange
        const volume = 0.7;
        when(mockAudioPlayer.setVolume(volume)).thenAnswer((_) async {});

        // Act
        await audioPlayerService.setVolume(volume);

        // Assert
        verify(mockAudioPlayer.setVolume(volume)).called(1);
      });

      test('should clamp volume to valid range', () async {
        // Arrange
        const invalidVolume = 2.0;
        const clampedVolume = 1.0;
        when(mockAudioPlayer.setVolume(clampedVolume)).thenAnswer((_) async {});

        // Act
        await audioPlayerService.setVolume(invalidVolume);

        // Assert
        verify(mockAudioPlayer.setVolume(clampedVolume)).called(1);
      });
    });

    group('State Management', () {
      test('should expose current position stream', () {
        // Assert
        expect(audioPlayerService.positionStream, isA<Stream<Duration>>());
      });

      test('should expose duration stream', () {
        // Assert
        expect(audioPlayerService.durationStream, isA<Stream<Duration?>>());
      });

      test('should expose playback state stream', () {
        // Assert
        expect(audioPlayerService.playerStateStream, isA<Stream<PlayerState>>());
      });
    });

    group('Resource Management', () {
      test('should dispose audio player on dispose', () {
        // Act
        audioPlayerService.dispose();

        // Assert
        verify(mockAudioPlayer.dispose()).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle audio loading errors', () async {
        // Arrange
        const audioPath = '/invalid/path.mp3';
        when(mockAudioPlayer.setFilePath(audioPath))
            .thenThrow(Exception('Failed to load audio'));

        // Act & Assert
        expect(
          () => audioPlayerService.playAudioFile(audioPath),
          throwsException,
        );
      });

      test('should handle playback errors', () async {
        // Arrange
        when(mockAudioPlayer.play())
            .thenThrow(Exception('Playback failed'));

        // Act & Assert
        expect(
          () => audioPlayerService.resume(),
          throwsException,
        );
      });
    });
  });
}