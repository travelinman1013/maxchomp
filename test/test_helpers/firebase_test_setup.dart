import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase test setup utilities for MaxChomp tests
class FirebaseTestSetup {
  static bool _initialized = false;

  /// Initialize Firebase for testing environment
  static Future<void> initializeFirebase() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase Core platform channel
    const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firebase#initializeCore':
          return <String, dynamic>{
            'name': '[DEFAULT]',
            'options': <String, dynamic>{
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project-id',
            },
            'pluginConstants': <String, dynamic>{},
          };
        case 'Firebase#initializeApp':
          return <String, dynamic>{
            'name': methodCall.arguments['appName'] ?? '[DEFAULT]',
            'options': methodCall.arguments['options'],
            'pluginConstants': <String, dynamic>{},
          };
        default:
          return null;
      }
    });

    // Mock Firebase Analytics platform channel
    const MethodChannel analyticsChannel = MethodChannel('plugins.flutter.io/firebase_analytics');
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(analyticsChannel, (MethodCall methodCall) async {
      // Mock all analytics method calls to return successfully
      return null;
    });

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ),
      );
    } catch (e) {
      // Firebase may already be initialized
      if (!e.toString().contains('already exists')) {
        rethrow;
      }
    }

    _initialized = true;
  }

  /// Clean up Firebase test setup
  static void cleanup() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
    const MethodChannel analyticsChannel = MethodChannel('plugins.flutter.io/firebase_analytics');
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(analyticsChannel, null);
  }
}