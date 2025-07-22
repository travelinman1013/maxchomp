import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maxchomp/core/models/auth_state.dart';

// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider for GoogleSignIn instance
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

// AuthStateNotifier class to handle authentication logic
class AuthStateNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthStateNotifier({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        super(const AuthState.unauthenticated()) {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AuthState.loading();
      
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        state = AuthState.authenticated(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
      if (kDebugMode) {
        print('SignIn error: $e');
      }
    }
  }

  /// Create account with email and password
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      state = const AuthState.loading();
      
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        state = AuthState.authenticated(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
      if (kDebugMode) {
        print('CreateAccount error: $e');
      }
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = const AuthState.loading();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        state = const AuthState.unauthenticated();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        state = AuthState.authenticated(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthState.error('Failed to sign in with Google');
      if (kDebugMode) {
        print('Google SignIn error: $e');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error('Failed to sign out');
      if (kDebugMode) {
        print('SignOut error: $e');
      }
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    } catch (e) {
      throw 'Failed to send password reset email';
    }
  }

  /// Get user-friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'An error occurred during authentication';
    }
  }
}

// Main auth state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  
  return AuthStateNotifier(
    firebaseAuth: firebaseAuth,
    googleSignIn: googleSignIn,
  );
});

// Convenience provider to get current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.status == AuthStatus.authenticated;
});