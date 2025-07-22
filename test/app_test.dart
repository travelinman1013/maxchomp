import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import 'package:maxchomp/main.dart';
import 'package:maxchomp/core/providers/auth_provider.dart';
import 'package:maxchomp/pages/auth/sign_in_page.dart';

// Use existing mocks
import 'core/providers/auth_provider_test.mocks.dart';

void main() {
  group('MaxChompApp', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockGoogleSignIn mockGoogleSignIn;
    late StreamController<User?> authStateController;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockGoogleSignIn = MockGoogleSignIn();
      authStateController = StreamController<User?>();

      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => authStateController.stream);
      when(mockUser.email).thenReturn('test@example.com');
    });

    tearDown(() {
      authStateController.close();
    });

    testWidgets('should display app with Material 3 theme', (WidgetTester tester) async {
      // Build our app with mocked auth
      await tester.pumpWidget(ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        ],
        child: const MaxChompApp(),
      ));

      // Verify Material 3 theme is being used
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, true);
      expect(materialApp.darkTheme?.useMaterial3, true);
    });

    testWidgets('should show sign-in page when unauthenticated', (WidgetTester tester) async {
      // Build our app with unauthenticated state
      await tester.pumpWidget(ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        ],
        child: const MaxChompApp(),
      ));

      // Should show sign-in page
      await tester.pump();
      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.text('MaxChomp'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('should show home page with navigation when authenticated', (WidgetTester tester) async {
      // Simulate authenticated user
      authStateController.add(mockUser);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        ],
        child: const MaxChompApp(),
      ));

      // Wait for auth state to propagate
      await tester.pumpAndSettle();

      // Should show home page with bottom navigation
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      
      // Check navigation destination labels
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}