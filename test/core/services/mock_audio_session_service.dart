import 'dart:async';
import 'package:maxchomp/core/services/audio_session_service.dart';
import 'package:maxchomp/core/models/audio_session_state.dart';

/// Mock implementation of AudioSessionService for testing
class MockAudioSessionService implements AudioSessionService {
  AudioSessionState _currentState = AudioSessionState.inactive;
  bool _isActive = false;
  bool _canPlayInBackground = false;
  String _currentRoute = 'speaker';
  bool _isHeadphonesConnected = false;
  
  final StreamController<AudioSessionState> _stateController = 
      StreamController<AudioSessionState>.broadcast();
  final StreamController<String> _routeChangeController = 
      StreamController<String>.broadcast();
  
  @override
  AudioSessionState get currentState => _currentState;
  
  @override
  bool get isActive => _isActive;
  
  @override
  bool get canPlayInBackground => _canPlayInBackground;
  
  @override
  String get currentRoute => _currentRoute;
  
  @override
  bool get isHeadphonesConnected => _isHeadphonesConnected;
  
  @override
  Stream<AudioSessionState> get stateStream => _stateController.stream;
  
  @override
  Stream<String> get routeChangeStream => _routeChangeController.stream;
  
  @override
  Future<bool> initialize() async {
    _currentState = AudioSessionState.active;
    _isActive = true;
    _canPlayInBackground = true;
    _stateController.add(_currentState);
    return true;
  }
  
  @override
  Future<bool> configureForBackgroundPlayback() async {
    _canPlayInBackground = true;
    _currentState = AudioSessionState.active;
    _isActive = true;
    _stateController.add(_currentState);
    return true;
  }
  
  @override
  Future<bool> setPlaybackCategory() async {
    _currentState = AudioSessionState.active;
    _isActive = true;
    _stateController.add(_currentState);
    return true;
  }
  
  @override
  Future<bool> setAudioSessionOptions(List<String> options) async {
    return true;
  }
  
  @override
  Future<bool> deactivate() async {
    _currentState = AudioSessionState.inactive;
    _isActive = false;
    _canPlayInBackground = false;
    _stateController.add(_currentState);
    return true;
  }
  
  @override
  void handleInterruption(bool began) {
    if (began) {
      _currentState = AudioSessionState.interrupted;
      _isActive = false;
    } else {
      _currentState = AudioSessionState.active;
      _isActive = true;
    }
    _stateController.add(_currentState);
  }
  
  @override
  void handleRouteChange(String route, bool isHeadphones) {
    _currentRoute = route;
    _isHeadphonesConnected = isHeadphones;
    _routeChangeController.add(route);
  }
  
  @override
  Future<void> dispose() async {
    _currentState = AudioSessionState.inactive;
    _isActive = false;
    _canPlayInBackground = false;
    
    await _stateController.close();
    await _routeChangeController.close();
  }
}