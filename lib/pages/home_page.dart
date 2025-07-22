import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/core/providers/auth_provider.dart';
import 'package:maxchomp/pages/library_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  Widget _buildSettingsPage() {
    final currentUser = ref.watch(currentUserProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Settings'),
          const SizedBox(height: 16),
          if (currentUser != null) ...[
            Text('Welcome, ${currentUser.email ?? 'User'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const LibraryPage(),
          const Center(child: Text('Player')),
          _buildSettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle),
            label: 'Player',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}