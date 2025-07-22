import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static const String _tag = 'FirebaseService';

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('$_tag: Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Check if Firebase is already initialized
  static bool get isInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
}