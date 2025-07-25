import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tts_provider.dart';
import '../providers/remote_config_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/settings_provider.dart';

/// Widget that initializes app services and shows a loading screen
/// 
/// This widget is responsible for initializing all necessary services
/// like TTS before showing the main app content.
class AppInitializer extends ConsumerStatefulWidget {
  final Widget child;
  
  const AppInitializer({
    super.key,
    required this.child,
  });
  
  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitialized = false;
  String? _initializationError;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Initialize services concurrently for better performance
      await Future.wait([
        _initializeTTS(),
        _initializeRemoteConfig(),
        _initializeAnalytics(),
        _initializeSettings(),
      ]);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = e.toString();
        });
      }
    }
  }

  Future<void> _initializeTTS() async {
    final ttsNotifier = ref.read(ttsStateNotifierProvider.notifier);
    await ttsNotifier.initialize();
  }

  Future<void> _initializeRemoteConfig() async {
    // Remote config initializes automatically when first accessed
    // We just need to trigger it by reading the provider
    ref.read(remoteConfigProvider);
  }

  Future<void> _initializeAnalytics() async {
    final analytics = ref.read(analyticsProvider);
    await analytics.initialize();
    
    // Track app launch
    await analytics.trackAppLifecycle(event: 'launched');
  }

  Future<void> _initializeSettings() async {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    await settingsNotifier.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize app',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initializationError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _initializationError = null;
                      });
                      _initializeServices();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if logo is not available
                    return const Icon(
                      Icons.auto_stories,
                      size: 120,
                      color: Colors.purple,
                    );
                  },
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Initializing MaxChomp...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}