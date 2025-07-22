import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/services/firebase_service.dart';
import 'package:maxchomp/core/theme/app_theme.dart';
import 'package:maxchomp/core/widgets/auth_wrapper.dart';
import 'package:maxchomp/core/widgets/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  runApp(const ProviderScope(
    child: MaxChompApp(),
  ));
}

class MaxChompApp extends StatelessWidget {
  const MaxChompApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppInitializer(
      child: MaterialApp(
        title: 'MaxChomp',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        home: const AuthWrapper(),
      ),
    );
  }
}