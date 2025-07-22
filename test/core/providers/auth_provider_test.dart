import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maxchomp/core/models/auth_state.dart';
import 'package:maxchomp/core/providers/auth_provider.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential, GoogleSignIn])
import 'auth_provider_test.mocks.dart';

void main() {
  group('AuthProvider', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockGoogleSignIn mockGoogleSignIn;
    late ProviderContainer container;
    late StreamController<User?> authStateController;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockGoogleSignIn = MockGoogleSignIn();
      authStateController = StreamController<User?>();

      // Mock the authStateChanges stream
      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authStateController.stream);

      container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        ],
      );
    });

    tearDown(() {
      authStateController.close();
      container.dispose();
    });

    test('initial state should be unauthenticated', () {
      final authState = container.read(authStateProvider);
      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.user, isNull);
    });

    test('should sign in with email and password successfully', () async {
      // Arrange
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Act
      await container
          .read(authStateProvider.notifier)
          .signInWithEmailAndPassword('test@example.com', 'password123');

      // Assert
      final authState = container.read(authStateProvider);
      expect(authState.status, AuthStatus.authenticated);
      expect(authState.user?.email, 'test@example.com');
    });

    test('should handle sign in errors gracefully', () async {
      // Arrange
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'invalid-email'));

      // Act
      await container
          .read(authStateProvider.notifier)
          .signInWithEmailAndPassword('invalid-email', 'password123');

      // Assert
      final authState = container.read(authStateProvider);
      expect(authState.status, AuthStatus.error);
      expect(authState.errorMessage, isNotNull);
    });

    test('should sign out successfully', () async {
      // Arrange
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      // Act
      await container.read(authStateProvider.notifier).signOut();

      // Assert
      final authState = container.read(authStateProvider);
      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.user, isNull);
    });
  });
}