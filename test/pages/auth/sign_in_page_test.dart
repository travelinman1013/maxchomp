import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maxchomp/pages/auth/sign_in_page.dart';
import 'package:maxchomp/core/models/auth_state.dart';
import 'package:maxchomp/core/providers/auth_provider.dart';
import 'dart:async';

// Use mocks from existing test file
import '../../../test/core/providers/auth_provider_test.mocks.dart';

void main() {
  group('SignInPage', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late StreamController<User?> authStateController;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      authStateController = StreamController<User?>();

      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authStateController.stream);
    });

    tearDown(() {
      authStateController.close();
    });

    Widget createSignInPage() {
      return ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        ],
        child: const MaterialApp(
          home: SignInPage(),
        ),
      );
    }

    testWidgets('should display sign-in form elements', (tester) async {
      await tester.pumpWidget(createSignInPage());

      // Check for app branding
      expect(find.text('MaxChomp'), findsOneWidget);
      expect(find.text('Transform your PDFs into natural speech'), findsOneWidget);

      // Check for form elements
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Check for navigation options
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('should validate email field', (tester) async {
      await tester.pumpWidget(createSignInPage());

      // Find the sign-in button and tap it without entering data
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('should validate password field', (tester) async {
      await tester.pumpWidget(createSignInPage());

      // Enter valid email but leave password empty
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Tap sign-in button
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      // Should show password validation error
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createSignInPage());

      // Find visibility toggle and tap it
      final visibilityToggle = find.byIcon(Icons.visibility);
      expect(visibilityToggle, findsOneWidget);

      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('should navigate to sign-up page when tapped', (tester) async {
      // Increase test surface size to avoid off-screen elements
      tester.view.physicalSize = const Size(800, 1200);
      
      await tester.pumpWidget(createSignInPage());

      // Scroll to make sure the sign-up button is visible
      await tester.scrollUntilVisible(
        find.text('Sign Up'),
        500,
        scrollable: find.byType(Scrollable),
      );

      // Find and tap the sign-up button
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Should navigate to sign-up page
      expect(find.text('Join MaxChomp'), findsOneWidget);
    });
  });
}