import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/models/auth_state.dart';
import 'package:maxchomp/core/providers/auth_provider.dart';
import 'package:maxchomp/pages/auth/sign_in_page.dart';
import 'package:maxchomp/pages/home_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    switch (authState.status) {
      case AuthStatus.loading:
      case AuthStatus.initial:
        return const _LoadingScreen();
      case AuthStatus.authenticated:
        return const HomePage();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const SignInPage();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'MaxChomp',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}