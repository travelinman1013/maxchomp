import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:maxchomp/core/models/audio_session_state.dart';

/// Service for managing audio session configuration, particularly for iOS background playback
/// and handling audio interruptions and route changes.
class AudioSessionService {
  static const MethodChannel _channel = MethodChannel('maxchomp/audio_session');
  
  // State management
  AudioSessionState _currentState = AudioSessionState.inactive;
  bool _isActive = false;
  bool _canPlayInBackground = false;
  String _currentRoute = 'speaker';
  bool _isHeadphonesConnected = false;
  
  // Stream controllers for state changes
  final StreamController<AudioSessionState> _stateController = 
      StreamController<AudioSessionState>.broadcast();
  final StreamController<String> _routeChangeController = 
      StreamController<String>.broadcast();
  
  /// Creates a new AudioSessionService instance
  AudioSessionService() {
    _setupMethodCallHandler();
  }
  
  // Getters
  AudioSessionState get currentState => _currentState;
  bool get isActive => _isActive;
  bool get canPlayInBackground => _canPlayInBackground;
  String get currentRoute => _currentRoute;
  bool get isHeadphonesConnected => _isHeadphonesConnected;
  
  // Streams
  Stream<AudioSessionState> get stateStream => _stateController.stream;
  Stream<String> get routeChangeStream => _routeChangeController.stream;
  
  /// Sets up the method call handler for platform callbacks
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onInterruption':
          final bool began = call.arguments['began'] as bool;
          handleInterruption(began);
          break;
        case 'onRouteChange':
          final String route = call.arguments['route'] as String;
          final bool isHeadphones = call.arguments['isHeadphones'] as bool;
          handleRouteChange(route, isHeadphones);
          break;
      }
    });
  }
  
  /// Initializes the audio session with background playback configuration
  Future<bool> initialize() async {
    if (_isActive) {
      return true; // Already initialized
    }
    
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod<bool>('initialize') ?? false;
        if (result) {
          _currentState = AudioSessionState.active;
          _isActive = true;
          _canPlayInBackground = true;
          _emitStateChange();
        }
        return result;
      } else {
        // For Android and other platforms, we'll handle differently
        // For now, return true as a basic implementation
        _currentState = AudioSessionState.active;
        _isActive = true;
        _canPlayInBackground = true;
        _emitStateChange();
        return true;
      }
    } catch (e) {
      _currentState = AudioSessionState.error;
      _isActive = false;
      _canPlayInBackground = false;
      _emitStateChange();
      return false;
    }
  }
  
  /// Configures the audio session specifically for background playback
  Future<bool> configureForBackgroundPlayback() async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod<bool>('configureBackgroundPlayback') ?? false;
        if (result) {
          _canPlayInBackground = true;
          _currentState = AudioSessionState.active;
          _isActive = true;
          _emitStateChange();
        }
        return result;
      } else {
        // For non-iOS platforms, assume background playback is available
        _canPlayInBackground = true;
        _currentState = AudioSessionState.active;
        _isActive = true;
        _emitStateChange();
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Sets the audio session to playback category (iOS-specific)
  Future<bool> setPlaybackCategory() async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod<bool>('setPlaybackCategory') ?? false;
        if (result) {
          _currentState = AudioSessionState.active;
          _isActive = true;
          _emitStateChange();
        }
        return result;
      } else {
        // For non-iOS platforms, return true
        _currentState = AudioSessionState.active;
        _isActive = true;
        _emitStateChange();
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Sets audio session options (iOS-specific)
  Future<bool> setAudioSessionOptions(List<String> options) async {
    try {
      if (Platform.isIOS) {
        return await _channel.invokeMethod<bool>('setAudioSessionOptions', {
          'options': options,
        }) ?? false;
      } else {
        // For non-iOS platforms, return true
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Deactivates the audio session
  Future<bool> deactivate() async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod<bool>('deactivate') ?? false;
        if (result) {
          _currentState = AudioSessionState.inactive;
          _isActive = false;
          _canPlayInBackground = false;
          _emitStateChange();
        }
        return result;
      } else {
        _currentState = AudioSessionState.inactive;
        _isActive = false;
        _canPlayInBackground = false;
        _emitStateChange();
        return true;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Handles audio interruption events (phone calls, other apps)
  void handleInterruption(bool began) {
    if (began) {
      _currentState = AudioSessionState.interrupted;
      _isActive = false;
    } else {
      _currentState = AudioSessionState.active;
      _isActive = true;
    }
    _emitStateChange();
  }
  
  /// Handles audio route changes (headphones, speaker, etc.)
  void handleRouteChange(String route, bool isHeadphones) {
    _currentRoute = route;
    _isHeadphonesConnected = isHeadphones;
    _routeChangeController.add(route);
  }
  
  /// Emits state change to listeners
  void _emitStateChange() {
    _stateController.add(_currentState);
  }
  
  /// Disposes of resources and stops the audio session
  Future<void> dispose() async {
    try {
      if (Platform.isIOS && _isActive) {
        await _channel.invokeMethod('dispose');
      }
    } catch (e) {
      // Ignore disposal errors
    }
    
    _currentState = AudioSessionState.inactive;
    _isActive = false;
    _canPlayInBackground = false;
    
    await _stateController.close();
    await _routeChangeController.close();
  }
}